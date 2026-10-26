package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
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
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));

        UserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());
        String token = jwtService.generateToken(userDetails);

        User user = userRepository.findByEmail(request.getEmail()).orElseThrow();

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

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<String>> changePassword(
            @RequestBody ChangePasswordRequest request,
            Principal principal) {
        String email = principal != null ? principal.getName() : null;
        userService.changePasswordByEmail(email, request);
        return ResponseEntity.ok(ApiResponse.success(null, "Đổi mật khẩu thành công"));
    }
}

