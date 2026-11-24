package vn.rescue.core.infrastructure.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import vn.rescue.core.domain.entities.Role;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.repositories.RoleRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.presentation.controllers.AdminSystemController;
import vn.rescue.core.presentation.controllers.AdminUserController;
import vn.rescue.core.presentation.controllers.RoleController;

import java.lang.reflect.Method;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

/**
 * EPIC 01 - Mục 1.6 (Ma trận phân quyền RBAC) trong TEST_MATRIX.
 * Kiểm thử hộp trắng 2 tầng: (1) Role -> Authority khi đăng nhập, (2) cấu hình @PreAuthorize trên các API quản trị.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-106: Unit Test Ma trận phân quyền RBAC (CustomUserDetailsService & @PreAuthorize)")
class RbacAuthorizationTest {

    @Mock private UserRepository userRepository;
    @Mock private RoleRepository roleRepository;

    @InjectMocks private CustomUserDetailsService userDetailsService;

    private User user(String email, String roleId, String status) {
        User u = new User();
        u.setEmail(email);
        u.setPassword("$2a$10$hash");
        u.setRoleId(roleId);
        u.setStatus(status);
        return u;
    }

    private List<String> authoritiesOf(UserDetails details) {
        return details.getAuthorities().stream().map(GrantedAuthority::getAuthority).collect(Collectors.toList());
    }

    // ==================== TẦNG 1: ROLE -> AUTHORITY ====================

    @Test
    @DisplayName("TC_RBAC_UT_01: User role ADMIN -> Được cấp ROLE_ADMIN kèm quyền ALL")
    void adminUser_ShouldHaveRoleAdminAuthority() {
        when(userRepository.findByEmail("admin@rescue.vn")).thenReturn(Optional.of(user("admin@rescue.vn", "ADMIN", "ACTIVE")));
        when(roleRepository.findById("ADMIN")).thenReturn(Optional.of(Role.builder().id("ADMIN").name("ADMIN").permissions(List.of("ALL")).build()));

        UserDetails details = userDetailsService.loadUserByUsername("admin@rescue.vn");

        assertTrue(authoritiesOf(details).containsAll(List.of("ROLE_ADMIN", "ALL")));
        assertTrue(details.isEnabled());
    }

    @Test
    @DisplayName("TC_RBAC_UT_02: User role USER (người dân) -> Chỉ có ROLE_USER, KHÔNG có ROLE_ADMIN")
    void citizenUser_ShouldNotHaveRoleAdmin() {
        when(userRepository.findByEmail("citizen@rescue.vn")).thenReturn(Optional.of(user("citizen@rescue.vn", "USER", "ACTIVE")));
        when(roleRepository.findById("USER")).thenReturn(Optional.of(Role.builder().id("USER").name("USER").permissions(List.of("REPORT")).build()));

        List<String> authorities = authoritiesOf(userDetailsService.loadUserByUsername("citizen@rescue.vn"));

        assertTrue(authorities.contains("ROLE_USER"));
        assertFalse(authorities.contains("ROLE_ADMIN"), "Người dân tuyệt đối không được có quyền ADMIN");
    }

    @Test
    @DisplayName("TC_RBAC_UT_03: User có roleId không tồn tại trong DB -> Không được cấp bất kỳ quyền nào")
    void unknownRole_ShouldHaveNoAuthorities() {
        when(userRepository.findByEmail("ghost@rescue.vn")).thenReturn(Optional.of(user("ghost@rescue.vn", "GHOST", "ACTIVE")));
        when(roleRepository.findById("GHOST")).thenReturn(Optional.empty());

        assertTrue(userDetailsService.loadUserByUsername("ghost@rescue.vn").getAuthorities().isEmpty());
    }

    @Test
    @DisplayName("TC_RBAC_UT_04: Tài khoản INACTIVE -> isEnabled = false; LOCKED -> isAccountNonLocked = false (chặn cấp token - KCPM-100)")
    void inactiveOrLockedAccount_ShouldBeBlocked() {
        when(userRepository.findByEmail("inactive@rescue.vn")).thenReturn(Optional.of(user("inactive@rescue.vn", "USER", "INACTIVE")));
        when(userRepository.findByEmail("locked@rescue.vn")).thenReturn(Optional.of(user("locked@rescue.vn", "USER", "LOCKED")));
        when(roleRepository.findById("USER")).thenReturn(Optional.of(Role.builder().id("USER").name("USER").build()));

        assertFalse(userDetailsService.loadUserByUsername("inactive@rescue.vn").isEnabled());
        assertFalse(userDetailsService.loadUserByUsername("locked@rescue.vn").isAccountNonLocked());
    }

    @Test
    @DisplayName("TC_RBAC_UT_05: Email không tồn tại -> Ném UsernameNotFoundException")
    void unknownEmail_ShouldThrow() {
        when(userRepository.findByEmail("nobody@rescue.vn")).thenReturn(Optional.empty());

        assertThrows(UsernameNotFoundException.class, () -> userDetailsService.loadUserByUsername("nobody@rescue.vn"));
    }

    // ==================== TẦNG 2: CẤU HÌNH @PreAuthorize TRÊN API QUẢN TRỊ ====================

    @Test
    @DisplayName("TC_RBAC_UT_06: AdminUserController & RoleController được khóa toàn bộ bằng @PreAuthorize(hasRole('ADMIN'))")
    void adminControllers_ShouldRequireAdminRole() {
        for (Class<?> controller : List.of(AdminUserController.class, RoleController.class)) {
            PreAuthorize rule = controller.getAnnotation(PreAuthorize.class);
            assertNotNull(rule, controller.getSimpleName() + " phải có @PreAuthorize ở mức class");
            assertEquals("hasRole('ADMIN')", rule.value());
        }
    }

    @Test
    @DisplayName("TC_RBAC_UT_07: Mọi API của AdminSystemController (trừ GET /config public có chủ đích) đều yêu cầu quyền ADMIN")
    void adminSystemEndpoints_ShouldRequireAdmin() {
        // GET /config được trang chủ người dân đọc khi chưa đăng nhập -> nằm trong danh sách cho phép public
        java.util.Set<String> publicByDesign = java.util.Set.of("getAllConfigs");
        for (Method m : AdminSystemController.class.getDeclaredMethods()) {
            if (!java.lang.reflect.Modifier.isPublic(m.getModifiers()) || publicByDesign.contains(m.getName())) continue;
            PreAuthorize rule = m.getAnnotation(PreAuthorize.class);
            assertNotNull(rule, "API " + m.getName() + " chưa được bảo vệ bởi @PreAuthorize");
            assertTrue(rule.value().contains("ADMIN"), "API " + m.getName() + " phải yêu cầu quyền ADMIN");
        }
    }
}
