package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryResponse {
    private String id;
    private String warehouseId;
    private String itemId;
    private String itemName;
    private String unit;
    private Integer quantity;
    private String imageUrl;
}
