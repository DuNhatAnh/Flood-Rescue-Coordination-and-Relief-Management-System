package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.WarehouseRequest;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.entities.Warehouse;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-126 [Sprint 5]: Chuẩn hóa độ phủ hộp trắng 100% câu lệnh cho WarehouseService")
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
        request.setStatus("ACTIVE");

        when(warehouseRepository.findById(warehouseId)).thenReturn(Optional.of(existing));
        when(warehouseRepository.save(any(Warehouse.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Warehouse updated = warehouseService.updateWarehouse(warehouseId, request);

        assertNotNull(updated);
        assertEquals("Kho mới Lệ Thủy", updated.getWarehouseName());
        assertEquals("Quảng Bình", updated.getLocation());
        verify(warehouseRepository, times(1)).save(any(Warehouse.class));
    }

    // =========================================================================
    // KCPM-126: CÁC CA KIỂM THỬ HỘP TRẮNG BỔ SUNG ĐẠT 100% STATEMENT COVERAGE
    // =========================================================================

    @Test
    @DisplayName("WB_WAREHOUSE_01: Tạo kho thành công kèm gán ManagerId -> Xử lý chuyển giao kho cũ và đồng bộ Đội cứu hộ (Dòng 30-44)")
    void testCreateWarehouse_Success_WithManagerReassignmentAndTeamSync() {
        String managerId = "LEADER-01";
        WarehouseRequest request = new WarehouseRequest();
        request.setWarehouseName("Kho Trung Tâm Ái Nghĩa");
        request.setLocation("Đại Lộc, Quảng Nam");
        request.setManagerId(managerId);
        request.setStatus("ACTIVE");
        request.setLatitude(15.889);
        request.setLongitude(108.123);

        Warehouse oldWarehouse = new Warehouse();
        oldWarehouse.setId("WH-OLD-01");
        oldWarehouse.setManagerId(managerId);

        Warehouse savedWarehouse = new Warehouse();
        savedWarehouse.setId("WH-NEW-01");
        savedWarehouse.setWarehouseName("Kho Trung Tâm Ái Nghĩa");
        savedWarehouse.setManagerId(managerId);
        savedWarehouse.setStatus("ACTIVE");
        savedWarehouse.setCreatedAt(LocalDateTime.now());

        RescueTeam team = new RescueTeam();
        team.setId("TEAM-01");
        team.setLeaderId(managerId);
        team.setWarehouseId("WH-OLD-01");

        when(warehouseRepository.findByManagerId(managerId)).thenReturn(Optional.of(oldWarehouse));
        when(warehouseRepository.save(any(Warehouse.class))).thenReturn(savedWarehouse);
        when(rescueTeamRepository.findByLeaderId(managerId)).thenReturn(Optional.of(team));
        when(warehouseRepository.findById("WH-NEW-01")).thenReturn(Optional.of(savedWarehouse));

        Warehouse result = warehouseService.createWarehouse(request);

        assertNotNull(result);
        assertEquals("WH-NEW-01", result.getId());
        assertEquals(managerId, result.getManagerId());
        assertEquals("WH-NEW-01", team.getWarehouseId(), "Đội cứu hộ phải được cập nhật mã kho mới");

        verify(warehouseRepository, times(1)).save(oldWarehouse);
        verify(rescueTeamRepository, times(1)).save(team);
        verify(rescueCoordinationService, times(1)).notifyTeam(eq("TEAM-01"), anyString(), anyString(), eq("INFO"));
    }

    @Test
    @DisplayName("WB_WAREHOUSE_02: Xóa kho thành công khi ID tồn tại (Dòng 112-113)")
    void testDeleteWarehouse_Success_WhenIdExists() {
        String warehouseId = "WH-EXIST-01";
        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);
        doNothing().when(warehouseRepository).deleteById(warehouseId);

        warehouseService.deleteWarehouse(warehouseId);

        verify(warehouseRepository, times(1)).existsById(warehouseId);
        verify(warehouseRepository, times(1)).deleteById(warehouseId);
    }

    @Test
    @DisplayName("WB_WAREHOUSE_03: Cập nhật kho thay đổi ManagerId -> Xử lý chuyển giao kho cũ và đồng bộ Đội cứu hộ (Dòng 54-56)")
    void testUpdateWarehouse_Success_WithNewManager() {
        String warehouseId = "WH-01";
        String oldManagerId = "LEADER-OLD";
        String newManagerId = "LEADER-NEW";

        Warehouse existing = new Warehouse();
        existing.setId(warehouseId);
        existing.setWarehouseName("Kho Dã Chiến 1");
        existing.setManagerId(oldManagerId);

        WarehouseRequest request = new WarehouseRequest();
        request.setWarehouseName("Kho Dã Chiến 1 (Cập nhật)");
        request.setManagerId(newManagerId);

        Warehouse prevManagedWarehouse = new Warehouse();
        prevManagedWarehouse.setId("WH-OTHER");
        prevManagedWarehouse.setManagerId(newManagerId);

        RescueTeam team = new RescueTeam();
        team.setId("TEAM-NEW");
        team.setLeaderId(newManagerId);
        team.setWarehouseId("WH-OTHER");

        when(warehouseRepository.findById(warehouseId)).thenReturn(Optional.of(existing));
        when(warehouseRepository.findByManagerId(newManagerId)).thenReturn(Optional.of(prevManagedWarehouse));
        when(warehouseRepository.save(any(Warehouse.class))).thenAnswer(i -> i.getArgument(0));
        when(rescueTeamRepository.findByLeaderId(newManagerId)).thenReturn(Optional.of(team));

        Warehouse updated = warehouseService.updateWarehouse(warehouseId, request);

        assertNotNull(updated);
        assertEquals(newManagerId, updated.getManagerId());
        verify(warehouseRepository, atLeastOnce()).save(any(Warehouse.class));
        verify(rescueTeamRepository, times(1)).save(team);
    }

    @Test
    @DisplayName("WB_WAREHOUSE_04: Lấy danh sách tất cả các kho -> Trả về danh sách kho đầy đủ")
    void testGetAllWarehouses() {
        Warehouse w1 = new Warehouse();
        w1.setId("WH-01");
        when(warehouseRepository.findAll()).thenReturn(List.of(w1));

        List<Warehouse> list = warehouseService.getAllWarehouses();

        assertNotNull(list);
        assertEquals(1, list.size());
        verify(warehouseRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("WB_WAREHOUSE_05: Lấy thông tin kho theo ID tồn tại và ID không tồn tại")
    void testGetWarehouseById() {
        String warehouseId = "WH-01";
        Warehouse warehouse = new Warehouse();
        warehouse.setId(warehouseId);

        when(warehouseRepository.findById(warehouseId)).thenReturn(Optional.of(warehouse));
        when(warehouseRepository.findById("NON-EXIST")).thenReturn(Optional.empty());

        Warehouse found = warehouseService.getWarehouseById(warehouseId);
        assertNotNull(found);
        assertEquals(warehouseId, found.getId());

        assertThrows(ResourceNotFoundException.class, () -> warehouseService.getWarehouseById("NON-EXIST"));
    }

    @Test
    @DisplayName("WB_WAREHOUSE_06: Lấy thông tin kho theo ManagerId")
    void testGetWarehouseByManagerId() {
        String managerId = "MGR-01";
        Warehouse warehouse = new Warehouse();
        warehouse.setManagerId(managerId);

        when(warehouseRepository.findByManagerId(managerId)).thenReturn(Optional.of(warehouse));

        Warehouse found = warehouseService.getWarehouseByManagerId(managerId);
        assertNotNull(found);
        assertEquals(managerId, found.getManagerId());
        verify(warehouseRepository, times(1)).findByManagerId(managerId);
    }
}
