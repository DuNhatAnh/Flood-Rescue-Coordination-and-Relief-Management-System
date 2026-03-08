package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
// Sửa lại dòng import này cho đúng package của Service
import vn.rescue.core.application.services.VehiclesService;
import vn.rescue.core.application.dto.VehicleRequest;
import vn.rescue.core.application.dto.VehicleResponse;

@RestController
@RequestMapping("/api/vehicles")
@RequiredArgsConstructor
public class VehiclesController {
    // Nếu bạn đã import đúng và file Service có @Service, lỗi Autowire sẽ hết
    private final VehiclesService vehiclesService;

    @PostMapping
    public ResponseEntity<VehicleResponse> createVehicle(@RequestBody VehicleRequest request) {
        return ResponseEntity.ok(vehiclesService.createVehicle(request));
    }
}