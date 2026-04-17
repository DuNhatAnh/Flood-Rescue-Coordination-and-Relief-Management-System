package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.entities.Warehouse;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.application.dto.UserDto;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {
    private final UserRepository userRepository;
    private final RescueTeamRepository rescueTeamRepository;
    private final VehiclesRepository vehiclesRepository;
    private final WarehouseRepository warehouseRepository;
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
        user.setTeamId(dto.getTeamId());
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
        user.setTeamId(dto.getTeamId()); // Set team if provided
        User savedUser = userRepository.save(user);

        // SCRUM-61: Auto-create team for Rescue Staff only if no teamId provided
        if ("RESCUE_STAFF".equals(savedUser.getRoleId()) && savedUser.getTeamId() == null) {
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

    @Transactional
    public UserDto updateUserRole(String id, String roleId) {
        User user = userRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
        String oldRoleId = user.getRoleId();
        
        // Luồng 1: Nếu từ NHÂN VIÊN chuyển sang vai trò khác (Xóa đội, giải phóng kho/phương tiện)
        if ("RESCUE_STAFF".equals(oldRoleId) && !"RESCUE_STAFF".equals(roleId)) {
            rescueTeamRepository.findByLeaderId(id).ifPresent(team -> {
                // 1. Giải phóng toàn bộ phương tiện của đội
                List<Vehicles> teamVehicles = vehiclesRepository.findByTeamId(team.getId());
                for (Vehicles v : teamVehicles) {
                    v.setTeamId(null);
                    v.setStatus("AVAILABLE");
                    vehiclesRepository.save(v);
                }
                // 2. Xóa hoàn toàn đội cứu hộ
                rescueTeamRepository.delete(team);
                log.info("Deleted RescueTeam {} and released {} vehicles for user {} due to role change", team.getId(), teamVehicles.size(), id);
            });
            user.setTeamId(null);
        }
        
        // Luồng 2: Nếu từ vai trò khác chuyển sang NHÂN VIÊN (Tạo đội, gán kho trống 1:1)
        if (!"RESCUE_STAFF".equals(oldRoleId) && "RESCUE_STAFF".equals(roleId)) {
            if (user.getTeamId() == null) {
                RescueTeam team = new RescueTeam();
                team.setTeamName("Đội " + user.getFullName());
                team.setLeaderId(user.getId());
                team.setStatus("AVAILABLE");
                
                // Logic Ràng buộc 1 Kho - 1 Đội
                List<Warehouse> allWarehouses = warehouseRepository.findAll();
                String vacantWarehouseId = null;
                for (Warehouse w : allWarehouses) {
                    if (rescueTeamRepository.findByWarehouseId(w.getId()).isEmpty()) {
                        vacantWarehouseId = w.getId();
                        break;
                    }
                }
                
                if (vacantWarehouseId != null) {
                    team.setWarehouseId(vacantWarehouseId);
                    log.info("Assigned vacant warehouse {} to new team for user {}", vacantWarehouseId, id);
                } else {
                    log.warn("No vacant warehouse available for new team for user {}", id);
                }
                
                RescueTeam savedTeam = rescueTeamRepository.save(team);
                user.setTeamId(savedTeam.getId());
            }
        }

        user.setRoleId(roleId);
        log.info("Updated User {} role from {} to {}", id, oldRoleId, roleId);
        User savedUser = userRepository.save(user);
        return mapToDto(savedUser);
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
                .teamId(user.getTeamId())
                .build();
    }
}
