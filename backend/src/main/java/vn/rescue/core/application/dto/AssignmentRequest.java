package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data // Quan trọng nhất: Nó sẽ tạo ra getRequestId(), getVehicleId(), getNote()
@AllArgsConstructor
@NoArgsConstructor
public class AssignmentRequest {
    private String requestId;
    private String vehicleId;
    private String note;
}