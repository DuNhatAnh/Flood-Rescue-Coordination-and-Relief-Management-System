package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import vn.rescue.core.application.dto.ChangePasswordRequest;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-80 [Subtask 1]: Unit Test Kiểm thử API Đổi mật khẩu (Change Password)")
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RescueTeamRepository rescueTeamRepository;

    @Mock
    private VehiclesRepository vehiclesRepository;

    @Mock
    private WarehouseRepository warehouseRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @Test
    @DisplayName("TC_AUTH_08: Đổi mật khẩu thành công khi nhập đúng mật khẩu cũ và mật khẩu mới hợp lệ")
    void testChangePassword_Success() {
        String userId = "USER-001";
        String oldPassword = "password123";
        String newPassword = "newPassword@2026";
        String encodedOld = "$2a$10$encodedOldHash";
        String encodedNew = "$2a$10$encodedNewHash";

        User mockUser = new User();
        mockUser.setId(userId);
        mockUser.setEmail("user@rescue.vn");
        mockUser.setPassword(encodedOld);
        mockUser.setStatus("ACTIVE");

        ChangePasswordRequest request = new ChangePasswordRequest(oldPassword, newPassword);

        when(userRepository.findById(userId)).thenReturn(Optional.of(mockUser));
        when(passwordEncoder.matches(oldPassword, encodedOld)).thenReturn(true);
        when(passwordEncoder.encode(newPassword)).thenReturn(encodedNew);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertDoesNotThrow(() -> userService.changePassword(userId, request));

        verify(passwordEncoder, times(1)).matches(oldPassword, encodedOld);
        verify(passwordEncoder, times(1)).encode(newPassword);
        verify(userRepository, times(1)).save(mockUser);
        assertEquals(encodedNew, mockUser.getPassword());
    }

    @Test
    @DisplayName("TC_AUTH_09: Đổi mật khẩu thất bại khi nhập sai mật khẩu cũ -> Ném 400 BadRequestException")
    void testChangePassword_WhenOldPasswordWrong_ShouldThrowBadRequestException() {
        String userId = "USER-001";
        String wrongOldPassword = "wrongPassword999";
        String newPassword = "newPassword@2026";
        String encodedOld = "$2a$10$encodedOldHash";

        User mockUser = new User();
        mockUser.setId(userId);
        mockUser.setPassword(encodedOld);

        ChangePasswordRequest request = new ChangePasswordRequest(wrongOldPassword, newPassword);

        when(userRepository.findById(userId)).thenReturn(Optional.of(mockUser));
        when(passwordEncoder.matches(wrongOldPassword, encodedOld)).thenReturn(false);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            userService.changePassword(userId, request);
        });

        assertEquals("Mật khẩu hiện tại không chính xác", exception.getMessage());
        verify(userRepository, never()).save(any());
        verify(passwordEncoder, never()).encode(any());
    }

    @Test
    @DisplayName("TC_AUTH_10: Đổi mật khẩu thất bại khi mật khẩu mới quá ngắn (< 6 ký tự) -> Ném 400 BadRequestException")
    void testChangePassword_WhenNewPasswordTooShort_ShouldThrowBadRequestException() {
        String userId = "USER-001";
        ChangePasswordRequest request = new ChangePasswordRequest("password123", "12345"); // 5 ký tự

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            userService.changePassword(userId, request);
        });

        assertTrue(exception.getMessage().contains("Mật khẩu mới phải có tối thiểu 6 ký tự"));
        verify(userRepository, never()).findById(any());
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_AUTH_11: Đổi mật khẩu thất bại khi mật khẩu mới trùng mật khẩu cũ -> Ném 400 BadRequestException")
    void testChangePassword_WhenNewPasswordSameAsOld_ShouldThrowBadRequestException() {
        String userId = "USER-001";
        String samePassword = "password123";
        ChangePasswordRequest request = new ChangePasswordRequest(samePassword, samePassword);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            userService.changePassword(userId, request);
        });

        assertEquals("Mật khẩu mới không được trùng với mật khẩu cũ", exception.getMessage());
        verify(userRepository, never()).findById(any());
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("Đổi mật khẩu thất bại khi không tìm thấy người dùng -> Ném 404 ResourceNotFoundException")
    void testChangePassword_WhenUserNotFound_ShouldThrowResourceNotFoundException() {
        String nonExistUserId = "USER-NOT-FOUND";
        ChangePasswordRequest request = new ChangePasswordRequest("oldPassword123", "newPassword@2026");

        when(userRepository.findById(nonExistUserId)).thenReturn(Optional.empty());

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            userService.changePassword(nonExistUserId, request);
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy người dùng với ID: " + nonExistUserId));
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("Đổi mật khẩu thất bại khi payload rỗng (null) -> Ném 400 BadRequestException")
    void testChangePassword_WhenRequestIsNull_ShouldThrowBadRequestException() {
        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            userService.changePassword("USER-001", null);
        });

        assertEquals("Dữ liệu đổi mật khẩu không được để trống", exception.getMessage());
        verify(userRepository, never()).save(any());
    }
}
