package vn.rescue.core.domain.entities;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "rescue_reports")
public class RescueReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "report_id")
    private Long id;

    @Column(name = "assignment_id", nullable = false)
    private Long assignmentId;

    @Column(name = "rescued_people_count")
    private Integer rescuedPeopleCount = 0;

    @Column(name = "actual_condition")
    private String actualCondition;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;
}
