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
@CrossOrigin(origins = "*") // Cho phép Frontend gọi API dễ dàng hơn
public class VehiclesController {

    private final VehiclesService vehiclesService;
    private final RescueCoordinationService rescueCoordinationService;

    // 1. Tạo mới phương tiện
    @PostMapping
    public ResponseEntity<VehicleResponse> create(@RequestBody VehicleRequest request) {
        return new ResponseEntity<>(vehiclesService.createVehicle(request), HttpStatus.CREATED);
    }

    // 2. Cập nhật thông tin (Dùng PUT)
    @PutMapping("/{id}")
    public ResponseEntity<VehicleResponse> update(
            @PathVariable String id,
            @RequestBody VehicleRequest request) {
        return ResponseEntity.ok(vehiclesService.updateVehicle(id, request));
    }

    // 3. Xóa phương tiện
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        vehiclesService.deleteVehicle(id);
        return ResponseEntity.noContent().build();
    }

    // 4. Lấy danh sách (Có lọc & Phân trang mặc định)
    @GetMapping
    public ResponseEntity<Page<VehicleResponse>> getAll(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status,
            @PageableDefault(size = 10) Pageable pageable) { // Mặc định 10 phần tử/trang nếu không truyền
        return ResponseEntity.ok(vehiclesService.getAllVehicles(type, status, pageable));
    }

    @GetMapping("/available")
    public ResponseEntity<List<Vehicles>> getAvailable() {
        return ResponseEntity.ok(rescueCoordinationService.getAvailableVehicles());
    }
}