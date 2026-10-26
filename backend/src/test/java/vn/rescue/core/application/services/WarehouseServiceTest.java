package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.WarehouseRequest;
import vn.rescue.core.domain.entities.Warehouse;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-28 [KCPM-46]: Unit Test cho Quản lý Kho cứu hộ (WarehouseService)")
class WarehouseServiceTest {

    @Mock
    private WarehouseRepository warehouseRepository;

    @Mock
    private RescueTeamRepository rescueTeamRepository;

    @Mock
    private RescueCoordinationService rescueCoordinationService;

    @InjectMocks
    private WarehouseService warehouseService;

    @Test
    @DisplayName("KCPM-28 [Subtask 1]: Xóa kho với ID không tồn tại -> Chặn ném 404 ResourceNotFoundException")
    void testDeleteWarehouse_WhenIdNotExists_ShouldThrowResourceNotFoundException() {
        String nonExistId = "WH-NOT-FOUND-999";
        when(warehouseRepository.existsById(nonExistId)).thenReturn(false);

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            warehouseService.deleteWarehouse(nonExistId);
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy kho bãi với ID: " + nonExistId));
        verify(warehouseRepository, never()).deleteById(anyString());
    }

    @Test
    @DisplayName("KCPM-28 [Subtask 1]: Cập nhật kho với ID không tồn tại -> Chặn ném 404 ResourceNotFoundException")
    void testUpdateWarehouse_WhenIdNotExists_ShouldThrowResourceNotFoundException() {
        String nonExistId = "WH-NOT-FOUND-999";
        WarehouseRequest updateRequest = new WarehouseRequest();
        updateRequest.setWarehouseName("Kho dã chiến cập nhật");

        when(warehouseRepository.findById(nonExistId)).thenReturn(Optional.empty());

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            warehouseService.updateWarehouse(nonExistId, updateRequest);
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy kho bãi với ID: " + nonExistId));
        verify(warehouseRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28: Cập nhật kho với payload null -> Ném BadRequestException 400")
    void testUpdateWarehouse_WhenRequestIsNull_ShouldThrowBadRequestException() {
        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            warehouseService.updateWarehouse("WH-01", null);
        });

        assertTrue(exception.getMessage().contains("Dữ liệu cập nhật kho không được để trống"));
        verify(warehouseRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28: Tạo kho với tên kho rỗng hoặc null -> Ném BadRequestException 400")
    void testCreateWarehouse_WhenNameIsBlank_ShouldThrowBadRequestException() {
        WarehouseRequest request = new WarehouseRequest();
        request.setWarehouseName("   ");

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            warehouseService.createWarehouse(request);
        });

        assertTrue(exception.getMessage().contains("Tên kho bãi không được để trống"));
        verify(warehouseRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28: Cập nhật kho hợp lệ -> Lưu thành công và trả về đối tượng đã lưu")
    void testUpdateWarehouse_Success() {
        String warehouseId = "WH-01";
        Warehouse existing = new Warehouse();
        existing.setId(warehouseId);
        existing.setWarehouseName("Kho cũ");

        WarehouseRequest request = new WarehouseRequest();
        request.setWarehouseName("Kho mới Lệ Thủy");
        request.setLocation("Quảng Bình");

        when(warehouseRepository.findById(warehouseId)).thenReturn(Optional.of(existing));
        when(warehouseRepository.save(any(Warehouse.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Warehouse updated = warehouseService.updateWarehouse(warehouseId, request);

        assertNotNull(updated);
        assertEquals("Kho mới Lệ Thủy", updated.getWarehouseName());
        assertEquals("Quảng Bình", updated.getLocation());
        verify(warehouseRepository, times(1)).save(any(Warehouse.class));
    }
}
