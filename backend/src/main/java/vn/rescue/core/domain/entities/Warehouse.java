package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "warehouses")
public class Warehouse {
    @Id
    private String id;

    @Field("warehouse_name")
    private String warehouseName;

    private String location;

    @Field("manager_id")
    private String managerId;

    private String status = "ACTIVE";
    
    private Double latitude;
    private Double longitude;

    @Field("created_at")
    private LocalDateTime createdAt;
}
