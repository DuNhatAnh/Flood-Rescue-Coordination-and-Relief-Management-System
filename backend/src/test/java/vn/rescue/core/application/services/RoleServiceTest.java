package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.RoleDto;
import vn.rescue.core.domain.entities.Role;
import vn.rescue.core.domain.repositories.RoleRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.DuplicateResourceException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("EPIC 01 - 1.6: Unit Test cho Quản lý Vai trò (RoleService)")
class RoleServiceTest {

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private SystemManagementService systemManagementService;

    @InjectMocks
    private RoleService roleService;

    @Test
    @DisplayName("Tạo Role hợp lệ -> tên được chuẩn hóa IN HOA và lưu thành công")
    void createRole_Valid_ShouldNormalizeNameAndSave() {
        when(roleRepository.findByName("QA_TESTER")).thenReturn(Optional.empty());
        when(roleRepository.save(any(Role.class))).thenAnswer(inv -> {
            Role r = inv.getArgument(0);
            r.setId("generated-id");
            return r;
        });

        RoleDto result = roleService.createRole(RoleDto.builder()
                .name("  qa_tester ").description("Kiểm thử").permissions(List.of("REPORT")).build());

        assertEquals("generated-id", result.getId());
        assertEquals("QA_TESTER", result.getName());
        verify(systemManagementService).logAction(eq("ADMIN"), eq("CREATE_ROLE"), any());
    }

    @Test
    @DisplayName("Tạo Role với tên rỗng/null -> ném 400 BadRequestException, không lưu DB")
    void createRole_BlankName_ShouldThrowBadRequest() {
        assertThrows(BadRequestException.class, () -> roleService.createRole(RoleDto.builder().name("   ").build()));
        assertThrows(BadRequestException.class, () -> roleService.createRole(RoleDto.builder().build()));
        verify(roleRepository, never()).save(any());
    }

    @Test
    @DisplayName("Tạo Role trùng tên (khác hoa thường) -> ném 409 DuplicateResourceException")
    void createRole_DuplicateName_ShouldThrowConflict() {
        when(roleRepository.findByName("ADMIN")).thenReturn(Optional.of(Role.builder().id("ADMIN").name("ADMIN").build()));

        assertThrows(DuplicateResourceException.class, () -> roleService.createRole(RoleDto.builder().name("admin").build()));
        verify(roleRepository, never()).save(any());
    }

    @Test
    @DisplayName("Lấy / Sửa / Xóa Role không tồn tại -> ném 404 ResourceNotFoundException")
    void notExistingRole_ShouldThrowNotFound() {
        when(roleRepository.findById("NOT_FOUND")).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> roleService.getRoleById("NOT_FOUND"));
        assertThrows(ResourceNotFoundException.class, () -> roleService.updateRole("NOT_FOUND", new RoleDto()));
        assertThrows(ResourceNotFoundException.class, () -> roleService.deleteRole("NOT_FOUND"));
        verify(roleRepository, never()).delete(any());
    }
}
