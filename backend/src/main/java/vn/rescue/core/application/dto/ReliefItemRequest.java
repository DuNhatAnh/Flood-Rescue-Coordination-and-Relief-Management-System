package vn.rescue.core.application.dto;

import lombok.Data;

@Data
public class ReliefItemRequest {
    private String itemName;
    private String unit;
    private String description;
}
