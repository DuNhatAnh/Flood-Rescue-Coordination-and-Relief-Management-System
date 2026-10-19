package vn.rescue.core.presentation.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.domain.entities.SafetyReport;
import vn.rescue.core.domain.repositories.SafetyReportRepository;
import vn.rescue.core.application.services.RescueRequestService;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.presentation.common.DateValidationUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

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

    /**
     * Lấy danh sách báo cáo an toàn có hỗ trợ lọc theo ngày.
     * Chặn lọc khi ngày bắt đầu lớn hơn ngày kết thúc (trả về HTTP 400).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<SafetyReport>>> getAllReports(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {

        String startStr = (startDate != null && !startDate.isBlank()) ? startDate : fromDate;
        String endStr = (endDate != null && !endDate.isBlank()) ? endDate : toDate;

        LocalDateTime startDt = null;
        LocalDateTime endDt = null;

        if (startStr != null && !startStr.isBlank()) {
            startDt = DateValidationUtils.parseDateTime(startStr, false);
        }
        if (endStr != null && !endStr.isBlank()) {
            endDt = DateValidationUtils.parseDateTime(endStr, true);
        }

        // Chặn lọc khi ngày bắt đầu lớn hơn ngày kết thúc
        if (startDt != null && endDt != null && startDt.isAfter(endDt)) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, "Ngày bắt đầu không được lớn hơn ngày kết thúc"));
        }

        List<SafetyReport> reports = safetyReportRepository.findAll();

        if (startDt != null || endDt != null) {
            final LocalDateTime finalStart = startDt;
            final LocalDateTime finalEnd = endDt;
            reports = reports.stream()
                    .filter(r -> {
                        LocalDateTime reportedAt = r.getReportedAt();
                        if (reportedAt == null) return false;
                        if (finalStart != null && reportedAt.isBefore(finalStart)) return false;
                        if (finalEnd != null && reportedAt.isAfter(finalEnd)) return false;
                        return true;
                    })
                    .collect(Collectors.toList());
        }

        return ResponseEntity.ok(ApiResponse.success(reports, "Safety reports retrieved successfully"));
    }
}
