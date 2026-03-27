package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "distributions")
public class Distribution {
    @Id
    private String id;

    @Field("warehouse_id")
    private String warehouseId;

    @Field("request_id")
    private String requestId;

    @Field("distributed_by")
    private String distributedBy;

    @Field("distributed_at")
    private LocalDateTime distributedAt;

    private String type = "EXPORT"; // EXPORT or TRANSFER

    @Field("destination_warehouse_id")
    private String destinationWarehouseId;

    private String status = "COMPLETED"; // IN_TRANSIT, COMPLETED, CANCELLED
}
