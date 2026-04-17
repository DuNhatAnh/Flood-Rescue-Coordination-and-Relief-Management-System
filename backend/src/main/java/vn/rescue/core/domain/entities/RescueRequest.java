package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;

@Data
@Document(collection = "rescue_requests")
public class RescueRequest {

    @Id
    private String id;

    @Field("custom_id")
    private String customId;

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

    private String description;

    @Field("urgency_level")
    private String urgencyLevel = "MEDIUM"; // LOW, MEDIUM, HIGH

    private String status = "PENDING"; // PENDING / ASSIGNED / COMPLETED

    @Field("number_of_people")
    private Integer numberOfPeople = 1;

    @Field("created_at")
    private LocalDateTime createdAt;

    @Field("is_verified")
    private boolean verified = false;

    @JsonProperty("isVerified")
    public boolean isVerified() {
        return verified;
    }

    public void setVerified(boolean verified) {
        this.verified = verified;
    }

    @Field("verified_by")
    private String verifiedBy;

    @Field("team_id")
    private String teamId;

    @Field("citizen_verified")
    private boolean citizenVerified = false;

    @Field("citizen_verified_at")
    private LocalDateTime citizenVerifiedAt;

    @Field("reported_at")
    private LocalDateTime reportedAt;

    private String note;
}
