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
@Document(collection = "stock_transactions")
public class StockTransaction {
    @Id
    private String id;

    @Field("warehouse_id")
    private String warehouseId;

    @Field("item_id")
    private String itemId;

    private Integer quantity;

    @Field("transaction_type")
    private String transactionType; // IMPORT, EXPORT

    private String source; // Donor, Supplier, etc.

    @Field("reference_number")
    private String referenceNumber; // Slip ID / Invoice ID

    @Field("expiry_date")
    private LocalDateTime expiryDate;

    private String condition; // New, Good, Used, Damaged

    @Field("staff_id")
    private String staffId;

    private String reason; // e.g., "RESCUE_MISSION"

    @Field("assignment_id")
    private String assignmentId;

    private LocalDateTime timestamp;
}
