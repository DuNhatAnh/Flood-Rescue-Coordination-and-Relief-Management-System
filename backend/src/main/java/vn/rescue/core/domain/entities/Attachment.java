package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "attachments")
public class Attachment {

    @Id
    private String id;

    @Field("request_id")
    private String requestId;

    @Field("file_url")
    private String fileUrl;

    @Field("uploaded_at")
    private LocalDateTime uploadedAt;
}
