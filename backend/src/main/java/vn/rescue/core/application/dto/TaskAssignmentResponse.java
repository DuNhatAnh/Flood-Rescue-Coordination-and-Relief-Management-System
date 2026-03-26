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

    // From RescueRequest
    private String citizenName;
    private String citizenPhone;
    private String addressText;
    private String description;
    private String urgencyLevel;
    private Double locationLat;
    private Double locationLng;
}
