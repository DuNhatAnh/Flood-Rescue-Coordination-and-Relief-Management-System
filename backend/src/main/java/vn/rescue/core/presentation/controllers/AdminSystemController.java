package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.DashboardStatsResponse;
import vn.rescue.core.application.services.SystemManagementService;
import vn.rescue.core.application.services.ReportService;
import vn.rescue.core.domain.entities.SystemLog;
import vn.rescue.core.domain.entities.SystemConfig;
import vn.rescue.core.presentation.common.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/system")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // Quan trọng để Flutter gọi không bị chặn CORS
public class AdminSystemController {
    private final SystemManagementService systemManagementService;
    private final ReportService reportService;

    // --- SCRUM-54: LẤY NHẬT KÝ ---
    @GetMapping("/logs")
    public ResponseEntity<ApiResponse<List<SystemLog>>> getLogs() {
        List<SystemLog> logs = systemManagementService.getAllLogs();
        return ResponseEntity.ok(ApiResponse.success(logs, "System logs retrieved successfully"));
    }

    // --- SCRUM-55: DASHBOARD THỐNG KÊ TỔNG HỢP ---
    // Endpoint này sẽ gọi Service để tính toán số xe, hàng hóa sắp hết theo kho
    @GetMapping("/dashboard/{warehouseId}")
    public ResponseEntity<ApiResponse<DashboardStatsResponse>> getDashboardStats(
            @PathVariable String warehouseId) {
        DashboardStatsResponse stats = systemManagementService.getDashboardStats(warehouseId);
        return ResponseEntity.ok(ApiResponse.success(stats, "Dashboard statistics retrieved"));
    }

    // --- CẤU HÌNH HỆ THỐNG ---
    @PutMapping("/config")
    public ResponseEntity<ApiResponse<SystemConfig>> updateConfig(
            @RequestParam String key,
            @RequestParam String value,
            @RequestParam String adminId) { // Thêm adminId để ghi log chính xác

        SystemConfig config = systemManagementService.updateConfig(key, value);

        // Ghi log hành động cập nhật cấu hình
        systemManagementService.logAction(adminId, "UPDATE_CONFIG",
                "Config " + key + " updated to " + value, "SYSTEM");

        return ResponseEntity.ok(ApiResponse.success(config, "System configuration updated"));
    }

    // --- THỐNG KÊ BÁO CÁO CHI TIẾT (REPORT SERVICE) ---
    @GetMapping("/reports/general")
    public ResponseEntity<ApiResponse<Object>> getGeneralReports() {
        return ResponseEntity.ok(ApiResponse.success(reportService.getGeneralStats(), "General reports retrieved"));
    }

    @GetMapping("/analytics")
    @PreAuthorize("hasAnyRole('ADMIN', 'COORDINATOR')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDetailedAnalytics() {
        return ResponseEntity.ok(ApiResponse.success(reportService.getDetailedAnalytics(), "Detailed analytics retrieved"));
    }
}