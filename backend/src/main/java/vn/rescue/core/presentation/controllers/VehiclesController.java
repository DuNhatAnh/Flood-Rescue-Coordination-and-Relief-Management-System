package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.VehicleRequest;
import vn.rescue.core.application.dto.VehicleResponse;
import vn.rescue.core.application.services.VehiclesService;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.application.services.RescueCoordinationService;
import vn.rescue.core.presentation.common.ApiResponse;
import java.util.List;

@RestController
@RequestMapping("/api/v1/vehicles")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class VehiclesController {

    private final VehiclesService vehiclesService;
    private final RescueCoordinationService rescueCoordinationService;

    // 1. Tạo mới: Thêm tham số userId để ghi log
    @PostMapping
    public ResponseEntity<ApiResponse<VehicleResponse>> create(
            @RequestBody VehicleRequest request,
            @RequestParam String userId) { // Thêm userId từ Request Param
        return new ResponseEntity<>(ApiResponse.success(vehiclesService.createVehicle(request, userId), "Tạo phương tiện thành công"), HttpStatus.CREATED);
    }

    // 2. Cập nhật: Thêm tham số userId để ghi log
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<VehicleResponse>> update(
            @PathVariable String id,
            @RequestBody VehicleRequest request,
            @RequestParam String userId) { // Thêm userId từ Request Param
        return ResponseEntity.ok(ApiResponse.success(vehiclesService.updateVehicle(id, request, userId), "Cập nhật phương tiện thành công"));
    }

    // 3. Xóa: Thêm tham số userId để ghi log
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable String id,
            @RequestParam String userId) { // Thêm userId từ Request Param
        vehiclesService.deleteVehicle(id, userId);
        return ResponseEntity.ok(ApiResponse.success(null, "Xóa phương tiện thành công"));
    }

    // 4. Lấy danh sách: Thêm tham số warehouseId để khớp 4 arguments
    @GetMapping
    public ResponseEntity<ApiResponse<Page<VehicleResponse>>> getAll(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String warehouseId, // Thêm trường này
            @PageableDefault(size = 10) Pageable pageable) {
        // Gọi service với đủ 4 tham số: type, status, warehouseId, pageable
        return ResponseEntity.ok(ApiResponse.success(vehiclesService.getAllVehicles(type, status, warehouseId, pageable), "Danh sách phương tiện"));
    }

    @GetMapping("/available")
    public ResponseEntity<ApiResponse<List<Vehicles>>> getAvailable() {
        return ResponseEntity.ok(ApiResponse.success(rescueCoordinationService.getAvailableVehicles(), "Danh sách phương tiện sẵn sàng"));
    }
}