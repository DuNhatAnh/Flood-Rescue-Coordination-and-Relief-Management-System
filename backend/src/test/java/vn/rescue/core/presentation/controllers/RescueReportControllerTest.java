package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import vn.rescue.core.domain.entities.RescueReport;
import vn.rescue.core.domain.repositories.RescueReportRepository;
import vn.rescue.core.presentation.common.ApiResponse;

import java.lang.reflect.Proxy;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Kiểm thử Controller nộp biên bản kết thúc cứu hộ: RescueReportController")
class RescueReportControllerTest {

    private RescueReportRepository rescueReportRepository;
    private RescueReportController rescueReportController;
    private AtomicInteger saveCallCount;

    @BeforeEach
    void setUp() {
        saveCallCount = new AtomicInteger(0);
        rescueReportRepository = (RescueReportRepository) Proxy.newProxyInstance(
                RescueReportRepository.class.getClassLoader(),
                new Class<?>[]{RescueReportRepository.class},
                (proxy, method, args) -> {
                    if ("save".equals(method.getName())) {
                        saveCallCount.incrementAndGet();
                        RescueReport report = (RescueReport) args[0];
                        if (report.getId() == null) {
                            report.setId("MOCK-REPORT-" + System.currentTimeMillis());
                        }
                        return report;
                    }
                    return null;
                }
        );
        rescueReportController = new RescueReportController(rescueReportRepository);
    }

    @Test
    @DisplayName("WB_REPORT_01: Nộp biên bản cứu nạn với rescuedPeopleCount = 0 (ca chỉ tiếp tế nhu yếu phẩm) -> Trả về 200 OK")
    void testSubmitReport_RescuedPeopleCountZero_ShouldReturn200Ok() {
        RescueReport report = new RescueReport();
        report.setAssignmentId("ASSIGN-001");
        report.setRescuedPeopleCount(0);
        report.setActualCondition("Tiếp tế nhu yếu phẩm thành công, không có người cần sơ tán");
        report.setDetailedNote("Đã cấp phát mì tôm và nước sạch");

        ResponseEntity<ApiResponse<RescueReport>> response = rescueReportController.submitReport(report);

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("Rescue report submitted successfully", response.getBody().getMessage());
        assertNotNull(response.getBody().getData());
        assertEquals(0, response.getBody().getData().getRescuedPeopleCount());
        assertNotNull(response.getBody().getData().getId());
        assertNotNull(response.getBody().getData().getCreatedAt(), "Hệ thống phải tự động gán createdAt");
        assertEquals(1, saveCallCount.get(), "Hàm save của repository phải được gọi đúng 1 lần");
    }

    @Test
    @DisplayName("WB_REPORT_02: Nộp biên bản cứu nạn với rescuedPeopleCount = 50 (đạt tải trọng tối đa) -> Trả về 200 OK")
    void testSubmitReport_RescuedPeopleCountFifty_ShouldReturn200Ok() {
        RescueReport report = new RescueReport();
        report.setAssignmentId("ASSIGN-002");
        report.setRescuedPeopleCount(50);
        report.setActualCondition("Đã sơ tán toàn bộ cụm dân cư bị cô lập");
        report.setDetailedNote("Đưa 50 người dân về khu tập kết an toàn");

        ResponseEntity<ApiResponse<RescueReport>> response = rescueReportController.submitReport(report);

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("Rescue report submitted successfully", response.getBody().getMessage());
        assertNotNull(response.getBody().getData());
        assertEquals(50, response.getBody().getData().getRescuedPeopleCount());
        assertNotNull(response.getBody().getData().getId());
        assertNotNull(response.getBody().getData().getCreatedAt(), "Hệ thống phải tự động gán createdAt");
        assertEquals(1, saveCallCount.get(), "Hàm save của repository phải được gọi đúng 1 lần");
    }

    @Test
    @DisplayName("WB_REPORT_03: Nộp biên bản danh định đầy đủ ảnh hiện trường và danh sách hàng phân phối thực tế -> Trả về 200 OK")
    void testSubmitReport_NominalWithImagesAndDistributedItems_ShouldReturn200Ok() {
        RescueReport report = new RescueReport();
        report.setAssignmentId("ASSIGN-003");
        report.setRescuedPeopleCount(12);
        report.setActualCondition("Cứu hộ thành công hộ gia đình 12 người mắc kẹt tầng 2");
        report.setDetailedNote("Sức khỏe nạn nhân ổn định");
        report.setImageUrls(java.util.List.of("https://cdn.rescue.vn/evidence-01.jpg", "https://cdn.rescue.vn/evidence-02.jpg"));

        vn.rescue.core.domain.entities.MissionItem item = new vn.rescue.core.domain.entities.MissionItem();
        item.setItemId("ITEM-AO-PHAO");
        item.setItemName("Áo phao");
        item.setQuantity(12);
        report.setActualDistributedItems(java.util.List.of(item));

        ResponseEntity<ApiResponse<RescueReport>> response = rescueReportController.submitReport(report);

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertNotNull(response.getBody().getData());
        assertEquals(12, response.getBody().getData().getRescuedPeopleCount());
        assertEquals(2, response.getBody().getData().getImageUrls().size());
        assertEquals(1, response.getBody().getData().getActualDistributedItems().size());
        assertNotNull(response.getBody().getData().getCreatedAt());
        assertEquals(1, saveCallCount.get());
    }
}
