package vn.rescue.core.domain.entities;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MissionItem {
    private String itemId;
    private String itemName;
    private String unit;
    private Integer quantity;
}
