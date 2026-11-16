package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import vn.rescue.core.application.dto.AuthRequest;
import vn.rescue.core.application.dto.AuthResponse;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.infrastructure.security.JwtService;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-100: Unit Test Kiểm tra chặn cấp JWT Token cho tài khoản INACTIVE/LOCKED")
class AuthControllerTest {

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private UserDetailsService userDetailsService;

    @Mock
    private JwtService jwtService;

    @Mock
    private UserRepository userRepository;

    @Mock
    private RescueTeamRepository rescueTeamRepository;

    @InjectMocks
    private AuthController authController;

    private AuthRequest createAuthRequest(String email, String password) {
        AuthRequest req = new AuthRequest();
        req.setEmail(email);
        req.setPassword(password);
        return req;
    }

    @Test
    @DisplayName("TC_AUTH_100_01: Đăng nhập thành công khi tài khoản có trạng thái ACTIVE -> Cấp Token 200 OK")
    void testLogin_WhenStatusActive_ShouldReturnToken200OK() {
        String email = "active_user@rescue.vn";
        String password = "password123";
        AuthRequest request = createAuthRequest(email, password);

        User activeUser = new User();
        activeUser.setId("USR-01");
        activeUser.setEmail(email);
        activeUser.setFullName("Nguyễn Văn A");
        activeUser.setStatus("ACTIVE");

        UserDetails mockUserDetails = new org.springframework.security.core.userdetails.User(
                email,
                password,
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))
        );

        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(null);
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(activeUser));
        when(userDetailsService.loadUserByUsername(email)).thenReturn(mockUserDetails);
        when(jwtService.generateToken(mockUserDetails)).thenReturn("mock-jwt-token-xyz");

        ResponseEntity<AuthResponse> response = authController.login(request);

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("mock-jwt-token-xyz", response.getBody().getToken());
        assertEquals("Nguyễn Văn A", response.getBody().getFullName());
        verify(jwtService, times(1)).generateToken(mockUserDetails);
    }

    @Test
    @DisplayName("TC_AUTH_100_02: Đăng nhập thất bại khi tài khoản có status INACTIVE -> Ném DisabledException và chặn cấp Token")
    void testLogin_WhenStatusInactive_ShouldThrowDisabledException() {
        String email = "inactive_user@rescue.vn";
        String password = "password123";
        AuthRequest request = createAuthRequest(email, password);

        User inactiveUser = new User();
        inactiveUser.setId("USR-02");
        inactiveUser.setEmail(email);
        inactiveUser.setFullName("Tài khoản Vô hiệu");
        inactiveUser.setStatus("INACTIVE");

        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(null);
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(inactiveUser));

        DisabledException exception = assertThrows(DisabledException.class, () -> {
            authController.login(request);
        });

        assertEquals("Tài khoản đã bị vô hiệu hóa hoặc chưa được kích hoạt", exception.getMessage());
        verify(jwtService, never()).generateToken(any());
        verify(userDetailsService, never()).loadUserByUsername(any());
    }

    @Test
    @DisplayName("TC_AUTH_100_03: Đăng nhập thất bại khi tài khoản có status LOCKED -> Ném LockedException và chặn cấp Token")
    void testLogin_WhenStatusLocked_ShouldThrowLockedException() {
        String email = "locked_user@rescue.vn";
        String password = "password123";
        AuthRequest request = createAuthRequest(email, password);

        User lockedUser = new User();
        lockedUser.setId("USR-03");
        lockedUser.setEmail(email);
        lockedUser.setStatus("LOCKED");

        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(null);
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(lockedUser));

        LockedException exception = assertThrows(LockedException.class, () -> {
            authController.login(request);
        });

        assertEquals("Tài khoản đã bị khóa do vi phạm chính sách", exception.getMessage());
        verify(jwtService, never()).generateToken(any());
        verify(userDetailsService, never()).loadUserByUsername(any());
    }

    @Test
    @DisplayName("TC_AUTH_100_04: Đăng nhập thất bại khi tài khoản có status khác ACTIVE (ví dụ null hoặc SUSPENDED)")
    void testLogin_WhenStatusSuspendedOrNull_ShouldThrowDisabledException() {
        String email = "suspended_user@rescue.vn";
        String password = "password123";
        AuthRequest request = createAuthRequest(email, password);

        User suspendedUser = new User();
        suspendedUser.setId("USR-04");
        suspendedUser.setEmail(email);
        suspendedUser.setStatus("SUSPENDED");

        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(null);
        when(userRepository.findByEmail(email)).thenReturn(Optional.of(suspendedUser));

        assertThrows(DisabledException.class, () -> {
            authController.login(request);
        });

        verify(jwtService, never()).generateToken(any());
    }
}
