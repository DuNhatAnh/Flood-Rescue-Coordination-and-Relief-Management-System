package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import vn.rescue.core.application.dto.NotificationDto;
import vn.rescue.core.application.services.SystemManagementService;
import vn.rescue.core.domain.entities.Notification;
import vn.rescue.core.presentation.common.ApiResponse;

import static org.assertj.core.api.Assertions.assertThat;

class NotificationControllerTest {

    private NotificationController notificationController;

    static class StubSystemManagementService extends SystemManagementService {
        public StubSystemManagementService() {
            super(null, null, null, null, null, null);
        }

        @Override
        public Notification sendNotification(NotificationDto dto) {
            if (dto.getUserId() == null || dto.getUserId().trim().isEmpty()) {
                throw new IllegalArgumentException("Người nhận không được để trống");
            }
            if (dto.getTitle() == null || dto.getTitle().trim().isEmpty()) {
                throw new IllegalArgumentException("Tiêu đề không được để trống");
            }
            return Notification.builder()
                    .id("noti_01")
                    .title(dto.getTitle())
                    .content(dto.getContent())
                    .userId(dto.getUserId())
                    .build();
        }

        @Override
        public long getUnreadNotificationCount(String userId) {
            return 3L;
        }
    }

    @BeforeEach
    void setUp() {
        notificationController = new NotificationController(new StubSystemManagementService());
    }

    @Test
    @DisplayName("Gửi thông báo thiếu người nhận (userId rỗng/null) phải trả về HTTP 400 Bad Request")
    void sendNotification_missingRecipient_shouldReturnBadRequest() {
        NotificationDto dto = NotificationDto.builder()
                .title("Cảnh báo lũ quét")
                .content("Nước dâng cao tại Đại Lộc")
                .userId(null)
                .build();

        ResponseEntity<ApiResponse<Notification>> response = notificationController.sendNotification(dto);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("Người nhận không được để trống");

        // Thử với userId chuỗi trắng
        dto.setUserId("   ");
        ResponseEntity<ApiResponse<Notification>> blankResponse = notificationController.sendNotification(dto);
        assertThat(blankResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    @DisplayName("Gửi thông báo thiếu tiêu đề (title rỗng/null) phải trả về HTTP 400 Bad Request")
    void sendNotification_missingTitle_shouldReturnBadRequest() {
        NotificationDto dto = NotificationDto.builder()
                .title(null)
                .content("Nội dung thông báo")
                .userId("user_123")
                .build();

        ResponseEntity<ApiResponse<Notification>> response = notificationController.sendNotification(dto);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).contains("Tiêu đề không được để trống");

        // Thử với title chuỗi trắng
        dto.setTitle("  ");
        ResponseEntity<ApiResponse<Notification>> blankResponse = notificationController.sendNotification(dto);
        assertThat(blankResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    @DisplayName("Gửi thông báo đầy đủ người nhận và tiêu đề phải thành công HTTP 200 OK")
    void sendNotification_validRecipientAndTitle_shouldReturnOk() {
        NotificationDto dto = NotificationDto.builder()
                .title("Thông báo khẩn cấp")
                .content("Đội cứu hộ đang di chuyển")
                .userId("user_123")
                .type("SOS")
                .priority("HIGH")
                .build();

        ResponseEntity<ApiResponse<Notification>> response = notificationController.sendNotification(dto);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();
        assertThat(response.getBody().getData().getTitle()).isEqualTo("Thông báo khẩn cấp");
    }

    @Test
    @DisplayName("Lấy số thông báo chưa đọc khi thiếu userId phải trả về HTTP 400 Bad Request")
    void getUnreadCount_missingUserId_shouldReturnBadRequest() {
        ResponseEntity<ApiResponse<Long>> response = notificationController.getUnreadCount(null);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        ResponseEntity<ApiResponse<Long>> blankResponse = notificationController.getUnreadCount("  ");
        assertThat(blankResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
