package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.DangerPointService;
import vn.rescue.core.domain.entities.DangerPoint;
import vn.rescue.core.presentation.common.ApiResponse;

import java.util.List;

@RestController
@RequestMapping("/api/v1/danger-points")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DangerPointController {
    private final DangerPointService dangerPointService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<DangerPoint>>> getAllDangerPoints() {
        return ResponseEntity.ok(ApiResponse.success(dangerPointService.getAllDangerPoints(), "Danger points retrieved"));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<DangerPoint>> createDangerPoint(@RequestBody DangerPoint dangerPoint) {
        return ResponseEntity.ok(ApiResponse.success(dangerPointService.createDangerPoint(dangerPoint), "Danger point created"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteDangerPoint(@PathVariable String id) {
        dangerPointService.deleteDangerPoint(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Danger point deleted"));
    }
}
