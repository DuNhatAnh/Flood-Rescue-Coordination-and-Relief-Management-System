package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.ItemConsumptionDTO;
import vn.rescue.core.domain.repositories.*;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportService {
    private final RescueRequestRepository rescueRequestRepository;
    private final UserRepository userRepository;
    private final RescueTeamRepository rescueTeamRepository;
    private final DistributionRepository distributionRepository;
    private final DistributionDetailRepository distributionDetailRepository;
    private final InventoryRepository inventoryRepository;
    private final ReliefItemRepository reliefItemRepository;

    /**
     * Lấy thống kê cho Dashboard của nhân viên (Staff)
     * Đã cập nhật khớp với dữ liệu thực tế: COMPLETED, ASSIGNED, PENDING
     */
    public Map<String, Object> getStaffDashboardStats() {
        // Sử dụng LinkedHashMap để giữ thứ tự các key cho JSON đẹp hơn
        Map<String, Object> stats = new LinkedHashMap<>();

        // 1. Task Statistics - Cập nhật khớp với thực tế MongoDB của bạn
        // Đếm các task đã hoàn thành
        stats.put("completedTasks", (long) rescueRequestRepository.countByStatus("COMPLETED"));

        // Đang thực hiện: Trong DB của bạn đang dùng "ASSIGNED".
        // Cộng gộp cả ASSIGNED và IN_PROGRESS để tránh thiếu sót.
        long assigned = rescueRequestRepository.countByStatus("ASSIGNED");
        long inProgress = rescueRequestRepository.countByStatus("IN_PROGRESS");
        stats.put("activeTasks", assigned + inProgress);

        // Đang chờ xử lý
        stats.put("pendingTasks", (long) rescueRequestRepository.countByStatus("PENDING"));

        // 2. Low Stock Alerts (Cảnh báo tồn kho thấp)
        var lowStockRaw = inventoryRepository.findLowStockItems();
        List<Map<String, Object>> lowStockData = (lowStockRaw != null) ? lowStockRaw.stream().map(inv -> {
            Map<String, Object> m = new HashMap<>();
            m.put("itemName", inv.getItemName() != null ? inv.getItemName() : "Không xác định");
            m.put("quantity", inv.getQuantity());
            m.put("minThreshold", inv.getMinThreshold());
            m.put("unit", inv.getUnit() != null ? inv.getUnit() : "");
            return m;
        }).collect(Collectors.toList()) : new ArrayList<>();
        stats.put("lowStockAlerts", lowStockData);

        // 3. Pie Chart Data (Thống kê vật phẩm tiêu thụ)
        List<ItemConsumptionDTO> consumptionRaw = distributionDetailRepository.aggregateItemConsumption();
        List<Map<String, Object>> chartData = (consumptionRaw != null) ? consumptionRaw.stream().map(item -> {
            String itemId = item.get_id();
            var itemInfo = (itemId != null) ? reliefItemRepository.findById(itemId).orElse(null) : null;

            Map<String, Object> node = new HashMap<>();
            node.put("name", itemInfo != null ? itemInfo.getItemName() : "Khác");
            node.put("value", item.getTotalQuantity() != null ? item.getTotalQuantity() : 0);
            node.put("unit", itemInfo != null ? itemInfo.getUnit() : "");
            return node;
        }).collect(Collectors.toList()) : new ArrayList<>();
        stats.put("topItemsChart", chartData);

        // 4. Activity History (Lịch sử biến động nguồn lực)
        var historyRaw = distributionRepository.findAllByOrderByDistributedAtDesc();
        List<Map<String, Object>> historyData = (historyRaw != null) ? historyRaw.stream().limit(10).map(dist -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", dist.getId());
            m.put("type", dist.getType() != null ? dist.getType().toString() : "UNKNOWN");
            m.put("status", dist.getStatus() != null ? dist.getStatus().toString() : "UNKNOWN");
            m.put("distributedAt", dist.getDistributedAt() != null ? dist.getDistributedAt().toString() : "");
            return m;
        }).collect(Collectors.toList()) : new ArrayList<>();
        stats.put("recentHistory", historyData);

        return stats;
    }

    /**
     * Thống kê tổng quát cho Admin
     */
    public Map<String, Object> getGeneralStats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalUsers", userRepository.count());
        stats.put("totalRequests", rescueRequestRepository.count());
        stats.put("pendingRequests", rescueRequestRepository.countByStatus("PENDING"));
        stats.put("completedRequests", rescueRequestRepository.countByStatus("COMPLETED"));
        // Tính cả ASSIGNED cho General Stats nếu cần
        stats.put("activeRequests", rescueRequestRepository.countByStatus("ASSIGNED") + rescueRequestRepository.countByStatus("IN_PROGRESS"));
        stats.put("totalTeams", rescueTeamRepository.count());
        return stats;
    }
}