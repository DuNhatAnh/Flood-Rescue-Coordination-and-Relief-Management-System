package vn.rescue.core.domain.entities;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "rescue_teams")
public class RescueTeam {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "team_id")
    private Integer id;

    @Column(name = "team_name", nullable = false)
    private String teamName;

    @Column(name = "status")
    private String status = "AVAILABLE"; // AVAILABLE / BUSY

    @Column(name = "leader_id", nullable = false)
    private Integer leaderId;
}
