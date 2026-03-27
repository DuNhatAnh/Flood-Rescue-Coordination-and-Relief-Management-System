package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.SystemManagementService;
import vn.rescue.core.application.services.ReportService;
import vn.rescue.core.domain.entities.SystemLog;
import vn.rescue.core.domain.entities.SystemConfig;
import vn.rescue.core.presentation.common.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/system")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminSystemController {
    private final SystemManagementService systemManagementService;
    private final ReportService reportService;

    @GetMapping("/logs")
    public ResponseEntity<ApiResponse<List<SystemLog>>> getLogs() {
        return ResponseEntity.ok(ApiResponse.success(systemManagementService.getAllLogs(), "System logs retrieved"));
    }

    @GetMapping("/reports")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReports() {
        return ResponseEntity.ok(ApiResponse.success(reportService.getGeneralStats(), "General statistics retrieved"));
    }

    @PutMapping("/config")
    public ResponseEntity<ApiResponse<SystemConfig>> updateConfig(
            @RequestParam String key, 
            @RequestParam String value) {
        SystemConfig config = systemManagementService.updateConfig(key, value);
        systemManagementService.logAction("ADMIN", "UPDATE_CONFIG", "Config " + key + " updated");
        return ResponseEntity.ok(ApiResponse.success(config, "System configuration updated"));
    }
}
