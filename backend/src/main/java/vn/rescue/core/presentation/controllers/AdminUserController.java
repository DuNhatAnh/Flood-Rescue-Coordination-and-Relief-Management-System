package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.UserDto;
import vn.rescue.core.application.services.UserService;
import vn.rescue.core.application.services.SystemManagementService;
import vn.rescue.core.domain.entities.Role;
import vn.rescue.core.presentation.common.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/users")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminUserController {
    private final UserService userService;
    private final SystemManagementService systemManagementService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserDto>>> getAllUsers(@RequestParam(required = false) String query) {
        return ResponseEntity.ok(ApiResponse.success(userService.getAllUsers(query), "User list retrieved"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserDto>> createUser(@RequestBody UserDto userDto) {
        UserDto createdUser = userService.createUser(userDto);
        systemManagementService.logAction("ADMIN", "CREATE_USER", "Created user " + createdUser.getEmail());
        return ResponseEntity.ok(ApiResponse.success(createdUser, "User created successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserDto>> getUserById(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(userService.getUserById(id), "User found"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserDto>> updateUser(
            @PathVariable String id, 
            @RequestBody UserDto userDto) {
        UserDto updatedUser = userService.updateUser(id, userDto);
        systemManagementService.logAction("ADMIN", "UPDATE_USER", "Updated info for user " + id);
        return ResponseEntity.ok(ApiResponse.success(updatedUser, "User updated successfully"));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<UserDto>> updateUserStatus(
            @PathVariable String id, 
            @RequestParam String status) {
        UserDto updatedUser = userService.updateUserStatus(id, status);
        systemManagementService.logAction("ADMIN", "UPDATE_USER_STATUS", "User " + id + " set to " + status);
        return ResponseEntity.ok(ApiResponse.success(updatedUser, "User status updated"));
    }

    @PutMapping("/{id}/role")
    public ResponseEntity<ApiResponse<UserDto>> updateUserRole(
            @PathVariable String id, 
            @RequestParam String roleId) {
        UserDto updatedUser = userService.updateUserRole(id, roleId);
        systemManagementService.logAction("ADMIN", "UPDATE_USER_ROLE", "User " + id + " role changed to " + roleId);
        return ResponseEntity.ok(ApiResponse.success(updatedUser, "User role updated"));
    }

    @GetMapping("/roles")
    public ResponseEntity<ApiResponse<List<Role>>> getAllRoles() {
        return ResponseEntity.ok(ApiResponse.success(systemManagementService.getAllRoles(), "Roles retrieved"));
    }
}
