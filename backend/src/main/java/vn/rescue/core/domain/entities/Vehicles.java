package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;

@Data
@Document(collection = "vehicles")
public class Vehicles {

    @Id
    private String id;

    @Field("vehicle_type")
    private String vehicleType;

    @Field("license_plate")
    private String licensePlate;

    private String status;

    @Field("current_location")
    private String currentLocation;

    @Field("team_id")
    private String teamId;
}