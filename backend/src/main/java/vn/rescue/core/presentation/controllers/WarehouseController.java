package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.WarehouseRequest;
import vn.rescue.core.application.services.WarehouseService;
import vn.rescue.core.domain.entities.Warehouse;
import vn.rescue.core.presentation.common.ApiResponse;
import org.springframework.http.ResponseEntity;

import java.util.List;

@RestController
@RequestMapping("/api/v1/warehouses")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class WarehouseController {
    private final WarehouseService warehouseService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Warehouse>>> getAllWarehouses() {
        return ResponseEntity.ok(ApiResponse.success(warehouseService.getAllWarehouses(), "Danh sách kho bãi"));
    }

    @GetMapping("/manager/{managerId}")
    public ResponseEntity<ApiResponse<Warehouse>> getWarehouseByManagerId(@PathVariable("managerId") String managerId) {
        return ResponseEntity.ok(ApiResponse.success(warehouseService.getWarehouseByManagerId(managerId), "Tìm thấy kho bãi"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Warehouse>> getWarehouseById(@PathVariable("id") String id) {
        return ResponseEntity.ok(ApiResponse.success(warehouseService.getWarehouseById(id), "Tìm thấy kho bãi"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Warehouse>> createWarehouse(@RequestBody WarehouseRequest request) {
        return ResponseEntity.ok(ApiResponse.success(warehouseService.createWarehouse(request), "Tạo kho bãi thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Warehouse>> updateWarehouse(@PathVariable("id") String id, @RequestBody WarehouseRequest request) {
        return ResponseEntity.ok(ApiResponse.success(warehouseService.updateWarehouse(id, request), "Cập nhật kho bãi thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteWarehouse(@PathVariable("id") String id) {
        warehouseService.deleteWarehouse(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Xóa kho bãi thành công"));
    }
}
