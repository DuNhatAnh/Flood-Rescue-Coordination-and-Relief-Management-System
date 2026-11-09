package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import vn.rescue.core.application.dto.CancelRescueRequestDto;
import vn.rescue.core.application.services.RescueRequestService;
import vn.rescue.core.application.services.SystemManagementService;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.SafetyReportRepository;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.presentation.exceptions.BadRequestException;

import java.lang.reflect.Proxy;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("Kiểm thử API Lọc cứu nạn & Hủy yêu cầu cứu nạn (GET /api/v1/rescue-requests & PUT /api/v1/rescue-requests/{id}/cancel)")
class RescueRequestFilterAndCancelTest {

    private RescueRequestRepository rescueRequestRepository;
    private RequestStatusHistoryRepository statusHistoryRepository;
    private SafetyReportRepository safetyReportRepository;
    private SystemManagementService systemManagementService;

    private RescueRequestService rescueRequestService;
    private RescueRequestController rescueRequestController;

    private RescueRequest reqPending;
    private RescueRequest reqInProgress;
    private RescueRequest reqCompleted;

    private final Map<String, RescueRequest> dbStore = new HashMap<>();
    private final List<RequestStatusHistory> historyStore = new ArrayList<>();
    private final List<String> loggedActions = new ArrayList<>();

    @BeforeEach
    void setUp() {
        dbStore.clear();
        historyStore.clear();
        loggedActions.clear();

        reqPending = new RescueRequest();
        reqPending.setId("req-01");
        reqPending.setCustomId("RES-0001");
        reqPending.setCitizenName("Nguyễn Văn A");
        reqPending.setStatus("PENDING");
        reqPending.setAddressText("123 Lê Duẩn, Quận Hải Châu, Đà Nẵng");

        reqInProgress = new RescueRequest();
        reqInProgress.setId("req-02");
        reqInProgress.setCustomId("RES-0002");
        reqInProgress.setCitizenName("Trần Thị B");
        reqInProgress.setStatus("IN_PROGRESS");
        reqInProgress.setAddressText("456 Nguyễn Văn Linh, Quận Thanh Khê, Đà Nẵng");

        reqCompleted = new RescueRequest();
        reqCompleted.setId("req-03");
        reqCompleted.setCustomId("RES-0003");
        reqCompleted.setCitizenName("Lê Văn C");
        reqCompleted.setStatus("COMPLETED");
        reqCompleted.setAddressText("789 Trần Hưng Đạo, Quận Sơn Trà, Đà Nẵng");

        dbStore.put(reqPending.getId(), reqPending);
        dbStore.put(reqInProgress.getId(), reqInProgress);
        dbStore.put(reqCompleted.getId(), reqCompleted);

        // Proxy cho RescueRequestRepository
        rescueRequestRepository = (RescueRequestRepository) Proxy.newProxyInstance(
                RescueRequestRepository.class.getClassLoader(),
                new Class<?>[]{RescueRequestRepository.class},
                (proxy, method, args) -> {
                    String name = method.getName();
                    if ("findAll".equals(name)) {
                        return new ArrayList<>(dbStore.values());
                    }
                    if ("findById".equals(name)) {
                        String id = (String) args[0];
                        return Optional.ofNullable(dbStore.get(id));
                    }
                    if ("findFirstByCustomId".equals(name)) {
                        String cid = (String) args[0];
                        return dbStore.values().stream()
                                .filter(r -> cid.equals(r.getCustomId()))
                                .findFirst();
                    }
                    if ("save".equals(name)) {
                        RescueRequest req = (RescueRequest) args[0];
                        dbStore.put(req.getId(), req);
                        return req;
                    }
                    if ("countByStatus".equals(name)) {
                        String st = (String) args[0];
                        return dbStore.values().stream().filter(r -> st.equalsIgnoreCase(r.getStatus())).count();
                    }
                    return null;
                }
        );

        // Proxy cho RequestStatusHistoryRepository
        statusHistoryRepository = (RequestStatusHistoryRepository) Proxy.newProxyInstance(
                RequestStatusHistoryRepository.class.getClassLoader(),
                new Class<?>[]{RequestStatusHistoryRepository.class},
                (proxy, method, args) -> {
                    if ("save".equals(method.getName())) {
                        RequestStatusHistory h = (RequestStatusHistory) args[0];
                        historyStore.add(h);
                        return h;
                    }
                    return null;
                }
        );

        // Proxy cho SafetyReportRepository
        safetyReportRepository = (SafetyReportRepository) Proxy.newProxyInstance(
                SafetyReportRepository.class.getClassLoader(),
                new Class<?>[]{SafetyReportRepository.class},
                (proxy, method, args) -> {
                    if ("count".equals(method.getName())) return 0L;
                    return null;
                }
        );

        // Stub cho SystemManagementService
        systemManagementService = new SystemManagementService(null, null, null, null, null, null) {
            @Override
            public void logAction(String userId, String action, String details, String module) {
                loggedActions.add(userId + ":" + action);
            }
        };

        rescueRequestService = new RescueRequestService(
                rescueRequestRepository,
                statusHistoryRepository,
                safetyReportRepository,
                systemManagementService
        );

        rescueRequestController = new RescueRequestController(rescueRequestService);
    }

    // =========================================================================
    // 1. KIỂM THỬ API LỌC CỨU NẠN (GET /api/v1/rescue-requests)
    // =========================================================================

    @Test
    @DisplayName("GET /api/v1/rescue-requests: Lọc theo trạng thái PENDING thành công (Tag V1)")
    void testFilterRequests_ByStatusPending() {
        ResponseEntity<ApiResponse<List<RescueRequest>>> response = rescueRequestController.getAllRequests("PENDING", null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        List<RescueRequest> data = response.getBody().getData();
        assertThat(data).hasSize(1);
        assertThat(data.get(0).getStatus()).isEqualTo("PENDING");
        assertThat(data.get(0).getId()).isEqualTo("req-01");
    }

    @Test
    @DisplayName("GET /api/v1/rescue-requests: Lọc theo trạng thái IN_PROGRESS thành công (Tag V1)")
    void testFilterRequests_ByStatusInProgress() {
        ResponseEntity<ApiResponse<List<RescueRequest>>> response = rescueRequestController.getAllRequests("IN_PROGRESS", null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        List<RescueRequest> data = response.getBody().getData();
        assertThat(data).hasSize(1);
        assertThat(data.get(0).getStatus()).isEqualTo("IN_PROGRESS");
        assertThat(data.get(0).getId()).isEqualTo("req-02");
    }

    @Test
    @DisplayName("GET /api/v1/rescue-requests: Lọc theo quận/huyện (Hải Châu) thành công (Tag V2)")
    void testFilterRequests_ByDistrict() {
        ResponseEntity<ApiResponse<List<RescueRequest>>> response = rescueRequestController.getAllRequests(null, "Hải Châu");

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        List<RescueRequest> data = response.getBody().getData();
        assertThat(data).hasSize(1);
        assertThat(data.get(0).getAddressText()).contains("Hải Châu");
        assertThat(data.get(0).getId()).isEqualTo("req-01");
    }

    @Test
    @DisplayName("GET /api/v1/rescue-requests: Lọc kết hợp trạng thái và quận/huyện")
    void testFilterRequests_ByStatusAndDistrict() {
        ResponseEntity<ApiResponse<List<RescueRequest>>> response = rescueRequestController.getAllRequests("PENDING", "Hải Châu");

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        List<RescueRequest> data = response.getBody().getData();
        assertThat(data).hasSize(1);
        assertThat(data.get(0).getStatus()).isEqualTo("PENDING");
        assertThat(data.get(0).getAddressText()).contains("Hải Châu");
    }

    @Test
    @DisplayName("GET /api/v1/rescue-requests: Test lọc với tham số trạng thái không hợp lệ -> Ném BadRequestException (Tag X1)")
    void testFilterRequests_WithInvalidStatus_ShouldThrowBadRequestException() {
        assertThatThrownBy(() -> rescueRequestController.getAllRequests("INVALID_STATUS", null))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Trạng thái không hợp lệ: INVALID_STATUS");
    }

    // =========================================================================
    // 2. KIỂM THỬ API HỦY YÊU CẦU CỨU NẠN (PUT /api/v1/rescue-requests/{id}/cancel)
    // =========================================================================

    @Test
    @DisplayName("PUT /api/v1/rescue-requests/{id}/cancel: Người dân tự hủy khi nước đã rút -> Thành công (Tag V3, V4)")
    void testCancelRequest_WhenCitizenCancelsDueToRecededWater_ShouldSucceed() {
        CancelRescueRequestDto cancelDto = new CancelRescueRequestDto("Nước đã rút, gia đình đã an toàn");
        ResponseEntity<ApiResponse<RescueRequest>> response = rescueRequestController.cancelRequest("req-01", cancelDto);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        RescueRequest cancelled = response.getBody().getData();
        assertThat(cancelled.getStatus()).isEqualTo("CANCELLED");
        assertThat(cancelled.getNote()).isEqualTo("Nước đã rút, gia đình đã an toàn");

        assertThat(historyStore).hasSize(1);
        assertThat(historyStore.get(0).getStatus()).isEqualTo("CANCELLED");
        assertThat(loggedActions).contains("CITIZEN:HỦY YÊU CẦU CỨU HỘ");
    }

    @Test
    @DisplayName("PUT /api/v1/rescue-requests/{id}/cancel: Hủy thành công khi không truyền body lý do (Tag V3, V4)")
    void testCancelRequest_WithNullBody_ShouldUseDefaultReason() {
        ResponseEntity<ApiResponse<RescueRequest>> response = rescueRequestController.cancelRequest("req-01", null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        RescueRequest cancelled = response.getBody().getData();
        assertThat(cancelled.getStatus()).isEqualTo("CANCELLED");
        assertThat(cancelled.getNote()).contains("Người dân tự hủy");
    }

    @Test
    @DisplayName("PUT /api/v1/rescue-requests/{id}/cancel: Cố tình hủy khi đã ở trạng thái COMPLETED -> Phải chặn lỗi (Tag X3)")
    void testCancelRequest_WhenAlreadyCompleted_ShouldThrowBadRequestException() {
        CancelRescueRequestDto cancelDto = new CancelRescueRequestDto("Nước rút");

        assertThatThrownBy(() -> rescueRequestController.cancelRequest("req-03", cancelDto))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Không thể hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED!");
    }

    @Test
    @DisplayName("PUT /api/v1/rescue-requests/{id}/cancel: Cố tình hủy khi đã ở trạng thái CANCELLED -> Phải chặn lỗi (Tag X4)")
    void testCancelRequest_WhenAlreadyCancelled_ShouldThrowBadRequestException() {
        RescueRequest reqCancelled = new RescueRequest();
        reqCancelled.setId("req-04");
        reqCancelled.setStatus("CANCELLED");
        dbStore.put(reqCancelled.getId(), reqCancelled);

        CancelRescueRequestDto cancelDto = new CancelRescueRequestDto("Hủy lại lần 2");

        assertThatThrownBy(() -> rescueRequestController.cancelRequest("req-04", cancelDto))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Yêu cầu cứu hộ này đã ở trạng thái CANCELLED trước đó!");
    }
}
