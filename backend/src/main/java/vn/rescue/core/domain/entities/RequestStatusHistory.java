package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "request_status_history")
public class RequestStatusHistory {

    @Id
    private String id;

    @Field("request_id")
    private String requestId;

    private String status;

    @Field("created_at")
    private LocalDateTime createdAt;

    private String note;
}
