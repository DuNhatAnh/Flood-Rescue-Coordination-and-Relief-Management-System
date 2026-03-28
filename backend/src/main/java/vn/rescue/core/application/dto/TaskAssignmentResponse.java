package vn.rescue.core.application.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class TaskAssignmentResponse {
    private String id;
    private String requestId;
    private String teamId;
    private String vehicleId;
    private String assignedBy;
    private LocalDateTime assignedAt;
    private String status;

    // From RescueTeam
    private String teamName;

    // From Vehicles
    private String vehicleType;
    private String licensePlate;

    // From RescueRequest
    private String citizenName;
    private String citizenPhone;
    private String addressText;
    private String description;
    private String urgencyLevel;
    private Integer numberOfPeople;
    private Double locationLat;
    private Double locationLng;

    private java.util.List<vn.rescue.core.domain.entities.MissionItem> missionItems;
    private java.util.List<vn.rescue.core.domain.entities.MissionItem> assignedItems;
    private boolean itemsExported;
}
