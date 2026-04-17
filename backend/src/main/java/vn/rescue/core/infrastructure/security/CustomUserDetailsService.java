package vn.rescue.core.infrastructure.security;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.repositories.RoleRepository;
import vn.rescue.core.domain.repositories.UserRepository;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username)
                .map(user -> {
                    List<GrantedAuthority> authorities = new ArrayList<>();
                    if (user.getRoleId() != null) {
                        roleRepository.findById(user.getRoleId()).ifPresentOrElse(role -> {
                            if (role.getName() != null) {
                                String roleName = "ROLE_" + role.getName().toUpperCase();
                                authorities.add(new SimpleGrantedAuthority(roleName));
                                log.info("Loaded role: {} for user: {}", roleName, username);
                            }
                            if (role.getPermissions() != null) {
                                role.getPermissions().forEach(p -> {
                                    authorities.add(new SimpleGrantedAuthority(p));
                                    log.debug("Loaded permission: {} for user: {}", p, username);
                                });
                            }
                        }, () -> {
                            log.warn("Role ID {} not found for user: {}", user.getRoleId(), username);
                        });
                    } else {
                        log.warn("User {} has no role assigned", username);
                    }
                    
                    log.info("Total authorities for user {}: {}", username, authorities.size());
                    return new User(
                            user.getEmail(),
                            user.getPassword(),
                            authorities
                    );
                })
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }
}
