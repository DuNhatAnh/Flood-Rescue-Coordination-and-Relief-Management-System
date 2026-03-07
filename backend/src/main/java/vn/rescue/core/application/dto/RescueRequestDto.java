package vn.rescue.core.application.dto;

import lombok.Data;

@Data
public class RescueRequestDto {
    private String citizenName;
    private String citizenPhone;
    private Double locationLat;
    private Double locationLng;
    private String addressText;
    private String description;
    private String urgencyLevel;
    private Integer numberOfPeople;
}
