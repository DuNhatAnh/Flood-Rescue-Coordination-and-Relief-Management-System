package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.rescue.core.application.dto.UserDto;
import vn.rescue.core.application.services.UserService;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;
import vn.rescue.core.presentation.exceptions.UnauthorizedException;

import java.security.Principal;

@RestController
@RequestMapping({"/api/v1/users", "/api/users"})
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserDto>> getCurrentUser(Principal principal) {
        if (principal == null || principal.getName() == null) {
            throw new UnauthorizedException("Chưa xác thực hoặc token không hợp lệ");
        }
        User user = userRepository.findByEmail(principal.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin người dùng: " + principal.getName()));
        return ResponseEntity.ok(ApiResponse.success(userService.getUserById(user.getId()), "Lấy thông tin người dùng thành công"));
    }
}
