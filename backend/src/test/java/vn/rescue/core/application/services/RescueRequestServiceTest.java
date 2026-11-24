package vn.rescue.core.application.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import vn.rescue.core.application.dto.RescueRequestDto;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.SafetyReportRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Unit test hộp trắng cho RescueRequestService.createRequest (Gửi đơn SOS).
 * P = 4 điểm quyết định: lat ngoài [8.18; 23.39] · lng ngoài [102.14; 109.46]
 * · ?: urgencyLevel mặc định NORMAL · ?: numberOfPeople mặc định 1
 * → V(G) = 5; C = 4 phép so sánh biên → N = 9 ca.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("Unit Test hộp trắng: Gửi đơn SOS (RescueRequestService.createRequest)")
class RescueRequestServiceTest {

    @Mock private RescueRequestRepository rescueRequestRepository;
    @Mock private RequestStatusHistoryRepository statusHistoryRepository;
    @Mock private SafetyReportRepository safetyReportRepository;
    @Mock private SystemManagementService systemManagementService;

    @InjectMocks private RescueRequestService rescueRequestService;

    @BeforeEach
    void setUp() {
        when(rescueRequestRepository.count()).thenReturn(4L);
        when(rescueRequestRepository.save(any(RescueRequest.class))).thenAnswer(inv -> {
            RescueRequest r = inv.getArgument(0);
            r.setId("REQ-ID-1");
            return r;
        });
    }

    private RescueRequestDto dto(Double lat, Double lng) {
        RescueRequestDto dto = new RescueRequestDto();
        dto.setCitizenName("Nguyễn Văn A");
        dto.setCitizenPhone("0987654321");
        dto.setAddressText("Hòa Vang, Đà Nẵng");
        dto.setDescription("Nước ngập tới mái nhà");
        dto.setLocationLat(lat);
        dto.setLocationLng(lng);
        dto.setUrgencyLevel("HIGH");
        dto.setNumberOfPeople(4);
        return dto;
    }

    private void assertCreated(RescueRequestDto dto) {
        RescueRequest saved = assertDoesNotThrow(() -> rescueRequestService.createRequest(dto));
        assertEquals("PENDING", saved.getStatus());
        assertEquals(dto.getLocationLat(), saved.getLocationLat());
        assertEquals(dto.getLocationLng(), saved.getLocationLng());
        verify(rescueRequestRepository, times(1)).save(any(RescueRequest.class));
    }

    // ===== V(G) = 5 đường đi độc lập =====

    @Test
    @DisplayName("WB_SOS_01: Tọa độ hợp lệ, đủ dữ liệu -> Tạo đơn PENDING, ghi lịch sử và bắn thông báo RESCUE")
    void createRequest_ValidData_ShouldSaveHistoryAndNotify() {
        RescueRequest saved = rescueRequestService.createRequest(dto(16.0544, 108.2022));

        assertEquals("0005", saved.getCustomId());
        assertEquals("PENDING", saved.getStatus());
        assertEquals("HIGH", saved.getUrgencyLevel());
        assertEquals(4, saved.getNumberOfPeople());
        assertNotNull(saved.getCreatedAt());

        ArgumentCaptor<RequestStatusHistory> history = ArgumentCaptor.forClass(RequestStatusHistory.class);
        verify(statusHistoryRepository).save(history.capture());
        assertEquals("REQ-ID-1", history.getValue().getRequestId());
        assertEquals("PENDING", history.getValue().getStatus());
        verify(systemManagementService).logAction(eq("CITIZEN"), eq("YÊU CẦU CỨU HỘ MỚI"), anyString(), eq("RESCUE"));
    }

    @Test
    @DisplayName("WB_SOS_02: Vĩ độ 8.17 (ngoài biên dưới lãnh thổ VN) -> Ném 400, không lưu DB")
    void createRequest_LatOutsideVietnam_ShouldThrowBadRequest() {
        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> rescueRequestService.createRequest(dto(8.17, 108.2022)));

        assertTrue(ex.getMessage().contains("vĩ độ"));
        verify(rescueRequestRepository, never()).save(any());
        verifyNoInteractions(systemManagementService);
    }

    @Test
    @DisplayName("WB_SOS_03: Kinh độ 109.47 (ngoài biên trên lãnh thổ VN) -> Ném 400, không lưu DB")
    void createRequest_LngOutsideVietnam_ShouldThrowBadRequest() {
        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> rescueRequestService.createRequest(dto(16.0544, 109.47)));

        assertTrue(ex.getMessage().contains("kinh độ"));
        verify(rescueRequestRepository, never()).save(any());
        verifyNoInteractions(systemManagementService);
    }

    @Test
    @DisplayName("WB_SOS_04: Không gửi urgencyLevel -> Mặc định NORMAL (nhánh ?: )")
    void createRequest_NoUrgency_ShouldDefaultToNormal() {
        RescueRequestDto dto = dto(16.0544, 108.2022);
        dto.setUrgencyLevel(null);

        assertEquals("NORMAL", rescueRequestService.createRequest(dto).getUrgencyLevel());
    }

    @Test
    @DisplayName("WB_SOS_05: Không gửi numberOfPeople -> Mặc định 1 người (nhánh ?: )")
    void createRequest_NoNumberOfPeople_ShouldDefaultToOne() {
        RescueRequestDto dto = dto(16.0544, 108.2022);
        dto.setNumberOfPeople(null);

        assertEquals(1, rescueRequestService.createRequest(dto).getNumberOfPeople());
    }

    // ===== C = 4 ca tại biên phía hợp lệ =====

    @Test
    @DisplayName("WB_SOS_06 (BVA): Vĩ độ = 8.18 (biên dưới) -> Hợp lệ")
    void createRequest_LatAtMin_ShouldPass() {
        assertCreated(dto(8.18, 108.2022));
    }

    @Test
    @DisplayName("WB_SOS_07 (BVA): Vĩ độ = 23.39 (biên trên) -> Hợp lệ")
    void createRequest_LatAtMax_ShouldPass() {
        assertCreated(dto(23.39, 108.2022));
    }

    @Test
    @DisplayName("WB_SOS_08 (BVA): Kinh độ = 102.14 (biên dưới) -> Hợp lệ")
    void createRequest_LngAtMin_ShouldPass() {
        assertCreated(dto(16.0544, 102.14));
    }

    @Test
    @DisplayName("WB_SOS_09 (BVA): Kinh độ = 109.46 (biên trên) -> Hợp lệ")
    void createRequest_LngAtMax_ShouldPass() {
        assertCreated(dto(16.0544, 109.46));
    }

    // ===== Bổ sung nhánh để đạt 100% Branch Coverage (AC 2) =====

    @Test
    @DisplayName("WB_SOS_10: Vĩ độ 23.40 (vượt biên trên lãnh thổ VN) -> Ném 400, không lưu DB")
    void WB_SOS_10_createRequest_LatAboveMax_ShouldThrowBadRequest() {
        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> rescueRequestService.createRequest(dto(23.40, 108.2022)));
        assertTrue(ex.getMessage().contains("vĩ độ"));
        verify(rescueRequestRepository, never()).save(any(RescueRequest.class));
    }

    @Test
    @DisplayName("WB_SOS_11: Kinh độ 102.13 (dưới biên dưới lãnh thổ VN) -> Ném 400, không lưu DB")
    void WB_SOS_11_createRequest_LngBelowMin_ShouldThrowBadRequest() {
        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> rescueRequestService.createRequest(dto(16.0544, 102.13)));
        assertTrue(ex.getMessage().contains("kinh độ"));
        verify(rescueRequestRepository, never()).save(any(RescueRequest.class));
    }

    @Test
    @DisplayName("WB_SOS_12: Vĩ độ null -> Bỏ qua kiểm tra vĩ độ, tạo đơn thành công")
    void WB_SOS_12_createRequest_LatNull_ShouldPass() {
        RescueRequestDto dto = dto(null, 108.2022);
        RescueRequest saved = assertDoesNotThrow(() -> rescueRequestService.createRequest(dto));
        assertNull(saved.getLocationLat());
        assertEquals(108.2022, saved.getLocationLng());
        verify(rescueRequestRepository, times(1)).save(any(RescueRequest.class));
    }

    @Test
    @DisplayName("WB_SOS_13: Kinh độ null -> Bỏ qua kiểm tra kinh độ, tạo đơn thành công")
    void WB_SOS_13_createRequest_LngNull_ShouldPass() {
        RescueRequestDto dto = dto(16.0544, null);
        RescueRequest saved = assertDoesNotThrow(() -> rescueRequestService.createRequest(dto));
        assertEquals(16.0544, saved.getLocationLat());
        assertNull(saved.getLocationLng());
        verify(rescueRequestRepository, times(1)).save(any(RescueRequest.class));
    }
}
