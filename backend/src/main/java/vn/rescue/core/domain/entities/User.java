package vn.rescue.core.domain.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Document(collection = "users")
public class User {

    @Id
    private String id;

    @Field("full_name")
    private String fullName;

    @Field("email")
    private String email;

    private String phone;

    private String password;

    @Field("role_id")
    private String roleId;

    private String status = "ACTIVE"; // ACTIVE / LOCKED

    @Field("created_at")
    private LocalDateTime createdAt;
}
