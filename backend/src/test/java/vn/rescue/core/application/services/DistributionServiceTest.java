package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.DistributionRequest;
import vn.rescue.core.domain.entities.Assignment;
import vn.rescue.core.domain.entities.Distribution;
import vn.rescue.core.domain.entities.DistributionDetail;
import vn.rescue.core.domain.entities.Inventory;
import vn.rescue.core.domain.repositories.*;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-126 [Sprint 5]: Chuẩn hóa độ phủ hộp trắng 100% câu lệnh cho DistributionService")
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

    // =========================================================================
    // KCPM-126: CÁC CA KIỂM THỬ HỘP TRẮNG BỔ SUNG ĐẠT 100% STATEMENT COVERAGE
    // =========================================================================

    @Test
    @DisplayName("WB_DISTRIBUTION_01: createDistribution khi request null -> Ném BadRequestException (Dòng 47)")
    void testCreateDistribution_WhenRequestIsNull_ShouldThrowBadRequest() {
        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            distributionService.createDistribution(null, "user-01");
        });
        assertTrue(ex.getMessage().contains("Dữ liệu phân phối hàng không được để trống"));
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_02: createDistribution khi warehouseId rỗng hoặc null -> Ném BadRequestException (Dòng 50)")
    void testCreateDistribution_WhenWarehouseIdIsBlank_ShouldThrowBadRequest() {
        DistributionRequest req = new DistributionRequest();
        req.setWarehouseId("   ");

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            distributionService.createDistribution(req, "user-01");
        });
        assertTrue(ex.getMessage().contains("Mã kho (warehouseId) không được để trống"));
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_03: createDistribution khi danh sách items rỗng hoặc null -> Ném BadRequestException (Dòng 56)")
    void testCreateDistribution_WhenItemsIsEmpty_ShouldThrowBadRequest() {
        String warehouseId = "WH-01";
        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        DistributionRequest req = new DistributionRequest();
        req.setWarehouseId(warehouseId);
        req.setItems(Collections.emptyList());

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            distributionService.createDistribution(req, "user-01");
        });
        assertTrue(ex.getMessage().contains("Danh sách mặt hàng phân phối không được để trống"));
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_04: createDistribution với status tùy chỉnh -> Gán đúng status (Dòng 83)")
    void testCreateDistribution_WithCustomStatus() {
        String warehouseId = "WH-01";
        String itemId = "ITEM-01";
        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        Inventory inv = new Inventory();
        inv.setQuantity(100);
        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId)).thenReturn(Optional.of(inv));

        DistributionRequest req = new DistributionRequest();
        req.setWarehouseId(warehouseId);
        req.setStatus("pending");
        DistributionRequest.ItemQuantity itemReq = new DistributionRequest.ItemQuantity();
        itemReq.setItemId(itemId);
        itemReq.setQuantity(10);
        req.setItems(List.of(itemReq));

        when(distributionRepository.save(any(Distribution.class))).thenAnswer(i -> i.getArgument(0));

        Distribution res = distributionService.createDistribution(req, "user-01");
        assertNotNull(res);
        assertEquals("PENDING", res.getStatus());
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_05: createDistribution điều chuyển kho TRANSFER có kho đích -> Gán IN_TRANSIT và gọi notifyWarehouse (Dòng 85, 94-98)")
    void testCreateDistribution_TransferType_ShouldSetInTransitAndNotifyDestination() {
        String warehouseId = "WH-SOURCE";
        String destWarehouseId = "WH-DEST";
        String itemId = "ITEM-01";

        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        Inventory inv = new Inventory();
        inv.setQuantity(50);
        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId)).thenReturn(Optional.of(inv));

        DistributionRequest req = new DistributionRequest();
        req.setWarehouseId(warehouseId);
        req.setType("TRANSFER");
        req.setDestinationWarehouseId(destWarehouseId);
        DistributionRequest.ItemQuantity itemReq = new DistributionRequest.ItemQuantity();
        itemReq.setItemId(itemId);
        itemReq.setQuantity(10);
        req.setItems(List.of(itemReq));

        when(distributionRepository.save(any(Distribution.class))).thenAnswer(i -> i.getArgument(0));

        Distribution res = distributionService.createDistribution(req, "user-01");

        assertNotNull(res);
        assertEquals("IN_TRANSIT", res.getStatus());
        assertEquals("TRANSFER", res.getType());
        assertEquals(destWarehouseId, res.getDestinationWarehouseId());

        verify(rescueCoordinationService, times(1)).notifyWarehouse(
                eq(destWarehouseId),
                eq("Yêu cầu điều phối hàng"),
                anyString(),
                eq("WARNING")
        );
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_06: cancelDistribution khi ID null hoặc rỗng -> Ném BadRequestException (Dòng 198)")
    void testCancelDistribution_WhenIdIsBlank_ShouldThrowBadRequest() {
        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            distributionService.cancelDistribution("   ", "Lý do", "user-01");
        });
        assertTrue(ex.getMessage().contains("Mã đợt phân phối (id) không được để trống"));
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_07: cancelDistribution khi thẻ kho đích chưa từng có (inventory null) -> Tạo mới Inventory hoàn kho (Dòng 227-233)")
    void testCancelDistribution_WhenInventoryNotExists_ShouldCreateNewInventory() {
        String distId = "DIST-01";
        String warehouseId = "WH-01";
        String itemId = "ITEM-NEW";

        Distribution dist = new Distribution();
        dist.setId(distId);
        dist.setWarehouseId(warehouseId);
        dist.setStatus("IN_TRANSIT");

        DistributionDetail detail = new DistributionDetail();
        detail.setDistributionId(distId);
        detail.setItemId(itemId);
        detail.setQuantity(15);

        when(distributionRepository.findById(distId)).thenReturn(Optional.of(dist));
        when(detailRepository.findAllByDistributionId(distId)).thenReturn(List.of(detail));
        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId)).thenReturn(Optional.empty());
        when(distributionRepository.save(any(Distribution.class))).thenAnswer(i -> i.getArgument(0));

        Distribution cancelled = distributionService.cancelDistribution(distId, null, "admin-01");

        assertNotNull(cancelled);
        assertEquals("CANCELLED", cancelled.getStatus());
        assertEquals("Hủy theo yêu cầu điều phối", cancelled.getCancelReason()); // Kiểm tra lý do mặc định

        verify(inventoryRepository, times(1)).save(argThat(inv ->
                warehouseId.equals(inv.getWarehouseId()) &&
                itemId.equals(inv.getItemId()) &&
                Integer.valueOf(15).equals(inv.getQuantity()) &&
                Integer.valueOf(100).equals(inv.getMinThreshold())
        ));
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_08: cancelDistribution gắn với nhiệm vụ cứu nạn (requestId) -> Reset trạng thái itemsExported = false (Dòng 238-243)")
    void testCancelDistribution_WithAssignmentRequestId_ShouldResetItemsExported() {
        String distId = "DIST-02";
        String warehouseId = "WH-01";
        String requestId = "ASSIGN-TASK-99";

        Distribution dist = new Distribution();
        dist.setId(distId);
        dist.setWarehouseId(warehouseId);
        dist.setStatus("IN_TRANSIT");
        dist.setRequestId(requestId);

        Assignment assignment = new Assignment();
        assignment.setId(requestId);
        assignment.setItemsExported(true);

        when(distributionRepository.findById(distId)).thenReturn(Optional.of(dist));
        when(detailRepository.findAllByDistributionId(distId)).thenReturn(Collections.emptyList());
        when(assignmentRepository.findById(requestId)).thenReturn(Optional.of(assignment));
        when(distributionRepository.save(any(Distribution.class))).thenAnswer(i -> i.getArgument(0));

        Distribution cancelled = distributionService.cancelDistribution(distId, "Hủy nhiệm vụ", "admin-01");

        assertNotNull(cancelled);
        assertFalse(assignment.isItemsExported(), "Nhiệm vụ điều phối phải được đặt lại itemsExported = false");
        verify(assignmentRepository, times(1)).save(assignment);
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_09: getHistory() -> Lấy danh sách lịch sử phân phối đầy đủ (Dòng 254-256)")
    void testGetHistory() {
        Distribution d1 = new Distribution();
        d1.setId("DIST-01");
        when(distributionRepository.findAll()).thenReturn(List.of(d1));

        List<Distribution> history = distributionService.getHistory();
        assertNotNull(history);
        assertEquals(1, history.size());
        verify(distributionRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_10: createDistribution gắn với nhiệm vụ (requestId) -> Đồng bộ itemsExported = true và gán MissionItems (Dòng 124-153)")
    void testCreateDistribution_WithAssignment_ShouldSetItemsExportedTrue() {
        String warehouseId = "WH-01";
        String itemId = "ITEM-01";
        String requestId = "REQ-ASSIGN-01";

        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        Inventory inv = new Inventory();
        inv.setItemId(itemId);
        inv.setItemName("Mì tôm Hảo Hảo");
        inv.setUnit("Thùng");
        inv.setQuantity(200);
        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId)).thenReturn(Optional.of(inv));

        DistributionRequest req = new DistributionRequest();
        req.setWarehouseId(warehouseId);
        req.setRequestId(requestId);
        DistributionRequest.ItemQuantity itemReq = new DistributionRequest.ItemQuantity();
        itemReq.setItemId(itemId);
        itemReq.setQuantity(50);
        req.setItems(List.of(itemReq));

        Assignment assignment = new Assignment();
        assignment.setId(requestId);
        assignment.setItemsExported(false);

        when(assignmentRepository.findById(requestId)).thenReturn(Optional.of(assignment));
        when(distributionRepository.save(any(Distribution.class))).thenAnswer(i -> i.getArgument(0));

        Distribution res = distributionService.createDistribution(req, "user-01");

        assertNotNull(res);
        assertTrue(assignment.isItemsExported(), "Nhiệm vụ phải được đánh dấu itemsExported = true");
        assertNotNull(assignment.getMissionItems());
        assertEquals(1, assignment.getMissionItems().size());
        assertEquals(Integer.valueOf(50), assignment.getMissionItems().get(0).getQuantity());
        verify(assignmentRepository, times(1)).save(assignment);
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_11: completeTransfer xác nhận chuyển kho thành công (Dòng 161-186)")
    void testCompleteTransfer_Success() {
        String distId = "DIST-TRANSFER-01";
        String destWarehouseId = "WH-DEST-02";
        String itemId = "ITEM-01";

        Distribution dist = new Distribution();
        dist.setId(distId);
        dist.setType("TRANSFER");
        dist.setStatus("IN_TRANSIT");
        dist.setDestinationWarehouseId(destWarehouseId);

        DistributionDetail detail = new DistributionDetail();
        detail.setDistributionId(distId);
        detail.setItemId(itemId);
        detail.setQuantity(25);

        Inventory destInventory = new Inventory();
        destInventory.setId("INV-DEST-01");
        destInventory.setWarehouseId(destWarehouseId);
        destInventory.setItemId(itemId);
        destInventory.setQuantity(10);

        when(distributionRepository.findById(distId)).thenReturn(Optional.of(dist));
        when(detailRepository.findAllByDistributionId(distId)).thenReturn(List.of(detail));
        when(inventoryRepository.findByWarehouseIdAndItemId(destWarehouseId, itemId)).thenReturn(Optional.of(destInventory));
        when(distributionRepository.save(any(Distribution.class))).thenAnswer(i -> i.getArgument(0));

        Distribution completed = distributionService.completeTransfer(distId);

        assertNotNull(completed);
        assertEquals("COMPLETED", completed.getStatus());
        assertEquals(35, destInventory.getQuantity());
        verify(inventoryRepository, times(1)).save(destInventory);
        verify(distributionRepository, times(1)).save(dist);
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_12: completeTransfer khi sai trạng thái -> Ném BadRequestException (Dòng 164-165)")
    void testCompleteTransfer_WhenStatusInvalid_ShouldThrowBadRequest() {
        String distId = "DIST-EXPORT-01";
        Distribution dist = new Distribution();
        dist.setId(distId);
        dist.setType("EXPORT"); // Không phải TRANSFER
        dist.setStatus("COMPLETED");

        when(distributionRepository.findById(distId)).thenReturn(Optional.of(dist));

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            distributionService.completeTransfer(distId);
        });

        assertTrue(ex.getMessage().contains("Trạng thái điều chuyển không hợp lệ"));
    }

    @Test
    @DisplayName("WB_DISTRIBUTION_13: completeTransfer khi không tìm thấy phiếu -> Ném ResourceNotFoundException (Dòng 161)")
    void testCompleteTransfer_WhenNotFound_ShouldThrowResourceNotFound() {
        String distId = "DIST-NOT-FOUND";
        when(distributionRepository.findById(distId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> {
            distributionService.completeTransfer(distId);
        });
    }
}
