package vn.rescue.core.application.dto;

import lombok.Data;
import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDto {
    private String id;
    private String title;
    private String content;
    private String type;
    private String priority;
    private String userId;
    private boolean isRead; // Trang thai da doc
    private LocalDateTime createAt; //De hien thi thoi gian: "5 phut truoc"
}
