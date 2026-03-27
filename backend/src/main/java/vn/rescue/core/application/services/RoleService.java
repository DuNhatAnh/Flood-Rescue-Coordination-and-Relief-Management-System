package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.RoleDto;
import vn.rescue.core.domain.entities.Role;
import vn.rescue.core.domain.repositories.RoleRepository;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoleService {
    
    private final RoleRepository roleRepository;
    private final SystemManagementService systemManagementService;

    public List<RoleDto> getAllRoles() {
        return roleRepository.findAll().stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    public RoleDto getRoleById(String id) {
        Role role = roleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Role not found"));
        return mapToDto(role);
    }

    public RoleDto createRole(RoleDto roleDto) {
        if (roleRepository.findByName(roleDto.getName()).isPresent()) {
            throw new RuntimeException("Role name already exists");
        }
        Role role = Role.builder()
                .name(roleDto.getName() != null ? roleDto.getName().toUpperCase() : null)
                .description(roleDto.getDescription())
                .permissions(roleDto.getPermissions())
                .build();
        Role savedRole = roleRepository.save(role);
        
        systemManagementService.logAction("ADMIN", "CREATE_ROLE", "Created role " + savedRole.getName());
        return mapToDto(savedRole);
    }

    public RoleDto updateRole(String id, RoleDto roleDto) {
        Role role = roleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Role not found"));
        
        if (roleDto.getName() != null && !roleDto.getName().equalsIgnoreCase(role.getName())) {
            if (roleRepository.findByName(roleDto.getName()).isPresent()) {
                throw new RuntimeException("Role name already exists");
            }
            role.setName(roleDto.getName().toUpperCase());
        }
        
        if (roleDto.getDescription() != null) {
            role.setDescription(roleDto.getDescription());
        }
        
        if (roleDto.getPermissions() != null) {
            role.setPermissions(roleDto.getPermissions());
        }

        Role updatedRole = roleRepository.save(role);
        systemManagementService.logAction("ADMIN", "UPDATE_ROLE", "Updated role " + updatedRole.getName());
        return mapToDto(updatedRole);
    }

    public void deleteRole(String id) {
        Role role = roleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Role not found"));
        roleRepository.delete(role);
        systemManagementService.logAction("ADMIN", "DELETE_ROLE", "Deleted role " + role.getName());
    }

    private RoleDto mapToDto(Role role) {
        return RoleDto.builder()
                .id(role.getId())
                .name(role.getName())
                .description(role.getDescription())
                .permissions(role.getPermissions())
                .build();
    }
}
