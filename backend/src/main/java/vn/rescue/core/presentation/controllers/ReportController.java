package vn.rescue.core.presentation.controllers;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.ReportService;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.presentation.common.DateValidationUtils;

import java.time.LocalDateTime;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/reports")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    /**
     * API Tổng hợp báo cáo có lọc theo ngày (startDate & endDate).
     * Chặn lọc khi ngày bắt đầu lớn hơn ngày kết thúc (trả về HTTP 400).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getGeneralReport(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {

        String startStr = (startDate != null && !startDate.isBlank()) ? startDate : fromDate;
        String endStr = (endDate != null && !endDate.isBlank()) ? endDate : toDate;

        LocalDateTime[] range = DateValidationUtils.validateAndParseRange(startStr, endStr);
        Map<String, Object> data = reportService.getGeneralReportFiltered(range[0], range[1]);
        return ResponseEntity.ok(ApiResponse.success(data, "Dữ liệu báo cáo đã được tải thành công"));
    }

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
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error(500, "Không thể tải dữ liệu Dashboard: " + e.getMessage()));
        }
    }

    /**
     * API Thống kê tổng quát cho Admin (Hỗ trợ kiểm tra khoảng ngày)
     */
    @GetMapping("/general-stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getGeneralStats(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {
        log.info("Tiếp nhận yêu cầu lấy thống kê tổng quát");
        try {
            String startStr = (startDate != null && !startDate.isBlank()) ? startDate : fromDate;
            String endStr = (endDate != null && !endDate.isBlank()) ? endDate : toDate;
            DateValidationUtils.validateAndParseRange(startStr, endStr);

            Map<String, Object> data = reportService.getGeneralStats();
            return ResponseEntity.ok(
                    ApiResponse.success(data, "Thống kê tổng quát đã được tải thành công")
            );
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, e.getMessage()));
        } catch (Exception e) {
            log.error("Lỗi khi tải thống kê tổng quát: ", e);
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error(500, "Lỗi hệ thống: " + e.getMessage()));
        }
    }

    /**
     * API Thống kê chi tiết cho Coordinator/Admin Dashboard (Hỗ trợ kiểm tra khoảng ngày)
     */
    @GetMapping("/analytics")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDetailedAnalytics(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {
        log.info("Tiếp nhận yêu cầu lấy thống kê chi tiết Analytics");
        try {
            String startStr = (startDate != null && !startDate.isBlank()) ? startDate : fromDate;
            String endStr = (endDate != null && !endDate.isBlank()) ? endDate : toDate;
            DateValidationUtils.validateAndParseRange(startStr, endStr);

            Map<String, Object> data = reportService.getDetailedAnalytics();
            return ResponseEntity.ok(
                    ApiResponse.success(data, "Thống kê chi tiết đã được tải thành công")
            );
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, e.getMessage()));
        } catch (Exception e) {
            log.error("Lỗi khi tải thống kê chi tiết: ", e);
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error(500, "Lỗi hệ thống: " + e.getMessage()));
        }
    }

    /**
     * API Lấy xu hướng kho (Biểu đồ đường)
     */
    @GetMapping("/warehouse-trend")
    public ResponseEntity<ApiResponse<Object>> getWarehouseTrend(
            @RequestParam(defaultValue = "week") String period,
            @RequestParam(required = false) String itemId) {
        try {
            return ResponseEntity.ok(ApiResponse.success(reportService.getWarehouseTrend(period, itemId), "Dữ liệu xu hướng kho đã được tải"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    /**
     * API Lấy danh sách vật phẩm có sẵn trong kho của đội
     */
    @GetMapping("/available-items")
    public ResponseEntity<ApiResponse<Object>> getAvailableItems() {
        try {
            return ResponseEntity.ok(ApiResponse.success(reportService.getAvailableItems(), "Danh sách vật phẩm đã được tải"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    /**
     * API Lấy thống kê chi tiết (Nhiệm vụ xong, Người cứu được)
     */
    @GetMapping("/extended-stats")
    public ResponseEntity<ApiResponse<Object>> getExtendedStats() {
        try {
            return ResponseEntity.ok(ApiResponse.success(reportService.getExtendedStats(), "Thống kê mở rộng đã được tải"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    /**
     * API Lấy lịch sử cứu hộ (Hỗ trợ lọc theo khoảng ngày, chặn khi ngày bắt đầu > ngày kết thúc)
     */
    @GetMapping("/rescue-history")
    public ResponseEntity<ApiResponse<Object>> getRescueHistory(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {
        try {
            String startStr = (startDate != null && !startDate.isBlank()) ? startDate : fromDate;
            String endStr = (endDate != null && !endDate.isBlank()) ? endDate : toDate;
            LocalDateTime[] range = DateValidationUtils.validateAndParseRange(startStr, endStr);

            return ResponseEntity.ok(ApiResponse.success(reportService.getRescueHistory(range[0], range[1]), "Lịch sử cứu hộ đã được tải"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    /**
     * API Lấy lịch sử kho (Hỗ trợ lọc theo khoảng ngày, chặn khi ngày bắt đầu > ngày kết thúc)
     */
    @GetMapping("/warehouse-history")
    public ResponseEntity<ApiResponse<Object>> getWarehouseHistory(
            @RequestParam(required = false, defaultValue = "EXPORT") String type,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {
        try {
            String startStr = (startDate != null && !startDate.isBlank()) ? startDate : fromDate;
            String endStr = (endDate != null && !endDate.isBlank()) ? endDate : toDate;
            LocalDateTime[] range = DateValidationUtils.validateAndParseRange(startStr, endStr);

            return ResponseEntity.ok(ApiResponse.success(reportService.getWarehouseHistory(type, range[0], range[1]), "Lịch sử kho đã được tải"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(ApiResponse.error(500, e.getMessage()));
        }
    }

    /**
     * API Lấy lịch sử sử dụng phương tiện (Hỗ trợ lọc theo khoảng ngày, chặn khi ngày bắt đầu > ngày kết thúc)
     */
    @GetMapping("/vehicle-history")
    public ResponseEntity<ApiResponse<Object>> getVehicleHistory(
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate) {
        try {
            String startStr = (startDate != null && !startDate.isBlank()) ? startDate : fromDate;
            String endStr = (endDate != null && !endDate.isBlank()) ? endDate : toDate;
            LocalDateTime[] range = DateValidationUtils.validateAndParseRange(startStr, endStr);

            return ResponseEntity.ok(ApiResponse.success(reportService.getVehicleUsageHistory(range[0], range[1]), "Lịch sử phương tiện đã được tải"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(ApiResponse.error(500, e.getMessage()));
        }
    }
}