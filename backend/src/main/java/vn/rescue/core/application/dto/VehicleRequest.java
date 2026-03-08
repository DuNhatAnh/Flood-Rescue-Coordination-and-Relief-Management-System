package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data // Tự động tạo Getter, Setter, equals, canEqual, hashCode, toString
@Builder // Cho phép sử dụng VehicleRequest.builder()
@NoArgsConstructor // Tạo constructor không tham số (bắt buộc cho Jackson/Spring)
@AllArgsConstructor // Tạo constructor đầy đủ tham số (bắt buộc cho @Builder)
public class VehicleRequest {

    private String vehicleType;     // Khớp với varchar(50)
    private String licensePlate;    // Khớp với varchar(20)
    private String currentLocation; // Khớp với text
    private Integer teamId;         // Khớp với integer
}