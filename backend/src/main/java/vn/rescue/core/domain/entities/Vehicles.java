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
@Builder // Thêm Builder để tạo object nhanh trong Service
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "vehicles")
public class Vehicles {

    @Id
    private String id;

    @Field("vehicle_type")
    private String vehicleType; // Xe tải, Xe bán tải, Xuồng máy, Cano

    @Field("license_plate")
    private String licensePlate;

    private String status; // AVAILABLE, IN_USE, MAINTENANCE, BROKEN

    @Field("warehouse_id")
    private String warehouseId; //  Để thống kê xe theo từng kho cụ thể

    @Field("current_location")
    private String currentLocation;

    @Field("capacity")
    private String capacity; // (Dùng để hiển thị chi tiết)

    @Field("team_id")
    private String teamId; // ID đội cứu hộ đang sử dụng xe này

    @Field("updated_at")
    private LocalDateTime updatedAt; // Để biết xe cập nhật vị trí/trạng thái lúc nào
}