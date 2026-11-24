package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.InventoryResponse;
import vn.rescue.core.application.dto.StockInRequest;
import vn.rescue.core.application.dto.StockOutRequest;
import vn.rescue.core.domain.entities.Inventory;
import vn.rescue.core.domain.entities.ReliefItem;
import vn.rescue.core.domain.entities.StockTransaction;
import vn.rescue.core.domain.repositories.*;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-115 [Sprint 5]: Unit Test cho Quản lý Nhập kho & Thẻ kho (InventoryService)")
class InventoryServiceTest {

    @Mock
    private InventoryRepository inventoryRepository;

    @Mock
    private ReliefItemRepository reliefItemRepository;

    @Mock
    private StockTransactionRepository stockTransactionRepository;

    @Mock
    private WarehouseRepository warehouseRepository;

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private SystemManagementService systemService;

    @InjectMocks
    private InventoryService inventoryService;

    // =========================================================================
    // 1. KIỂM THỬ GIÁ TRỊ BIÊN BVA (QUANTITY) - POST /api/v1/inventory/import
    // =========================================================================

    @Test
    @DisplayName("TC_IMP_01: Nhập kho thất bại khi số lượng <= 0 (Biên dưới lỗi: 0) -> Ném 400 BadRequestException")
    void testImportStock_WhenQuantityZero_ShouldThrowBadRequestException() {
        StockInRequest request = StockInRequest.builder()
                .warehouseId("WH-01")
                .itemId("ITEM-01")
                .quantity(0)
                .build();

        when(warehouseRepository.existsById("WH-01")).thenReturn(true);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            inventoryService.importStock(request, "admin-01");
        });

        assertTrue(exception.getMessage().contains("Số lượng nhập kho phải lớn hơn 0"));
        verify(inventoryRepository, never()).save(any());
        verify(stockTransactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_IMP_02: Nhập kho thất bại khi số lượng âm (Biên âm: -10) -> Ném 400 BadRequestException")
    void testImportStock_WhenQuantityNegative_ShouldThrowBadRequestException() {
        StockInRequest request = StockInRequest.builder()
                .warehouseId("WH-01")
                .itemId("ITEM-01")
                .quantity(-10)
                .build();

        when(warehouseRepository.existsById("WH-01")).thenReturn(true);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            inventoryService.importStock(request, "admin-01");
        });

        assertTrue(exception.getMessage().contains("Số lượng nhập kho phải lớn hơn 0"));
        verify(inventoryRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_IMP_03: Nhập kho thành công tại Biên Min hợp lệ (Quantity = 1) -> Tồn kho cộng dồn chuẩn")
    void testImportStock_WhenQuantityValidMinBoundary_ShouldSuccess() {
        String warehouseId = "WH-01";
        String itemId = "ITEM-01";

        StockInRequest request = StockInRequest.builder()
                .warehouseId(warehouseId)
                .itemId(itemId)
                .quantity(1)
                .source("MẶT TRẬN TỔ QUỐC")
                .referenceNumber("PNK-001")
                .expiryDate(LocalDateTime.now().plusMonths(6))
                .condition("GOOD")
                .build();

        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        ReliefItem mockItem = new ReliefItem();
        mockItem.setId(itemId);
        mockItem.setItemName("Mì tôm Hảo Hảo");
        mockItem.setUnit("Thùng");
        when(reliefItemRepository.findById(itemId)).thenReturn(Optional.of(mockItem));

        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId))
                .thenReturn(Optional.empty());

        when(inventoryRepository.save(any(Inventory.class))).thenAnswer(invocation -> {
            Inventory inv = invocation.getArgument(0);
            inv.setId("INV-001");
            return inv;
        });

        InventoryResponse response = inventoryService.importStock(request, "admin-01");

        assertNotNull(response);
        assertEquals(1, response.getQuantity());
        assertEquals("Mì tôm Hảo Hảo", response.getItemName());
        assertEquals("Thùng", response.getUnit());

        verify(inventoryRepository, times(1)).save(any(Inventory.class));
        verify(stockTransactionRepository, times(1)).save(any(StockTransaction.class));
        verify(systemService, times(1)).logAction(eq("admin-01"), eq("IMPORT_STOCK"), anyString(), eq("INVENTORY"));
    }

    @Test
    @DisplayName("TC_IMP_04: Nhập kho thành công tại Biên Max hợp lệ (Quantity = 10000) -> Cộng dồn với kho có sẵn")
    void testImportStock_WhenQuantityValidMaxBoundary_ShouldSuccess() {
        String warehouseId = "WH-01";
        String itemId = "ITEM-01";

        StockInRequest request = StockInRequest.builder()
                .warehouseId(warehouseId)
                .itemId(itemId)
                .quantity(10000)
                .source("BỘ Y TẾ VIỆN TRỢ")
                .referenceNumber("PNK-002")
                .expiryDate(LocalDateTime.now().plusYears(1))
                .condition("GOOD")
                .build();

        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        ReliefItem mockItem = new ReliefItem();
        mockItem.setId(itemId);
        mockItem.setItemName("Nước khoáng đóng chai 500ml");
        mockItem.setUnit("Chai");
        when(reliefItemRepository.findById(itemId)).thenReturn(Optional.of(mockItem));

        // Kho đã có sẵn 500 chai
        Inventory existingInv = new Inventory();
        existingInv.setId("INV-EXISTING");
        existingInv.setWarehouseId(warehouseId);
        existingInv.setItemId(itemId);
        existingInv.setQuantity(500);
        existingInv.setMinThreshold(100);

        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId))
                .thenReturn(Optional.of(existingInv));

        when(inventoryRepository.save(any(Inventory.class))).thenAnswer(invocation -> invocation.getArgument(0));

        InventoryResponse response = inventoryService.importStock(request, "admin-01");

        assertNotNull(response);
        assertEquals(10500, response.getQuantity()); // 500 + 10000 = 10500
        verify(inventoryRepository, times(1)).save(existingInv);
        verify(stockTransactionRepository, times(1)).save(any(StockTransaction.class));
    }

    @Test
    @DisplayName("TC_IMP_05: Nhập kho thất bại khi số lượng vượt trần (Biên Max+1: 10001) -> Ném 400 BadRequestException")
    void testImportStock_WhenQuantityExceedsMaxThreshold_ShouldThrowBadRequestException() {
        StockInRequest request = StockInRequest.builder()
                .warehouseId("WH-01")
                .itemId("ITEM-01")
                .quantity(10001)
                .build();

        when(warehouseRepository.existsById("WH-01")).thenReturn(true);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            inventoryService.importStock(request, "admin-01");
        });

        assertTrue(exception.getMessage().contains("Số lượng nhập vượt quá sức chứa tối đa một lô (10000)"));
        verify(inventoryRepository, never()).save(any());
    }

    // =========================================================================
    // 2. KIỂM THỬ RÀNG BUỘC THỜI GIAN & TÍNH TOÀN VẸN
    // =========================================================================

    @Test
    @DisplayName("TC_IMP_06: Nhập kho thất bại khi hàng đã hết hạn sử dụng (expiryDate trong quá khứ) -> Chặn ném 400")
    void testImportStock_WhenExpiryDateInPast_ShouldThrowBadRequestException() {
        StockInRequest request = StockInRequest.builder()
                .warehouseId("WH-01")
                .itemId("ITEM-01")
                .quantity(100)
                .expiryDate(LocalDateTime.now().minusDays(5)) // Hết hạn 5 ngày trước
                .build();

        when(warehouseRepository.existsById("WH-01")).thenReturn(true);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            inventoryService.importStock(request, "admin-01");
        });

        assertTrue(exception.getMessage().contains("Hàng hóa đã hết hạn sử dụng"));
        verify(inventoryRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_IMP_07: Nhập kho thất bại khi kho hàng không tồn tại -> Ném 404 ResourceNotFoundException")
    void testImportStock_WhenWarehouseNotFound_ShouldThrowResourceNotFoundException() {
        String nonExistWarehouse = "WH-UNKNOWN-999";
        StockInRequest request = StockInRequest.builder()
                .warehouseId(nonExistWarehouse)
                .itemId("ITEM-01")
                .quantity(50)
                .build();

        when(warehouseRepository.existsById(nonExistWarehouse)).thenReturn(false);

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            inventoryService.importStock(request, "admin-01");
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy kho hàng với ID: " + nonExistWarehouse));
        verify(inventoryRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_IMP_08: Nhập kho thất bại khi mã vật phẩm rỗng -> Ném 400 BadRequestException")
    void testImportStock_WhenItemIdIsEmpty_ShouldThrowBadRequestException() {
        StockInRequest request = StockInRequest.builder()
                .warehouseId("WH-01")
                .itemId("")
                .quantity(50)
                .build();

        when(warehouseRepository.existsById("WH-01")).thenReturn(true);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            inventoryService.importStock(request, "admin-01");
        });

        assertTrue(exception.getMessage().contains("Mã vật phẩm không được để trống"));
        verify(inventoryRepository, never()).save(any());
    }

    // =========================================================================
    // 3. TRA CỨU THẺ KHO & CẢNH BÁO TỒN KHO CẠN KIỆT (LOW STOCK)
    // =========================================================================

    @Test
    @DisplayName("TC_INQ_01: Tra cứu tồn kho thành công theo kho hàng (GET /warehouse/{id}) -> Trả về danh sách chuẩn")
    void testGetWarehouseInventory_WhenWarehouseExists_ShouldReturnList() {
        String warehouseId = "WH-01";
        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        Inventory inv1 = new Inventory();
        inv1.setId("INV-1");
        inv1.setWarehouseId(warehouseId);
        inv1.setItemId("ITEM-01");
        inv1.setQuantity(200);
        inv1.setMinThreshold(50);

        Inventory inv2 = new Inventory();
        inv2.setId("INV-2");
        inv2.setWarehouseId(warehouseId);
        inv2.setItemId("ITEM-02");
        inv2.setQuantity(30);
        inv2.setMinThreshold(50);

        when(inventoryRepository.findByWarehouseId(warehouseId)).thenReturn(List.of(inv1, inv2));

        ReliefItem item1 = new ReliefItem();
        item1.setId("ITEM-01");
        item1.setItemName("Mì tôm Hảo Hảo");
        item1.setUnit("Thùng");
        when(reliefItemRepository.findById("ITEM-01")).thenReturn(Optional.of(item1));

        ReliefItem item2 = new ReliefItem();
        item2.setId("ITEM-02");
        item2.setItemName("Thuốc khử trùng Aquatabs");
        item2.setUnit("Hộp");
        when(reliefItemRepository.findById("ITEM-02")).thenReturn(Optional.of(item2));

        List<InventoryResponse> results = inventoryService.getWarehouseInventory(warehouseId);

        assertNotNull(results);
        assertEquals(2, results.size());
        assertEquals("NORMAL", results.get(0).getStatus());
        assertEquals("LOW_STOCK", results.get(1).getStatus()); // 30 <= 50 -> LOW_STOCK
    }

    @Test
    @DisplayName("TC_INQ_02: Tra cứu tồn kho thất bại khi kho không tồn tại -> Ném 404 ResourceNotFoundException")
    void testGetWarehouseInventory_WhenWarehouseNotExists_ShouldThrowResourceNotFoundException() {
        String nonExistId = "WH-INVALID-001";
        when(warehouseRepository.existsById(nonExistId)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> {
            inventoryService.getWarehouseInventory(nonExistId);
        });
    }

    @Test
    @DisplayName("TC_INQ_03: Cảnh báo tồn kho cạn kiệt (GET /warehouse/{id}/low-stock) -> Lọc đúng các mặt hàng dưới ngưỡng")
    void testGetLowStockItems_WhenWarehouseExists_ShouldReturnLowStockItems() {
        String warehouseId = "WH-01";
        when(warehouseRepository.existsById(warehouseId)).thenReturn(true);

        Inventory lowStockInv = new Inventory();
        lowStockInv.setId("INV-LOW");
        lowStockInv.setWarehouseId(warehouseId);
        lowStockInv.setItemId("ITEM-THUOC");
        lowStockInv.setQuantity(15);
        lowStockInv.setMinThreshold(50);

        when(inventoryRepository.findLowStockItemsByWarehouse(warehouseId))
                .thenReturn(List.of(lowStockInv));

        ReliefItem mockItem = new ReliefItem();
        mockItem.setId("ITEM-THUOC");
        mockItem.setItemName("Băng gạc y tế");
        mockItem.setUnit("Cuộn");
        when(reliefItemRepository.findById("ITEM-THUOC")).thenReturn(Optional.of(mockItem));

        List<InventoryResponse> results = inventoryService.getLowStockItems(warehouseId);

        assertNotNull(results);
        assertEquals(1, results.size());
        assertEquals("LOW_STOCK", results.get(0).getStatus());
        assertEquals(15, results.get(0).getQuantity());
    }

    // =========================================================================
    // 4. KIỂM THỬ XUẤT KHO CƠ BẢN (EXPORT STOCK)
    // =========================================================================

    @Test
    @DisplayName("TC_EXP_01: Xuất kho thành công khi số lượng khả dụng đủ -> Trừ tồn kho và ghi log giao dịch")
    void testExportStock_WhenAvailableQuantitySufficient_ShouldDeductStock() {
        String warehouseId = "WH-01";
        String itemId = "ITEM-01";

        StockOutRequest request = StockOutRequest.builder()
                .warehouseId(warehouseId)
                .itemId(itemId)
                .quantity(40)
                .reason("CẤP PHÁT ĐỘI CỨU HỘ")
                .assignmentId("ASSIGN-001")
                .build();

        Inventory existingInv = new Inventory();
        existingInv.setId("INV-01");
        existingInv.setWarehouseId(warehouseId);
        existingInv.setItemId(itemId);
        existingInv.setItemName("Áo phao cứu sinh");
        existingInv.setUnit("Cái");
        existingInv.setQuantity(100);
        existingInv.setMinThreshold(20);

        when(inventoryRepository.findByWarehouseIdAndItemId(warehouseId, itemId))
                .thenReturn(Optional.of(existingInv));

        int actualExported = inventoryService.exportStock(request, "staff-01");

        assertEquals(40, actualExported);
        assertEquals(60, existingInv.getQuantity()); // 100 - 40 = 60
        verify(inventoryRepository, times(1)).save(existingInv);
        verify(stockTransactionRepository, times(1)).save(any(StockTransaction.class));
        verify(systemService, times(1)).logAction(eq("staff-01"), eq("EXPORT_STOCK"), anyString(), eq("INVENTORY"));
    }

    // =========================================================================
    // Ca bổ sung hộp trắng: 2 nhánh chặn đầu tiên của importStock (dòng 38, 41)
    // =========================================================================

    @Test
    @DisplayName("WB_IMP_01: Payload nhập kho null -> Ném 400 BadRequestException, không truy vấn kho")
    void testImportStock_WhenRequestNull_ShouldThrowBadRequestException() {
        BadRequestException exception = assertThrows(BadRequestException.class,
                () -> inventoryService.importStock(null, "admin-01"));

        assertEquals("Dữ liệu nhập kho không được để trống", exception.getMessage());
        verifyNoInteractions(warehouseRepository, inventoryRepository, stockTransactionRepository);
    }

    @Test
    @DisplayName("WB_IMP_02: Mã kho để trống (chỉ khoảng trắng) -> Ném 400 BadRequestException, không truy vấn kho")
    void testImportStock_WhenWarehouseIdBlank_ShouldThrowBadRequestException() {
        StockInRequest request = StockInRequest.builder()
                .warehouseId("  ")
                .itemId("ITEM-01")
                .quantity(10)
                .build();

        BadRequestException exception = assertThrows(BadRequestException.class,
                () -> inventoryService.importStock(request, "admin-01"));

        assertEquals("Mã kho không được để trống", exception.getMessage());
        verify(warehouseRepository, never()).existsById(any());
        verify(inventoryRepository, never()).save(any());
    }
}

