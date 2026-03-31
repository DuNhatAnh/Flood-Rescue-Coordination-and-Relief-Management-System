package vn.rescue.core.application.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor // CỰC KỲ QUAN TRỌNG: Thiếu cái này Spring sẽ báo lỗi type null
public class ItemConsumptionDTO {
    private String _id; // MongoDB Aggregation Group trả về ID ở field _id
    private Long totalQuantity;
}