package vn.rescue.core.application.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import vn.rescue.core.domain.entities.MissionItem;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AssignmentRequest {
    private String requestId;
    private String teamId;
    private List<String> vehicleIds;
    private String assignedBy;
    private List<MissionItem> missionItems;
    private String note;
}