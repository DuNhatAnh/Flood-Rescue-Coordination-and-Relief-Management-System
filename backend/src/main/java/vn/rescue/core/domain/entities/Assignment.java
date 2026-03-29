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

    @Field("vehicle_ids")
    private java.util.List<String> vehicleIds;

    @Field("assigned_by")
    private String assignedBy;

    @Field("assigned_at")
    private LocalDateTime assignedAt;

    private String status = "ASSIGNED"; // ASSIGNED / PREPARING / MOVING / RESCUING / RETURNING / COMPLETED / CANCELLED / REJECTED

    @Field("mission_items")
    private java.util.List<MissionItem> missionItems;

    @Field("assigned_items")
    private java.util.List<MissionItem> assignedItems;

    @Field("items_exported")
    private boolean itemsExported = false;

    @Field("completed_at")
    private LocalDateTime completedAt;

    @Field("rescued_count")
    private Integer rescuedCount;

    @Field("report_note")
    private String reportNote;

    @Field("actual_distributed_items")
    private java.util.List<MissionItem> actualDistributedItems;

    @Field("image_urls")
    private java.util.List<String> imageUrls;
}
