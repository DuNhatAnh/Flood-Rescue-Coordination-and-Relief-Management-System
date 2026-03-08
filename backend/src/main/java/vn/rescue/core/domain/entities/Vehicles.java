package vn.rescue.core.domain.entities;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "vehicles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Vehicles {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Khớp với nextval('vehicles_...') trong DB
    @Column(name = "vehicle_id")
    private Integer vehicleId;

    @Column(name = "vehicle_type", length = 50) // Khớp với varchar(50)
    private String vehicleType;

    @Column(name = "license_plate", length = 20) // Khớp với varchar(20)
    private String licensePlate;

    @Column(name = "status", length = 20) // Khớp với varchar(20)
    private String status; // Mặc định trong DB là 'AVAILABLE'

    @Column(name = "current_location", columnDefinition = "text") // Khớp với kiểu text
    private String currentLocation;

    @Column(name = "team_id") // Khớp với kiểu integer
    private Integer teamId;
}