package vn.rescue.core.presentation.controllers;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.InventoryResponse;
import vn.rescue.core.application.dto.StockInRequest;
import vn.rescue.core.application.services.InventoryService;
import vn.rescue.core.presentation.common.ApiResponse; // Giả định bạn dùng ApiResponse chung

import java.util.List;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // Hỗ trợ Flutter gọi API
public class InventoryController {
    private final InventoryService inventoryService;

    // SỬA LỖI: Thêm @RequestParam userId để truyền vào Service ghi log
    @PostMapping("/import")
    public ResponseEntity<ApiResponse<InventoryResponse>> importStock(
            @Valid @RequestBody StockInRequest request,
            @RequestParam String userId) {
        // Truyền đủ 2 tham số (request, userId) như Service yêu cầu
        return ResponseEntity.ok(ApiResponse.success(inventoryService.importStock(request, userId), "Nhập kho thành công"));
    }

    @GetMapping("/warehouse/{warehouseId}")
    public ResponseEntity<ApiResponse<List<InventoryResponse>>> getWarehouseInventory(
            @PathVariable("warehouseId") String warehouseId) {
        return ResponseEntity.ok(ApiResponse.success(inventoryService.getWarehouseInventory(warehouseId), "Danh sách tồn kho"));
    }

    // Bổ sung: Lấy danh sách hàng sắp hết cho Dashboard (SCRUM-55)
    @GetMapping("/warehouse/{warehouseId}/low-stock")
    public ResponseEntity<ApiResponse<List<InventoryResponse>>> getLowStock(
            @PathVariable("warehouseId") String warehouseId) {
        return ResponseEntity.ok(ApiResponse.success(inventoryService.getLowStockItems(warehouseId), "Hàng hóa sắp hết"));
    }
}