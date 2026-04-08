package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.ReportService;
import vn.rescue.core.presentation.common.ApiResponse;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ReportController {

    private final ReportService reportService;

    /**
     * API TỔNG LỰC CHO DASHBOARD
     * Trả về tất cả dữ liệu cần thiết cho Staff
     */
    @GetMapping("/staff-dashboard")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStaffDashboard() {
        log.info("Tiếp nhận yêu cầu lấy dữ liệu Dashboard cho Staff");
        try {
            Map<String, Object> data = reportService.getStaffDashboardStats();
            log.info("Trả về dữ liệu Dashboard thành công");

            return ResponseEntity.ok(
                    ApiResponse.success(data, "Dữ liệu Dashboard đã được tải thành công")
            );
        } catch (Exception e) {
            log.error("Lỗi khi tải dữ liệu Dashboard: ", e);
            // SỬA LỖI: Thay null bằng mã số 500
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error(500, "Không thể tải dữ liệu Dashboard: " + e.getMessage()));
        }
    }

    /**
     * API Thống kê tổng quát cho Admin
     */
    @GetMapping("/general-stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getGeneralStats() {
        log.info("Tiếp nhận yêu cầu lấy thống kê tổng quát");
        try {
            Map<String, Object> data = reportService.getGeneralStats();

            return ResponseEntity.ok(
                    ApiResponse.success(data, "Thống kê tổng quát đã được tải thành công")
            );
        } catch (Exception e) {
            log.error("Lỗi khi tải thống kê tổng quát: ", e);
            // SỬA LỖI: Thay null bằng mã số 500
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error(500, "Lỗi hệ thống: " + e.getMessage()));
        }
    }

    /**
     * API Thống kê chi tiết cho Coordinator/Admin Dashboard
     */
    @GetMapping("/analytics")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDetailedAnalytics() {
        log.info("Tiếp nhận yêu cầu lấy thống kê chi tiết Analytics");
        try {
            Map<String, Object> data = reportService.getDetailedAnalytics();
            return ResponseEntity.ok(
                    ApiResponse.success(data, "Thống kê chi tiết đã được tải thành công")
            );
        } catch (Exception e) {
            log.error("Lỗi khi tải thống kê chi tiết: ", e);
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error(500, "Lỗi hệ thống: " + e.getMessage()));
        }
    }
}