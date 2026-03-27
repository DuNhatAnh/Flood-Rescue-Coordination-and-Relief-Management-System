package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.application.dto.UserDto;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final RescueTeamRepository rescueTeamRepository;
    private final PasswordEncoder passwordEncoder;

    public List<UserDto> getAllUsers(String query) {
        List<User> users;
        if (query != null && !query.isEmpty()) {
            users = userRepository.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCase(query, query);
        } else {
            users = userRepository.findAll();
        }
        return users.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    public UserDto getUserById(String id) {
        if (id == null) throw new IllegalArgumentException("ID cannot be null");
        return userRepository.findById(id)
                .map(this::mapToDto)
                .orElseThrow(() -> new RuntimeException("User not found: " + id));
    }

    public UserDto updateUser(String id, UserDto dto) {
        if (id == null) throw new IllegalArgumentException("ID cannot be null");
        User user = userRepository.findById(id).orElseThrow();
        user.setFullName(dto.getFullName());
        user.setPhone(dto.getPhone());
        user.setRoleId(dto.getRoleId());
        return mapToDto(userRepository.save(user));
    }

    public UserDto createUser(UserDto dto) {
        if (userRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists: " + dto.getEmail());
        }
        User user = new User();
        user.setFullName(dto.getFullName());
        user.setEmail(dto.getEmail());
        user.setPhone(dto.getPhone());
        user.setRoleId(dto.getRoleId() != null ? dto.getRoleId() : "USER");
        user.setPassword(passwordEncoder.encode("123456")); // Default password
        user.setStatus("ACTIVE");
        user.setCreatedAt(LocalDateTime.now());
        User savedUser = userRepository.save(user);

        // SCRUM-61: Auto-create team for Rescue Staff
        if ("RESCUE_STAFF".equals(savedUser.getRoleId())) {
            RescueTeam team = new RescueTeam();
            team.setTeamName("Đội " + savedUser.getFullName());
            team.setLeaderId(savedUser.getId());
            team.setStatus("AVAILABLE");
            RescueTeam savedTeam = rescueTeamRepository.save(team);
            
            savedUser.setTeamId(savedTeam.getId());
            userRepository.save(savedUser);
        }

        return mapToDto(savedUser);
    }

    public UserDto updateUserRole(String id, String roleId) {
        if (id == null) throw new IllegalArgumentException("ID cannot be null");
        User user = userRepository.findById(id).orElseThrow();
        user.setRoleId(roleId);
        return mapToDto(userRepository.save(user));
    }

    public UserDto updateUserStatus(String userId, String status) {
        if (userId == null) throw new IllegalArgumentException("User ID cannot be null");
        User user = userRepository.findById(userId).orElseThrow();
        user.setStatus(status);
        return mapToDto(userRepository.save(user));
    }

    private UserDto mapToDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .roleId(user.getRoleId())
                .status(user.getStatus())
                .build();
    }
}
