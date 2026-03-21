package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssignmentResponse {

    // ID của bản ghi gán vừa tạo
    private String assignmentId;

    // Thông tin nhiệm vụ
    private String requestId;
    private String customId; // Mã hiển thị (ví dụ: REQ-001)
    private String citizenName;

    // Thông tin phương tiện
    private String vehicleId;
    private String licensePlate;
    private String vehicleType;

    // Thông tin đội cứu hộ đảm nhận
    private String teamId;

    // Trạng thái và thời gian
    private String status; // ACTIVE
    private LocalDateTime assignedAt;

    // Thông điệp phản hồi cho người dùng
    private String message;
}