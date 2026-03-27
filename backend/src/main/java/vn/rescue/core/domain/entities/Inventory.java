package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "inventory")
public class Inventory {
    @Id
    private String id;

    @Field("warehouse_id")
    private String warehouseId;

    @Field("item_id")
    private String itemId;

    @Field("item_name")
    private String itemName; // Ví dụ: Gạo, Mì tôm, Nước sạch (Dùng để hiển thị nhanh trên Dashboard)

    @Field("unit")
    private String unit; // Đơn vị tính: Kg, Thùng, Lít, Cái

    private Integer quantity = 0;

    @Field("min_threshold")
    private Integer minThreshold; // Ngưỡng tối thiểu (Để báo động đỏ trên UI khi hàng sắp hết)

    @Field("max_capacity")
    private Integer maxCapacity; // Sức chứa tối đa (Dùng để tính % thanh tiến trình trên UI)
}