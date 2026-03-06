package vn.rescue.core.domain.entities;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "rescue_requests")
public class RescueRequest {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "request_id")
    private Long id;
    
    @Column(name = "citizen_name", nullable = false)
    private String citizenName;
    
    @Column(name = "citizen_phone", nullable = false)
    private String citizenPhone;
    
    @Column(name = "location_lat", nullable = false)
    private Double locationLat;
    
    @Column(name = "location_lng", nullable = false)
    private Double locationLng;
    
    @Column(name = "address_text", nullable = false)
    private String addressText;
    
    @Column(name = "description")
    private String description;
    
    @Column(name = "urgency_level")
    private String urgencyLevel = "MEDIUM"; // HIGH / MEDIUM / LOW
    
    @Column(name = "status")
    private String status = "PENDING";      // PENDING / ASSIGNED / COMPLETED
    
    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "verified_by")
    private Integer verifiedBy; // can be mapped to User entity later
}
