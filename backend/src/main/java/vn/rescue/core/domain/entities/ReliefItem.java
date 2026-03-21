package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;

@Data
@Document(collection = "relief_items")
public class ReliefItem {
    @Id
    private String id;

    @Field("item_name")
    private String itemName;

    private String unit;

    private String description;
    
    @Field("image_url")
    private String imageUrl;
}
