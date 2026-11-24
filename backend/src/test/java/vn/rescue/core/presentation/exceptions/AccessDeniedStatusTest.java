package vn.rescue.core.presentation.exceptions;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import vn.rescue.core.presentation.common.ApiResponse;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * EPIC 01 - Mục 1.6 RBAC: phân biệt 401 (chưa xác thực) và 403 (không đủ quyền) theo thiết kế auth_rbac_data.csv (KCPM-90).
 */
@DisplayName("KCPM-106: Unit Test phân biệt HTTP 401 / 403 khi truy cập API quản trị")
class AccessDeniedStatusTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @AfterEach
    void clear() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("TC_RBAC_10/11/12: Không có token hoặc token hết hạn/bị sửa (người dùng ẩn danh) -> 401 Unauthorized")
    void anonymousUser_ShouldGet401() {
        SecurityContextHolder.getContext().setAuthentication(new AnonymousAuthenticationToken(
                "key", "anonymousUser", List.of(new SimpleGrantedAuthority("ROLE_ANONYMOUS"))));

        ResponseEntity<ApiResponse<Object>> res = handler.handleAccessDeniedException(new AccessDeniedException("Access Denied"));

        assertEquals(401, res.getStatusCode().value());
    }

    @Test
    @DisplayName("Không có Authentication trong SecurityContext -> 401 Unauthorized")
    void noAuthentication_ShouldGet401() {
        ResponseEntity<ApiResponse<Object>> res = handler.handleAccessDeniedException(new AccessDeniedException("Access Denied"));

        assertEquals(401, res.getStatusCode().value());
    }

    @Test
    @DisplayName("TC_RBAC_07/08: Đã đăng nhập bằng role USER/COORDINATOR nhưng gọi API ADMIN -> 403 Forbidden")
    void authenticatedWithoutRole_ShouldGet403() {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "citizen@rescue.vn", null, List.of(new SimpleGrantedAuthority("ROLE_USER"))));

        ResponseEntity<ApiResponse<Object>> res = handler.handleAccessDeniedException(new AccessDeniedException("Access Denied"));

        assertEquals(403, res.getStatusCode().value());
    }
}
