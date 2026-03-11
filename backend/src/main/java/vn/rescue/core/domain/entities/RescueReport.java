package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "rescue_reports")
public class RescueReport {

    @Id
    private String id;

    @Field("assignment_id")
    private String assignmentId;

    @Field("rescued_people_count")
    private Integer rescuedPeopleCount = 0;

    @Field("actual_condition")
    private String actualCondition;

    @Field("image_url")
    private String imageUrl;

    @Field("created_at")
    private LocalDateTime createdAt;
}
