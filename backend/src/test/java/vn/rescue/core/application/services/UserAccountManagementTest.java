package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import vn.rescue.core.application.dto.UserDto;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.entities.Warehouse;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * EPIC 01 - Mục 1.4 (Khóa / Mở khóa tài khoản) & 1.5 (Gán / Đổi vai trò) trong TEST_MATRIX.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-106: Unit Test Khóa tài khoản & Đổi vai trò (UserService)")
class UserAccountManagementTest {

    @Mock private UserRepository userRepository;
    @Mock private RescueTeamRepository rescueTeamRepository;
    @Mock private VehiclesRepository vehiclesRepository;
    @Mock private WarehouseRepository warehouseRepository;
    @Mock private PasswordEncoder passwordEncoder;

    @InjectMocks private UserService userService;

    private User user(String id, String roleId, String status, String teamId) {
        User u = new User();
        u.setId(id);
        u.setEmail(id + "@rescue.vn");
        u.setFullName("Nhân viên " + id);
        u.setRoleId(roleId);
        u.setStatus(status);
        u.setTeamId(teamId);
        return u;
    }

    // ==================== 1.4 KHÓA / MỞ KHÓA TÀI KHOẢN ====================

    @Test
    @DisplayName("TC_LOCK_01: Khóa tài khoản ACTIVE -> INACTIVE được lưu vào DB")
    void lockAccount_ShouldSaveInactive() {
        User u = user("U1", "USER", "ACTIVE", null);
        when(userRepository.findById("U1")).thenReturn(Optional.of(u));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UserDto result = userService.updateUserStatus("U1", "INACTIVE");

        assertEquals("INACTIVE", result.getStatus());
        verify(userRepository).save(u);
    }

    @Test
    @DisplayName("TC_LOCK_02: Mở khóa tài khoản LOCKED -> ACTIVE (chấp nhận chữ thường, tự chuẩn hóa IN HOA)")
    void unlockAccount_ShouldNormalizeAndSaveActive() {
        User u = user("U2", "USER", "LOCKED", null);
        when(userRepository.findById("U2")).thenReturn(Optional.of(u));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UserDto result = userService.updateUserStatus("U2", " active ");

        assertEquals("ACTIVE", result.getStatus());
    }

    @Test
    @DisplayName("TC_LOCK_03: Trạng thái ngoài danh mục (BANNED, rỗng, null) -> Ném 400 BadRequestException, không lưu DB")
    void invalidStatus_ShouldThrowBadRequest() {
        assertThrows(BadRequestException.class, () -> userService.updateUserStatus("U1", "BANNED"));
        assertThrows(BadRequestException.class, () -> userService.updateUserStatus("U1", ""));
        assertThrows(BadRequestException.class, () -> userService.updateUserStatus("U1", null));
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_LOCK_04: Khóa tài khoản không tồn tại -> Ném 404 ResourceNotFoundException")
    void lockNotExistingUser_ShouldThrowNotFound() {
        when(userRepository.findById("NOT_FOUND")).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> userService.updateUserStatus("NOT_FOUND", "INACTIVE"));
        verify(userRepository, never()).save(any());
    }

    // ==================== 1.5 GÁN / ĐỔI VAI TRÒ ====================

    @Test
    @DisplayName("TC_ROLE_CHG_01: USER -> RESCUE_STAFF: Tự tạo đội AVAILABLE do user làm trưởng và gán kho còn trống")
    void promoteToRescueStaff_ShouldCreateTeamWithVacantWarehouse() {
        User u = user("U3", "USER", "ACTIVE", null);
        Warehouse occupied = new Warehouse();
        occupied.setId("WH-1");
        Warehouse vacant = new Warehouse();
        vacant.setId("WH-2");

        when(userRepository.findById("U3")).thenReturn(Optional.of(u));
        when(warehouseRepository.findAll()).thenReturn(List.of(occupied, vacant));
        when(rescueTeamRepository.findByWarehouseId("WH-1")).thenReturn(Optional.of(new RescueTeam()));
        when(rescueTeamRepository.findByWarehouseId("WH-2")).thenReturn(Optional.empty());
        when(rescueTeamRepository.save(any(RescueTeam.class))).thenAnswer(inv -> {
            RescueTeam t = inv.getArgument(0);
            t.setId("TEAM-NEW");
            return t;
        });
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UserDto result = userService.updateUserRole("U3", "RESCUE_STAFF");

        ArgumentCaptor<RescueTeam> teamCaptor = ArgumentCaptor.forClass(RescueTeam.class);
        verify(rescueTeamRepository).save(teamCaptor.capture());
        RescueTeam team = teamCaptor.getValue();
        assertEquals("U3", team.getLeaderId());
        assertEquals("AVAILABLE", team.getStatus());
        assertEquals("WH-2", team.getWarehouseId(), "Phải gán kho chưa có đội (ràng buộc 1 kho - 1 đội)");
        assertEquals("RESCUE_STAFF", result.getRoleId());
        assertEquals("TEAM-NEW", result.getTeamId());
    }

    @Test
    @DisplayName("TC_ROLE_CHG_02: RESCUE_STAFF -> USER: Giải phóng toàn bộ xe của đội về AVAILABLE và xóa đội")
    void demoteFromRescueStaff_ShouldReleaseVehiclesAndDeleteTeam() {
        User u = user("U4", "RESCUE_STAFF", "ACTIVE", "TEAM-4");
        RescueTeam team = new RescueTeam();
        team.setId("TEAM-4");
        Vehicles v1 = Vehicles.builder().id("V1").teamId("TEAM-4").status("BUSY").build();
        Vehicles v2 = Vehicles.builder().id("V2").teamId("TEAM-4").status("BUSY").build();

        when(userRepository.findById("U4")).thenReturn(Optional.of(u));
        when(rescueTeamRepository.findByLeaderId("U4")).thenReturn(Optional.of(team));
        when(vehiclesRepository.findByTeamId("TEAM-4")).thenReturn(List.of(v1, v2));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UserDto result = userService.updateUserRole("U4", "USER");

        assertAll(
                () -> assertNull(v1.getTeamId()),
                () -> assertEquals("AVAILABLE", v1.getStatus()),
                () -> assertNull(v2.getTeamId()),
                () -> assertEquals("AVAILABLE", v2.getStatus()),
                () -> assertNull(result.getTeamId()),
                () -> assertEquals("USER", result.getRoleId()));
        verify(vehiclesRepository, times(2)).save(any(Vehicles.class));
        verify(rescueTeamRepository).delete(team);
    }

    @Test
    @DisplayName("TC_ROLE_CHG_03: USER -> COORDINATOR (không liên quan RESCUE_STAFF) -> Chỉ đổi role, không tạo/xóa đội")
    void changeRoleWithoutStaff_ShouldNotTouchTeams() {
        User u = user("U5", "USER", "ACTIVE", null);
        when(userRepository.findById("U5")).thenReturn(Optional.of(u));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UserDto result = userService.updateUserRole("U5", "COORDINATOR");

        assertEquals("COORDINATOR", result.getRoleId());
        verifyNoInteractions(rescueTeamRepository, vehiclesRepository, warehouseRepository);
    }

    @Test
    @DisplayName("TC_ROLE_CHG_04: Đổi vai trò cho user không tồn tại -> Ném 404 ResourceNotFoundException")
    void changeRoleNotExistingUser_ShouldThrowNotFound() {
        when(userRepository.findById("NOT_FOUND")).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> userService.updateUserRole("NOT_FOUND", "ADMIN"));
        verify(userRepository, never()).save(any());
    }
}
