package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import vn.rescue.core.application.services.ReportService;
import vn.rescue.core.domain.entities.SafetyReport;
import vn.rescue.core.domain.repositories.SafetyReportRepository;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.presentation.common.DateValidationUtils;

import java.lang.reflect.Field;
import java.lang.reflect.Proxy;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ReportAndSafetyReportValidationTest {

    private SafetyReportController safetyReportController;
    private ReportController reportController;
    private List<SafetyReport> mockReports;

    static class StubReportService extends ReportService {
        public StubReportService() {
            super(null, null, null, null, null, null, null, null, null, null);
        }

        @Override
        public List<Map<String, Object>> getRescueHistory(LocalDateTime start, LocalDateTime end) {
            return List.of();
        }

        @Override
        public List<Map<String, Object>> getWarehouseHistory(String type, LocalDateTime start, LocalDateTime end) {
            return List.of();
        }

        @Override
        public List<Map<String, Object>> getVehicleUsageHistory(LocalDateTime start, LocalDateTime end) {
            return List.of();
        }

        @Override
        public Map<String, Object> getGeneralReportFiltered(LocalDateTime start, LocalDateTime end) {
            return Map.of("status", "ok");
        }
    }

    @BeforeEach
    void setUp() throws Exception {
        mockReports = new ArrayList<>();
        SafetyReportRepository safetyReportRepo = (SafetyReportRepository) Proxy.newProxyInstance(
                SafetyReportRepository.class.getClassLoader(),
                new Class<?>[]{SafetyReportRepository.class},
                (proxy, method, args) -> {
                    if ("findAll".equals(method.getName())) {
                        return mockReports;
                    }
                    if ("save".equals(method.getName())) {
                        SafetyReport report = (SafetyReport) args[0];
                        if (report.getId() == null) report.setId("mock-id-1");
                        return report;
                    }
                    return null;
                }
        );

        safetyReportController = new SafetyReportController();
        Field repoField = SafetyReportController.class.getDeclaredField("safetyReportRepository");
        repoField.setAccessible(true);
        repoField.set(safetyReportController, safetyReportRepo);

        reportController = new ReportController(new StubReportService());
    }

    @Test
    @DisplayName("DateValidationUtils: startDate > endDate phải ném IllegalArgumentException")
    void dateValidationUtils_startDateAfterEndDate_shouldThrowException() {
        assertThatThrownBy(() -> DateValidationUtils.validateAndParseRange("2026-10-20", "2026-10-10"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ngày bắt đầu không được lớn hơn ngày kết thúc");

        assertThatThrownBy(() -> DateValidationUtils.validateAndParseRange("2026-10-12T15:00:00", "2026-10-12T10:00:00"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ngày bắt đầu không được lớn hơn ngày kết thúc");
    }

    @Test
    @DisplayName("SafetyReport: Lọc khi startDate > endDate phải trả về HTTP 400 Bad Request")
    void safetyReport_startDateAfterEndDate_shouldReturnBadRequest() {
        ResponseEntity<ApiResponse<List<SafetyReport>>> response = safetyReportController.getAllReports(
                "2026-10-20",
                "2026-10-10",
                null,
                null
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isFalse();
        assertThat(response.getBody().getMessage()).contains("Ngày bắt đầu không được lớn hơn ngày kết thúc");
    }

    @Test
    @DisplayName("SafetyReport: Lọc hợp lệ startDate <= endDate phải trả về HTTP 200 OK và lọc đúng")
    void safetyReport_validDateRange_shouldReturnOkAndFilter() {
        SafetyReport r1 = new SafetyReport();
        r1.setId("1");
        r1.setReportedAt(LocalDateTime.of(2026, 10, 15, 10, 0));

        SafetyReport r2 = new SafetyReport();
        r2.setId("2");
        r2.setReportedAt(LocalDateTime.of(2026, 10, 25, 10, 0));

        mockReports.add(r1);
        mockReports.add(r2);

        ResponseEntity<ApiResponse<List<SafetyReport>>> response = safetyReportController.getAllReports(
                "2026-10-10",
                "2026-10-20",
                null,
                null
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getData()).hasSize(1);
        assertThat(response.getBody().getData().get(0).getId()).isEqualTo("1");
    }

    @Test
    @DisplayName("Report (General): Lọc khi startDate > endDate phải ném IllegalArgumentException dẫn tới 400")
    void report_generalReport_startDateAfterEndDate_shouldThrowException() {
        assertThatThrownBy(() -> reportController.getGeneralReport("2026-10-25", "2026-10-10", null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ngày bắt đầu không được lớn hơn ngày kết thúc");
    }

    @Test
    @DisplayName("Report (Rescue History): Lọc khi startDate > endDate phải trả về HTTP 400 Bad Request")
    void report_rescueHistory_startDateAfterEndDate_shouldReturnBadRequest() {
        ResponseEntity<ApiResponse<Object>> response = reportController.getRescueHistory(
                "2026-10-25",
                "2026-10-10",
                null,
                null
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("Ngày bắt đầu không được lớn hơn ngày kết thúc");
    }

    @Test
    @DisplayName("Report (Warehouse History): Lọc khi startDate > endDate phải trả về HTTP 400 Bad Request")
    void report_warehouseHistory_startDateAfterEndDate_shouldReturnBadRequest() {
        ResponseEntity<ApiResponse<Object>> response = reportController.getWarehouseHistory(
                "EXPORT",
                "2026-10-25",
                "2026-10-10",
                null,
                null
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("Ngày bắt đầu không được lớn hơn ngày kết thúc");
    }

    @Test
    @DisplayName("Report (Vehicle History): Lọc khi startDate > endDate phải trả về HTTP 400 Bad Request")
    void report_vehicleHistory_startDateAfterEndDate_shouldReturnBadRequest() {
        ResponseEntity<ApiResponse<Object>> response = reportController.getVehicleHistory(
                "2026-10-25",
                "2026-10-10",
                null,
                null
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("Ngày bắt đầu không được lớn hơn ngày kết thúc");
    }

    @Test
    @DisplayName("Report: Khi khoảng ngày hợp lệ thì các endpoint lịch sử trả về HTTP 200 OK")
    void report_validDateRange_shouldReturnOk() {
        ResponseEntity<ApiResponse<Object>> rescueRes = reportController.getRescueHistory(
                "2026-10-01",
                "2026-10-20",
                null,
                null
        );
        assertThat(rescueRes.getStatusCode()).isEqualTo(HttpStatus.OK);

        ResponseEntity<ApiResponse<Object>> whRes = reportController.getWarehouseHistory(
                "EXPORT",
                "2026-10-01",
                "2026-10-20",
                null,
                null
        );
        assertThat(whRes.getStatusCode()).isEqualTo(HttpStatus.OK);

        ResponseEntity<ApiResponse<Object>> vRes = reportController.getVehicleHistory(
                "2026-10-01",
                "2026-10-20",
                null,
                null
        );
        assertThat(vRes.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    @DisplayName("SafetyReport: Người dân báo an toàn thành công -> HTTP 200 OK")
    void safetyReport_citizenReportsSafety_shouldReturnOk() {
        SafetyReport report = new SafetyReport();
        report.setCitizenName("Nguyễn Văn Dân");
        report.setCitizenPhone("0905123456");
        report.setAddressText("123 Lê Duẩn, Hải Châu, Đà Nẵng");
        report.setNote("Nước đã rút, gia đình an toàn");

        ResponseEntity<ApiResponse<SafetyReport>> response = safetyReportController.createReport(report);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();
        assertThat(response.getBody().getData().getCitizenPhone()).isEqualTo("0905123456");
    }

    @Test
    @DisplayName("SafetyReport: Gửi thiếu số điện thoại -> Ném BadRequestException (HTTP 400 Bad Request)")
    void safetyReport_missingPhone_shouldThrowBadRequestException() {
        SafetyReport report = new SafetyReport();
        report.setCitizenName("Nguyễn Văn Dân");
        report.setAddressText("123 Lê Duẩn, Hải Châu, Đà Nẵng");
        report.setNote("Thiếu số điện thoại");

        assertThatThrownBy(() -> safetyReportController.createReport(report))
                .isInstanceOf(vn.rescue.core.presentation.exceptions.BadRequestException.class)
                .hasMessageContaining("Số điện thoại người báo không được để trống");
    }

    @Test
    @DisplayName("Report: Đội cứu hộ nộp báo cáo tổng kết (số người cứu được và số hàng đã phát) -> HTTP 200 OK")
    void report_submitRescueReport_shouldReturnOk() {
        vn.rescue.core.domain.entities.RescueReport rescueReport = new vn.rescue.core.domain.entities.RescueReport();
        rescueReport.setAssignmentId("assign-01");
        rescueReport.setRescuedPeopleCount(5);
        rescueReport.setActualDistributedItems(List.of(
                vn.rescue.core.domain.entities.MissionItem.builder()
                        .itemId("item-01")
                        .itemName("Mì tôm Hảo Hảo")
                        .unit("Thùng")
                        .quantity(3)
                        .build()
        ));

        ResponseEntity<ApiResponse<vn.rescue.core.domain.entities.RescueReport>> response =
                reportController.submitRescueReport(rescueReport);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();
        assertThat(response.getBody().getData().getRescuedPeopleCount()).isEqualTo(5);
        assertThat(response.getBody().getData().getActualDistributedItems()).hasSize(1);
    }
}
