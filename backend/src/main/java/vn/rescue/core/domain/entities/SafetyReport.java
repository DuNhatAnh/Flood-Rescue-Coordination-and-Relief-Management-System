package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "safety_reports")
public class SafetyReport {

    @Id
    private String id;

    @Field("citizen_name")
    private String citizenName;

    @Field("citizen_phone")
    private String citizenPhone;

    @Field("location_lat")
    private Double locationLat;

    @Field("location_lng")
    private Double locationLng;

    @Field("address_text")
    private String addressText;

    private String note;

    @Field("reported_at")
    private LocalDateTime reportedAt;
}
