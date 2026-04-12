package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.Data;
import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "danger_points")
public class DangerPoint {
    @Id
    private String id;
    private String name;
    private String address;
    private Double latitude;
    private Double longitude;
    private Double depth; // Độ sâu nước (mét)
    private String createdBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
