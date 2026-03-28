package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "notifications")
public class Notification {
    @Id
    private String id;

    private String title;
    private String content;

    // INFO, WARNING, SOS (Khớp với màu sắc trên UI Flutter)
    private String type;

    // HIGH, NORMAL, LOW (Để sắp xếp độ quan trọng)
    private String priority;

    @Field("is_read")
    @Builder.Default
    private boolean isRead = false; // Quan trọng: Để lọc thông báo chưa đọc

    @Field("sender_id")
    private String senderId; // ID người gửi (Admin hoặc Hệ thống)

    @Field("user_id")
    private String userId; // ID người nhận (Null nếu là thông báo chung cho toàn hệ thống)

    @Field("created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now(); // Tự động lấy thời gian hiện tại

    public void markAsRead() {
        this.isRead = true;
    }
}