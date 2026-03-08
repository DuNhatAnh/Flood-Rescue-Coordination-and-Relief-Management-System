package vn.rescue.core.domain.entities;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "assignments")
public class Assignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "assignment_id")
    private Long id;

    @Column(name = "request_id", nullable = false)
    private Long requestId;

    @Column(name = "team_id", nullable = false)
    private Integer teamId;

    @Column(name = "assigned_by", nullable = false)
    private Integer assignedBy;

    @Column(name = "assigned_at", insertable = false, updatable = false)
    private LocalDateTime assignedAt;

    @Column(name = "status")
    private String status = "IN_PROGRESS"; // IN_PROGRESS / COMPLETED / CANCELLED

    @Column(name = "completed_at")
    private LocalDateTime completedAt;
}
