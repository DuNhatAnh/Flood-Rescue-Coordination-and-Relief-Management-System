package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "assignments")
public class Assignment {

    @Id
    private String id;

    @Field("request_id")
    private String requestId;

    @Field("team_id")
    private String teamId;

    @Field("assigned_by")
    private String assignedBy;

    @Field("assigned_at")
    private LocalDateTime assignedAt;

    private String status = "IN_PROGRESS"; // IN_PROGRESS / COMPLETED / CANCELLED

    @Field("completed_at")
    private LocalDateTime completedAt;
}
