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

    // Thông tin phương tiện (Danh sách)
    private java.util.List<String> vehicleIds;
    private String licensePlate; // Biển số (gộp các xe)
    private String vehicleType;  // Loại xe (gộp các loại)

    // Thông tin đội cứu hộ đảm nhận
    private String teamId;

    // Trạng thái và thời gian
    private String status; // ACTIVE
    private LocalDateTime assignedAt;

    // Thông điệp phản hồi cho người dùng
    private String message;
}