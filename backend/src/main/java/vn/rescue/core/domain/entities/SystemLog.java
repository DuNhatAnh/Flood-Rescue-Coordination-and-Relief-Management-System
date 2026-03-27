package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "system_logs")
public class SystemLog {
    @Id
    private String id;
    private String action; // CREATE_USER, LOGIN, etc.
    private String moudle;
    private String userId;
    private String userName;
    private String details;
    private String module;
    @Field("created_at")
    private LocalDateTime createdAt;
}
