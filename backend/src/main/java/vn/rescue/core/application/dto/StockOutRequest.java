package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockOutRequest {
    private String warehouseId;
    private String itemId;
    private Integer quantity;
    private String reason; // e.g., "RESCUE_MISSION"
    private String assignmentId;
}
