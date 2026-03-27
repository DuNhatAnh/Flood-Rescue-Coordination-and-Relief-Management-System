package vn.rescue.core.application.dto;

import lombok.*;
import java.util.List;

@Data
@Builder
public class DashboardStatsResponse {
    private long totalVehicles;
    private long availableVehicles;
    private long totalWarehouses;
    private List<InventoryResponse> lowStockItems; // Cảnh báo hàng sắp hết
    private long unreadNotifications;             // Số thông báo chưa đọc
}