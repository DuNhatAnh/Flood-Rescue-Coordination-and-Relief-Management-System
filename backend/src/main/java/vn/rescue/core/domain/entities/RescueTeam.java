package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "rescue_teams")
public class RescueTeam {

    @Id
    private String id;

    @Field("team_name")
    private String teamName;

    private String status = "AVAILABLE"; // AVAILABLE / BUSY

    @Field("leader_id")
    private String leaderId;
}
