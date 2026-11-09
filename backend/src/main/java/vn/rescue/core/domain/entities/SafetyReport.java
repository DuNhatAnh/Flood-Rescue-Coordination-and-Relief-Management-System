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

    @com.fasterxml.jackson.annotation.JsonProperty("phoneNumber")
    public void setPhoneNumber(String phoneNumber) {
        if (this.citizenPhone == null || this.citizenPhone.isBlank()) {
            this.citizenPhone = phoneNumber;
        }
    }

    @com.fasterxml.jackson.annotation.JsonProperty("contactName")
    public void setContactName(String contactName) {
        if (this.citizenName == null || this.citizenName.isBlank()) {
            this.citizenName = contactName;
        }
    }

    @com.fasterxml.jackson.annotation.JsonProperty("address")
    public void setAddress(String address) {
        if (this.addressText == null || this.addressText.isBlank()) {
            this.addressText = address;
        }
    }

    @com.fasterxml.jackson.annotation.JsonProperty("latitude")
    public void setLatitude(Double latitude) {
        if (this.locationLat == null) {
            this.locationLat = latitude;
        }
    }

    @com.fasterxml.jackson.annotation.JsonProperty("longitude")
    public void setLongitude(Double longitude) {
        if (this.locationLng == null) {
            this.locationLng = longitude;
        }
    }
}
