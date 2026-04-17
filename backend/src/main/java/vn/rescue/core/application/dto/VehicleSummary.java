package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VehicleSummary {
    private String id;
    private String vehicleType;
    private String licensePlate;
}
