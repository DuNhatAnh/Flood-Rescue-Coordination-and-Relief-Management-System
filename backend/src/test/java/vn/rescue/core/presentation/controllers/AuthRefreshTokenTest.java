package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.util.ReflectionTestUtils;
import vn.rescue.core.application.dto.AuthResponse;
import vn.rescue.core.application.dto.RefreshTokenRequest;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.infrastructure.security.JwtService;
import vn.rescue.core.presentation.exceptions.UnauthorizedException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("Unit Test Kiểm thử API POST /api/auth/refresh và JwtService.isRefreshTokenValid()")
class AuthRefreshTokenTest {

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

    private User sampleUser;
    private UserDetails sampleUserDetails;

    @BeforeEach
    void setUp() {
        sampleUser = new User();
        sampleUser.setId("user-123");
        sampleUser.setEmail("admin@floodrescue.vn");
        sampleUser.setFullName("Quản trị viên Hệ thống");
        sampleUser.setRoleId("ROLE_ADMIN");
        sampleUser.setTeamId("team-01");

        sampleUserDetails = new org.springframework.security.core.userdetails.User(
                "admin@floodrescue.vn",
                "password123",
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))
        );
    }

    @Test
    @DisplayName("TC_REFRESH_01: Cấp accessToken mới thành công khi gửi Refresh Token hợp lệ -> 200 OK")
    void testRefreshToken_Success() {
        String validRefreshToken = "valid_refresh_token_jwt_string";
        String newAccessToken = "newly_generated_access_token_jwt_string";

        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken(validRefreshToken)
                .build();

        when(jwtService.isRefreshTokenValid(validRefreshToken)).thenReturn(true);
        when(jwtService.extractUsername(validRefreshToken)).thenReturn("admin@floodrescue.vn");
        when(userDetailsService.loadUserByUsername("admin@floodrescue.vn")).thenReturn(sampleUserDetails);
        when(jwtService.isRefreshTokenValid(validRefreshToken, sampleUserDetails)).thenReturn(true);
        when(jwtService.generateToken(sampleUserDetails)).thenReturn(newAccessToken);
        when(userRepository.findByEmail("admin@floodrescue.vn")).thenReturn(Optional.of(sampleUser));

        RescueTeam sampleTeam = new RescueTeam();
        sampleTeam.setId("team-01");
        sampleTeam.setTeamName("Đội Cứu Hộ Hải Châu");
        when(rescueTeamRepository.findById("team-01")).thenReturn(Optional.of(sampleTeam));

        ResponseEntity<AuthResponse> response = authController.refreshToken(request);

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());

        AuthResponse body = response.getBody();
        assertEquals(newAccessToken, body.getToken());
        assertEquals(newAccessToken, body.getAccessToken());
        assertEquals(validRefreshToken, body.getRefreshToken());
        assertEquals("admin@floodrescue.vn", body.getEmail());
        assertEquals("Quản trị viên Hệ thống", body.getFullName());
        assertEquals("team-01", body.getTeamId());
        assertEquals("Đội Cứu Hộ Hải Châu", body.getTeamName());
        assertTrue(body.getRoles().contains("ROLE_ADMIN"));

        verify(jwtService).isRefreshTokenValid(validRefreshToken);
        verify(jwtService).generateToken(sampleUserDetails);
    }

    @Test
    @DisplayName("TC_REFRESH_02: Ném ngoại lệ UnauthorizedException khi Refresh Token rỗng hoặc null")
    void testRefreshToken_NullOrEmpty() {
        RefreshTokenRequest emptyRequest = new RefreshTokenRequest("");
        UnauthorizedException ex1 = assertThrows(UnauthorizedException.class,
                () -> authController.refreshToken(emptyRequest));
        assertTrue(ex1.getMessage().contains("không được để trống"));

        RefreshTokenRequest nullRequest = new RefreshTokenRequest(null);
        UnauthorizedException ex2 = assertThrows(UnauthorizedException.class,
                () -> authController.refreshToken(nullRequest));
        assertTrue(ex2.getMessage().contains("không được để trống"));

        UnauthorizedException ex3 = assertThrows(UnauthorizedException.class,
                () -> authController.refreshToken(null));
        assertTrue(ex3.getMessage().contains("không được để trống"));
    }

    @Test
    @DisplayName("TC_REFRESH_03: Ném ngoại lệ UnauthorizedException khi Refresh Token giả mạo hoặc hết hạn")
    void testRefreshToken_InvalidOrExpired() {
        String invalidRefreshToken = "forged_or_expired_refresh_token";
        RefreshTokenRequest request = new RefreshTokenRequest(invalidRefreshToken);

        when(jwtService.isRefreshTokenValid(invalidRefreshToken)).thenReturn(false);

        UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                () -> authController.refreshToken(request));
        assertTrue(ex.getMessage().contains("không hợp lệ hoặc đã hết hạn"));

        verify(jwtService, never()).generateToken(any());
    }

    @Test
    @DisplayName("TC_REFRESH_04: Ném ngoại lệ UnauthorizedException khi User không tồn tại trong hệ thống")
    void testRefreshToken_UserNotFound() {
        String refreshToken = "valid_format_token";
        RefreshTokenRequest request = new RefreshTokenRequest(refreshToken);

        when(jwtService.isRefreshTokenValid(refreshToken)).thenReturn(true);
        when(jwtService.extractUsername(refreshToken)).thenReturn("unknown@floodrescue.vn");
        when(userDetailsService.loadUserByUsername("unknown@floodrescue.vn"))
                .thenThrow(new RuntimeException("User not found"));

        UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                () -> authController.refreshToken(request));
        assertTrue(ex.getMessage().contains("không tồn tại hoặc đã bị vô hiệu hóa"));
    }

    @Test
    @DisplayName("TC_REFRESH_05: Kiểm thử logic xác thực thực tế của JwtService.isRefreshTokenValid()")
    void testRealJwtService_isRefreshTokenValid() {
        JwtService realJwtService = new JwtService();
        // 256-bit base64 key
        String testSecret = "Y2hhbmdlbWVjaGFuZ2VtZWNoYW5nZW1lY2hhbmdlbWVjaGFuZ2VtZQ==";
        ReflectionTestUtils.setField(realJwtService, "secretKey", testSecret);
        ReflectionTestUtils.setField(realJwtService, "jwtExpiration", 10000L);
        ReflectionTestUtils.setField(realJwtService, "refreshExpiration", 60000L);

        // 1. Tạo refresh token thật hợp lệ
        String validToken = realJwtService.generateRefreshToken(sampleUserDetails);
        assertNotNull(validToken);
        assertTrue(realJwtService.isRefreshTokenValid(validToken));
        assertTrue(realJwtService.isRefreshTokenValid(validToken, sampleUserDetails));

        // 2. Token giả mạo (bị can thiệp dữ liệu)
        String forgedToken = validToken + "corrupted";
        assertFalse(realJwtService.isRefreshTokenValid(forgedToken));
        assertFalse(realJwtService.isRefreshTokenValid(forgedToken, sampleUserDetails));

        // 3. Token rỗng hoặc null
        assertFalse(realJwtService.isRefreshTokenValid(""));
        assertFalse(realJwtService.isRefreshTokenValid(null));

        // 4. Token với User khác
        UserDetails anotherUser = new org.springframework.security.core.userdetails.User(
                "other@floodrescue.vn", "pwd", List.of()
        );
        assertFalse(realJwtService.isRefreshTokenValid(validToken, anotherUser));

        // 5. Token đã hết hạn (expiration âm)
        ReflectionTestUtils.setField(realJwtService, "refreshExpiration", -1000L);
        String expiredToken = realJwtService.generateRefreshToken(sampleUserDetails);
        assertFalse(realJwtService.isRefreshTokenValid(expiredToken));
    }
}
