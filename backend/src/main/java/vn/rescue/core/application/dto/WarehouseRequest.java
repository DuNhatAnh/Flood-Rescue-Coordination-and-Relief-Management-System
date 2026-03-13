package vn.rescue.core.application.dto;

import lombok.Data;

@Data
public class WarehouseRequest {
    private String warehouseName;
    private String location;
    private String managerId;
    private String status;
}
