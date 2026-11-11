package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.DistributionRequest;
import vn.rescue.core.domain.entities.Distribution;
import vn.rescue.core.domain.entities.DistributionDetail;
import vn.rescue.core.domain.entities.Inventory;
import vn.rescue.core.domain.repositories.*;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-28 & KCPM-103: Unit Test cho Phân phối, Xuất kho và Hủy hoàn kho (DistributionService)")
class DistributionServiceTest {

    @Mock
    private DistributionRepository distributionRepository;

    @Mock
    private DistributionDetailRepository detailRepository;

    @Mock
    private InventoryRepository inventoryRepository;

    @Mock
    private AssignmentRepository assignmentRepository;

    @Mock
    private RescueCoordinationService rescueCoordinationService;

    @Mock
    private InventoryService inventoryService;

    @Mock
    private ReliefItemRepository reliefItemRepository;

    @Mock
    private WarehouseRepository warehouseRepository;

    @InjectMocks
    private DistributionService distributionService;

    @Test
    @DisplayName("KCPM-28 [BUG-DIST-01]: Xuất hàng vượt quá số lượng tồn kho -> Chặn ném 400 BadRequestException")
    void testCreateDistribution_WhenQuantityExceedsAvailableInventory_ShouldThrowBadRequest() {
        String warehouseId = "WH-LE-THUY";
        String itemId = "ITEM-AO-PHAO";

        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        Inventory mockInventory = new Inventory();
        mockInventory.setItemId(itemId);
        mockInventory.setItemName("Áo phao cứu sinh");
        mockInventory.setQuantity(10); // Tồn kho chỉ còn 10
        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId))
                .thenReturn(Optional.of(mockInventory));

        DistributionRequest request = new DistributionRequest();
        request.setWarehouseId(warehouseId);

        DistributionRequest.ItemQuantity itemReq = new DistributionRequest.ItemQuantity();
        itemReq.setItemId(itemId);
        itemReq.setQuantity(50); // Yêu cầu xuất 50 cái (vượt tồn kho)
        request.setItems(List.of(itemReq));

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            distributionService.createDistribution(request, "user-staff-01");
        });

        assertTrue(exception.getMessage().contains("Số lượng tồn kho không đủ cho mặt hàng 'Áo phao cứu sinh'"));
        assertTrue(exception.getMessage().contains("Hiện có: 10, Yêu cầu xuất: 50"));
        verify(distributionRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28: Xuất hàng từ kho không tồn tại -> Chặn ném 404 ResourceNotFoundException")
    void testCreateDistribution_WhenWarehouseNotExists_ShouldThrowResourceNotFoundException() {
        String nonExistWarehouseId = "WH-INVALID-001";
        when(warehouseRepository.existsById(nonExistWarehouseId)).thenReturn(false);

        DistributionRequest request = new DistributionRequest();
        request.setWarehouseId(nonExistWarehouseId);
        DistributionRequest.ItemQuantity itemReq = new DistributionRequest.ItemQuantity();
        itemReq.setItemId("ITEM-01");
        itemReq.setQuantity(5);
        request.setItems(List.of(itemReq));

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            distributionService.createDistribution(request, "user-staff-01");
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy kho hàng với ID: " + nonExistWarehouseId));
        verify(distributionRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28: Xuất hàng với số lượng <= 0 -> Chặn ném 400 BadRequestException")
    void testCreateDistribution_WhenQuantityIsZeroOrNegative_ShouldThrowBadRequest() {
        String warehouseId = "WH-01";
        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        DistributionRequest request = new DistributionRequest();
        request.setWarehouseId(warehouseId);
        DistributionRequest.ItemQuantity itemReq = new DistributionRequest.ItemQuantity();
        itemReq.setItemId("ITEM-01");
        itemReq.setQuantity(0); // Số lượng không hợp lệ
        request.setItems(List.of(itemReq));

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            distributionService.createDistribution(request, "user-staff-01");
        });

        assertTrue(exception.getMessage().contains("Mặt hàng và số lượng phân phối không hợp lệ"));
        verify(distributionRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28: Xuất hàng hợp lệ đủ tồn kho -> Tạo phiếu phân phối COMPLETED thành công")
    void testCreateDistribution_Success() {
        String warehouseId = "WH-01";
        String itemId = "ITEM-NUOC-KHOANG";

        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        Inventory mockInventory = new Inventory();
        mockInventory.setItemId(itemId);
        mockInventory.setItemName("Nước suối đóng chai");
        mockInventory.setQuantity(100);
        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId))
                .thenReturn(Optional.of(mockInventory));

        DistributionRequest request = new DistributionRequest();
        request.setWarehouseId(warehouseId);
        request.setRequestId("REQ-SOS-01");
        DistributionRequest.ItemQuantity itemReq = new DistributionRequest.ItemQuantity();
        itemReq.setItemId(itemId);
        itemReq.setQuantity(20);
        request.setItems(List.of(itemReq));

        when(distributionRepository.save(any(Distribution.class))).thenAnswer(invocation -> {
            Distribution d = invocation.getArgument(0);
            d.setId("DIST-CREATED-01");
            return d;
        });

        Distribution result = distributionService.createDistribution(request, "user-staff-01");

        assertNotNull(result);
        assertEquals("DIST-CREATED-01", result.getId());
        assertEquals("COMPLETED", result.getStatus());
        assertEquals(warehouseId, result.getWarehouseId());
        verify(distributionRepository, times(1)).save(any(Distribution.class));
    }

    // ============================================================
    // KCPM-103: UNIT TESTS CHO HỦY ĐỢT PHÂN PHỐI VÀ HOÀN KHO (ROLLBACK)
    // ============================================================

    @Test
    @DisplayName("KCPM-103: Hủy đợt phân phối hợp lệ (chưa COMPLETED) -> Hoàn kho 100% và trạng thái CANCELLED")
    void testCancelDistribution_Success_ShouldRollbackInventoryAndSetStatusCancelled() {
        String distId = "DIST-TRANSIT-01";
        String warehouseId = "WH-01";
        String itemId = "ITEM-MI-TOM";

        Distribution mockDist = new Distribution();
        mockDist.setId(distId);
        mockDist.setWarehouseId(warehouseId);
        mockDist.setType("TRANSFER");
        mockDist.setStatus("IN_TRANSIT"); // Chưa COMPLETED

        DistributionDetail detail = new DistributionDetail();
        detail.setDistributionId(distId);
        detail.setItemId(itemId);
        detail.setQuantity(30); // 30 thùng mì đã xuất

        Inventory inventory = new Inventory();
        inventory.setWarehouseId(warehouseId);
        inventory.setItemId(itemId);
        inventory.setQuantity(70); // Tồn kho hiện tại sau khi xuất

        when(distributionRepository.findById(distId)).thenReturn(Optional.of(mockDist));
        when(detailRepository.findAllByDistributionId(distId)).thenReturn(List.of(detail));
        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId)).thenReturn(Optional.of(inventory));
        when(distributionRepository.save(any(Distribution.class))).thenAnswer(i -> i.getArgument(0));

        Distribution cancelled = distributionService.cancelDistribution(distId, "Nước rút, đổi phương án cứu hộ", "admin-01");

        assertNotNull(cancelled);
        assertEquals("CANCELLED", cancelled.getStatus(), "Trạng thái phải chuyển sang CANCELLED");
        assertNotNull(cancelled.getCancelledAt(), "Thời gian hủy phải được ghi nhận");
        assertEquals("Nước rút, đổi phương án cứu hộ", cancelled.getCancelReason());
        assertEquals("admin-01", cancelled.getCancelledBy());

        // Kiểm tra cơ chế tự động hoàn kho (Rollback Inventory: 70 + 30 = 100)
        assertEquals(100, inventory.getQuantity(), "Tồn kho phải được hoàn trả 100% nguyên vẹn");
        verify(inventoryRepository, times(1)).save(inventory);
        verify(distributionRepository, times(1)).save(mockDist);
    }

    @Test
    @DisplayName("KCPM-103: Chặn hủy đợt phân phối khi trạng thái đã là COMPLETED -> Ném 400 BadRequestException")
    void testCancelDistribution_WhenStatusIsCompleted_ShouldThrowBadRequestException() {
        String distId = "DIST-COMPLETED-01";
        Distribution mockDist = new Distribution();
        mockDist.setId(distId);
        mockDist.setStatus("COMPLETED"); // Đã hoàn thành

        when(distributionRepository.findById(distId)).thenReturn(Optional.of(mockDist));

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            distributionService.cancelDistribution(distId, "Lý do hủy", "admin-01");
        });

        assertTrue(ex.getMessage().contains("Không thể hủy đợt phân phối đã hoàn thành (COMPLETED)"));
        verify(detailRepository, never()).findAllByDistributionId(any());
        verify(inventoryRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-103: Chặn hủy đợt phân phối khi đơn đã bị CANCELLED trước đó -> Ném 400 BadRequestException")
    void testCancelDistribution_WhenStatusAlreadyCancelled_ShouldThrowBadRequestException() {
        String distId = "DIST-CANCELLED-01";
        Distribution mockDist = new Distribution();
        mockDist.setId(distId);
        mockDist.setStatus("CANCELLED"); // Đã hủy rồi

        when(distributionRepository.findById(distId)).thenReturn(Optional.of(mockDist));

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            distributionService.cancelDistribution(distId, "Hủy lần 2", "admin-01");
        });

        assertTrue(ex.getMessage().contains("Đợt phân phối này đã bị hủy trước đó"));
        verify(inventoryRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-103: Hủy đợt phân phối với ID không tồn tại -> Ném 404 ResourceNotFoundException")
    void testCancelDistribution_WhenNotFound_ShouldThrowResourceNotFoundException() {
        String nonExistId = "DIST-NOT-FOUND";
        when(distributionRepository.findById(nonExistId)).thenReturn(Optional.empty());

        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class, () -> {
            distributionService.cancelDistribution(nonExistId, "Lý do", "admin-01");
        });

        assertTrue(ex.getMessage().contains("Không tìm thấy đợt phân phối với ID: " + nonExistId));
        verify(distributionRepository, never()).save(any());
    }
}
