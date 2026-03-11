package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;

@Data
@Document(collection = "inventory")
public class Inventory {
    @Id
    private String id;

    @Field("warehouse_id")
    private String warehouseId;

    @Field("item_id")
    private String itemId;

    private Integer quantity = 0;
}
