package vn.rescue.core.infrastructure.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import vn.rescue.core.domain.repositories.RoleRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final UserRepository userRepository;
    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http, 
            JwtAuthenticationFilter jwtAuthFilter,
            AuthenticationProvider authenticationProvider
    ) throws Exception {
        http
<<<<<<< HEAD
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        .requestMatchers("/api/warehouses/**", "/api/relief-items/**", "/api/inventory/**", "/api/upload/**", "/uploads/**", "/api/v1/rescue-requests/stats").permitAll()
                        .anyRequest().authenticated())
=======
                // Tắt CSRF để cho phép các method POST/PUT/PATCH/DELETE từ Postman
                .csrf(AbstractHttpConfigurer::disable)
                // Cấu hình CORS để Flutter/Web có thể gọi API
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .authorizeHttpRequests(auth -> auth
                        // 1. Cho phép các đường dẫn xác thực và tài liệu API
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                        // 2. SỬA LỖI TẠI ĐÂY: Thêm các endpoint nghiệp vụ vào permitAll
                        // Chúng ta cho phép cả /api/v1/** và các đường dẫn /api/** không có v1
                        .requestMatchers("/api/v1/**").permitAll()
                        .requestMatchers("/api/notifications/**").permitAll() // Khớp với NotificationController
                        .requestMatchers("/api/admin/system/**").permitAll()  // Khớp với Dashboard/Logs
                        .requestMatchers("/api/inventory/**").permitAll()      // Khớp với Inventory

                        // 3. Cho phép các tài nguyên khác
                        .requestMatchers("/api/warehouses/**", "/api/relief-items/**", "/api/upload/**", "/uploads/**").permitAll()

                        // 4. Tất cả các yêu cầu còn lại mới yêu cầu Token
                        .anyRequest().authenticated())

>>>>>>> 0934fba440f64f23273ef2bfce6ef3a221277d4d
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authenticationProvider(authenticationProvider)
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "x-auth-token"));
        configuration.setExposedHeaders(List.of("Authorization"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public AuthenticationProvider authenticationProvider(org.springframework.security.core.userdetails.UserDetailsService userDetailsService) {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}