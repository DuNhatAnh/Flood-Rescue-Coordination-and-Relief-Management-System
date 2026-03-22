package vn.rescue.core.application.dto;

import lombok.Data;
import java.util.List;

@Data
public class DistributionRequest {
    private String warehouseId;
    private String requestId;
    private String type; // EXPORT or TRANSFER
    private String destinationWarehouseId;
    private List<ItemQuantity> items;

    @Data
    public static class ItemQuantity {
        private String itemId;
        private Integer quantity;
    }
}
