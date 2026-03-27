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
    public ResponseEntity<VehicleResponse> create(
            @RequestBody VehicleRequest request,
            @RequestParam String userId) { // Thêm userId từ Request Param
        return new ResponseEntity<>(vehiclesService.createVehicle(request, userId), HttpStatus.CREATED);
    }

    // 2. Cập nhật: Thêm tham số userId để ghi log
    @PutMapping("/{id}")
    public ResponseEntity<VehicleResponse> update(
            @PathVariable String id,
            @RequestBody VehicleRequest request,
            @RequestParam String userId) { // Thêm userId từ Request Param
        return ResponseEntity.ok(vehiclesService.updateVehicle(id, request, userId));
    }

    // 3. Xóa: Thêm tham số userId để ghi log
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable String id,
            @RequestParam String userId) { // Thêm userId từ Request Param
        vehiclesService.deleteVehicle(id, userId);
        return ResponseEntity.noContent().build();
    }

    // 4. Lấy danh sách: Thêm tham số warehouseId để khớp 4 arguments
    @GetMapping
    public ResponseEntity<Page<VehicleResponse>> getAll(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String warehouseId, // Thêm trường này
            @PageableDefault(size = 10) Pageable pageable) {
        // Gọi service với đủ 4 tham số: type, status, warehouseId, pageable
        return ResponseEntity.ok(vehiclesService.getAllVehicles(type, status, warehouseId, pageable));
    }

    @GetMapping("/available")
    public ResponseEntity<List<Vehicles>> getAvailable() {
        return ResponseEntity.ok(rescueCoordinationService.getAvailableVehicles());
    }
}