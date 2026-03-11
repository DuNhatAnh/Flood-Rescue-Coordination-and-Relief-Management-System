package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;

@Data
@Document(collection = "distribution_details")
public class DistributionDetail {
    @Id
    private String id;

    @Field("distribution_id")
    private String distributionId;

    @Field("item_id")
    private String itemId;

    private Integer quantity;
}
