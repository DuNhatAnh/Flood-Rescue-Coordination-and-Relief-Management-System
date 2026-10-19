package vn.rescue.core.application.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class NotificationDto {
    private String id;

    @NotBlank(message = "Tiêu đề không được để trống")
    private String title;

    private String content;
    private String type;
    private String priority;

    @NotBlank(message = "Người nhận không được để trống")
    private String userId;

    private boolean isRead; // Trang thai da doc
    private LocalDateTime createAt; // De hien thi thoi gian: "5 phut truoc"

    public NotificationDto() {
    }

    public NotificationDto(String id, String title, String content, String type, String priority, String userId, boolean isRead, LocalDateTime createAt) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.type = type;
        this.priority = priority;
        this.userId = userId;
        this.isRead = isRead;
        this.createAt = createAt;
    }
}
