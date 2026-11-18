package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.rescue.core.application.dto.AuthRequest;
import vn.rescue.core.application.dto.AuthResponse;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.infrastructure.security.JwtService;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.repositories.RescueTeamRepository;


import java.security.Principal;
import java.util.stream.Collectors;
import org.springframework.security.core.GrantedAuthority;
import vn.rescue.core.application.dto.ChangePasswordRequest;
import vn.rescue.core.application.services.UserService;
import vn.rescue.core.presentation.common.ApiResponse;

@RestController
@RequestMapping({"/api/v1/auth", "/api/auth"})
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final RescueTeamRepository rescueTeamRepository;
    private final UserService userService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody(required = false) AuthRequest request) {
        validateLoginInput(request);
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
        } catch (LockedException e) {
            // Spring Security đã chặn trước (accountNonLocked = false) -> trả thông báo nghiệp vụ tiếng Việt
            throw new LockedException("Tài khoản đã bị khóa do vi phạm chính sách");
        } catch (DisabledException e) {
            // Spring Security đã chặn trước (enabled = false với status INACTIVE) -> trả thông báo nghiệp vụ tiếng Việt
            throw new DisabledException("Tài khoản đã bị vô hiệu hóa hoặc chưa được kích hoạt");
        }

        User user = userRepository.findByEmail(request.getEmail()).orElseThrow();
        if (user.getStatus() != null && !"ACTIVE".equalsIgnoreCase(user.getStatus())) {
            if ("LOCKED".equalsIgnoreCase(user.getStatus())) {
                throw new LockedException("Tài khoản đã bị khóa do vi phạm chính sách");
            }
            throw new DisabledException("Tài khoản đã bị vô hiệu hóa hoặc chưa được kích hoạt");
        }

        UserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
        String token = jwtService.generateToken(userDetails);

        String teamName = null;
        if (user.getTeamId() != null) {
            teamName = rescueTeamRepository.findById(user.getTeamId())
                    .map(RescueTeam::getTeamName)
                    .orElse(null);
        }

        return ResponseEntity.ok(AuthResponse.builder()
                .id(user.getId())
                .token(token)
                .email(user.getEmail())
                .fullName(user.getFullName())
                .teamId(user.getTeamId())
                .teamName(teamName)
                .roles(userDetails.getAuthorities().stream()
                        .map(GrantedAuthority::getAuthority)
                        .collect(Collectors.toList()))
                .build());
    }

    /** Phân vùng tương đương đầu vào đăng nhập (thiết kế KCPM-89: auth_login_data.csv TC_LOG_06 -> TC_LOG_09) */
    private void validateLoginInput(AuthRequest request) {
        String email = request != null ? request.getEmail() : null;
        String password = request != null ? request.getPassword() : null;
        if (email == null && password == null) {
            throw new BadRequestException("Dữ liệu đăng nhập không được để trống");
        }
        if (email == null || email.trim().isEmpty()) {
            throw new BadRequestException("Email không được để trống");
        }
        if (password == null || password.trim().isEmpty()) {
            throw new BadRequestException("Mật khẩu không được để trống");
        }
        if (!email.trim().matches("^[\\w.+-]+@[\\w-]+(\\.[\\w-]+)+$")) {
            throw new BadRequestException("Email không đúng định dạng");
        }
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<String>> changePassword(
            @RequestBody ChangePasswordRequest request,
            Principal principal) {
        String email = principal != null ? principal.getName() : null;
        userService.changePasswordByEmail(email, request);
        return ResponseEntity.ok(ApiResponse.success(null, "Đổi mật khẩu thành công"));
    }
}

