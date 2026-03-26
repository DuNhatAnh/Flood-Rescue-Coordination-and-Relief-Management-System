package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
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
