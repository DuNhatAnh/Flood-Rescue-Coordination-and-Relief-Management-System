package vn.rescue.core.application.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@Builder
public class SystemLogResponse {
    private String action;      // CREATE, UPDATE, DELETE...
    private String module;      // VEHICLE, INVENTORY...
    private String userName;    // Tên người thực hiện
    private String details;     // Nội dung: "Đã cập nhật xe 43C-12345"
    private LocalDateTime createdAt;
}