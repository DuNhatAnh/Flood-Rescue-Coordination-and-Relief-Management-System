package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.RoleDto;
import vn.rescue.core.application.services.RoleService;
import vn.rescue.core.presentation.common.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/roles")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class RoleController {
    
    private final RoleService roleService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<RoleDto>>> getAllRoles() {
        return ResponseEntity.ok(ApiResponse.success(roleService.getAllRoles(), "Roles retrieved successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RoleDto>> getRoleById(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(roleService.getRoleById(id), "Role retrieved successfully"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RoleDto>> createRole(@RequestBody RoleDto roleDto) {
        return ResponseEntity.ok(ApiResponse.success(roleService.createRole(roleDto), "Role created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RoleDto>> updateRole(@PathVariable String id, @RequestBody RoleDto roleDto) {
        return ResponseEntity.ok(ApiResponse.success(roleService.updateRole(id, roleDto), "Role updated successfully"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRole(@PathVariable String id) {
        roleService.deleteRole(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Role deleted successfully"));
    }
}
