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
    public ResponseEntity<ApiResponse<List<DangerPoint>>> getAllDangerPoints(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) Double radius) {
        List<DangerPoint> points = dangerPointService.getDangerPointsNearby(lat, lng, radius);
        return ResponseEntity.ok(ApiResponse.success(points, "Danh sách điểm nguy hiểm đã được tải"));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<DangerPoint>> createDangerPoint(@RequestBody DangerPoint dangerPoint) {
        return ResponseEntity.ok(ApiResponse.success(dangerPointService.createDangerPoint(dangerPoint), "Danger point created"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<DangerPoint>> updateDangerPoint(@PathVariable String id, @RequestBody DangerPoint dangerPoint) {
        return ResponseEntity.ok(ApiResponse.success(dangerPointService.updateDangerPoint(id, dangerPoint), "Danger point updated"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteDangerPoint(@PathVariable String id) {
        dangerPointService.deleteDangerPoint(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Danger point deleted"));
    }
}
