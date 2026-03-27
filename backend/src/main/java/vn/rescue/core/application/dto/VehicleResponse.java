package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data // Tự động tạo Getter, Setter để Controller có thể đọc dữ liệu
@Builder // Sửa lỗi "Cannot resolve method 'builder'" trong Service
@NoArgsConstructor // Cần thiết để các thư viện như Jackson có thể khởi tạo Object
@AllArgsConstructor // Bắt buộc phải có khi dùng @Builder
public class VehicleResponse {

    private String id; // Lấy từ @Id trong MongoDB
    private String vehicleType; // Khớp với vehicle_type
    private String licensePlate; // Khớp với license_plate
    private String status; // Trạng thái hiện tại (mặc định AVAILABLE)

    private String warehouseId; // ID kho quan ly xe
    private String warehouseName; // Ten kho

    private String currentLocation; // Tọa độ hoặc địa chỉ dạng text
    private String teamId; // ID đội cứu hộ dạng String
    private String teamName; // ten doi cua ho dang lay xe
    private String capacity; //Tai trong/suc chua


}