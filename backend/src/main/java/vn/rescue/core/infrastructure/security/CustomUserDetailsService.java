package vn.rescue.core.infrastructure.security;

import lombok.RequiredArgsConstructor;
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
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return userRepository.findByEmail(username)
                .map(user -> {
                    List<GrantedAuthority> authorities = new ArrayList<>();
                    if (user.getRoleId() != null) {
                        roleRepository.findById(user.getRoleId()).ifPresent(role -> {
                            if (role.getName() != null) {
                                authorities.add(new SimpleGrantedAuthority("ROLE_" + role.getName().toUpperCase()));
                            }
                            if (role.getPermissions() != null) {
                                role.getPermissions().forEach(p -> authorities.add(new SimpleGrantedAuthority(p)));
                            }
                        });
                    }
                    return new User(
                            user.getEmail(),
                            user.getPassword(),
                            authorities
                    );
                })
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }
}
