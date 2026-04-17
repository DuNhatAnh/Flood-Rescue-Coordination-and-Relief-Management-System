package vn.rescue.core.presentation.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.domain.entities.SafetyReport;
import vn.rescue.core.domain.repositories.SafetyReportRepository;
import vn.rescue.core.application.services.RescueRequestService;
import vn.rescue.core.presentation.common.ApiResponse;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/safety-reports")
public class SafetyReportController {

    @Autowired
    private SafetyReportRepository safetyReportRepository;

    @Autowired
    private RescueRequestService rescueRequestService;

    @PostMapping
    public ResponseEntity<ApiResponse<SafetyReport>> createReport(@RequestBody SafetyReport report) {
        report.setReportedAt(LocalDateTime.now());
        SafetyReport saved = safetyReportRepository.save(report);
        
        // Tự động liên kết với yêu cầu cứu trợ (nếu có) thông qua SĐT
        try {
            rescueRequestService.linkSafetyReportByPhone(report.getCitizenPhone());
        } catch (Exception e) {
            // Log error but don't fail the safety report creation
            System.err.println("Error linking safety report to rescue request: " + e.getMessage());
        }
        
        return ResponseEntity.ok(ApiResponse.success(saved, "Safety report created successfully"));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<SafetyReport>>> getAllReports() {
        List<SafetyReport> reports = safetyReportRepository.findAll();
        return ResponseEntity.ok(ApiResponse.success(reports, "Safety reports retrieved successfully"));
    }
}
