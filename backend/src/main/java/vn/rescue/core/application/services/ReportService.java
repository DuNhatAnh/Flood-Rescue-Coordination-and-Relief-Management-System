package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.ItemConsumptionDTO;
import vn.rescue.core.domain.repositories.*;
import vn.rescue.core.domain.entities.*;
import org.springframework.security.core.context.SecurityContextHolder;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import java.time.LocalDate;

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
    private final AssignmentRepository assignmentRepository;
    private final VehiclesRepository vehiclesRepository;
    private final StockTransactionRepository stockTransactionRepository;

    /**
     * Helper: Lấy bối cảnh người dùng hiện tại (Team và Warehouse)
     */
    private Map<String, String> getCurrentUserContext() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getName() == null) return null;
        
        String email = auth.getName();
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_COORDINATOR"));
        
        if (isAdmin) return null; // Admin xem tất cả

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null || user.getTeamId() == null) {
            Map<String, String> empty = new HashMap<>();
            empty.put("empty", "true");
            return empty;
        }

        Map<String, String> context = new HashMap<>();
        context.put("teamId", user.getTeamId());
        
        rescueTeamRepository.findById(user.getTeamId()).ifPresent(team -> {
            context.put("warehouseId", team.getWarehouseId());
        });
        
        return context;
    }

    /**
     * Lấy thống kê cho Dashboard của nhân viên (Staff)
     * Đã cập nhật khớp với dữ liệu thực tế: COMPLETED, ASSIGNED, PENDING
     */
    public Map<String, Object> getStaffDashboardStats() {
        // Lấy context để lọc
        Map<String, String> context = getCurrentUserContext();
        if (context != null && context.containsKey("empty")) {
            Map<String, Object> empty = new LinkedHashMap<>();
            empty.put("completedTasks", 0L);
            empty.put("activeTasks", 0L);
            empty.put("pendingTasks", 0L);
            empty.put("lowStockAlerts", new ArrayList<>());
            return empty;
        }

        String teamId = context != null ? context.get("teamId") : null;
        String warehouseId = context != null ? context.get("warehouseId") : null;

        // Sử dụng LinkedHashMap để giữ thứ tự các key cho JSON đẹp hơn
        Map<String, Object> stats = new LinkedHashMap<>();

        // 1. Task Statistics
        if (teamId != null) {
            stats.put("completedTasks", rescueRequestRepository.findByStatus("COMPLETED").stream().filter(r -> teamId.equals(r.getTeamId())).count());
            long assigned = rescueRequestRepository.findByStatus("ASSIGNED").stream().filter(r -> teamId.equals(r.getTeamId())).count();
            long inProgress = rescueRequestRepository.findByStatus("IN_PROGRESS").stream().filter(r -> teamId.equals(r.getTeamId())).count();
            stats.put("activeTasks", assigned + inProgress);
            stats.put("pendingTasks", 0L); // Staff chỉ thấy task đã gán cho mình hoặc đang bận? 
                                          // Thực tế Staff có thể thấy Pending chung để chọn, nhưng Dashboard này là "Của tôi"
        } else {
            stats.put("completedTasks", (long) rescueRequestRepository.countByStatus("COMPLETED"));
            long assigned = rescueRequestRepository.countByStatus("ASSIGNED");
            long inProgress = rescueRequestRepository.countByStatus("IN_PROGRESS");
            stats.put("activeTasks", assigned + inProgress);
            stats.put("pendingTasks", (long) rescueRequestRepository.countByStatus("PENDING"));
        }

        // 2. Low Stock Alerts
        List<Inventory> lowStockRaw;
        if (warehouseId != null) {
            lowStockRaw = inventoryRepository.findLowStockItems().stream()
                    .filter(inv -> warehouseId.equals(inv.getWarehouseId()))
                    .collect(Collectors.toList());
        } else {
            lowStockRaw = inventoryRepository.findLowStockItems();
        }

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

    /**
     * Thống kê chi tiết cho Dashboard Điều phối viên/Admin
     */
    public Map<String, Object> getDetailedAnalytics() {
        Map<String, Object> analytics = new LinkedHashMap<>();

        // 1. Chỉ số KPI
        analytics.put("totalRequests", rescueRequestRepository.count());
        analytics.put("totalTeams", rescueTeamRepository.count());
        
        // Đếm tổng số người dự kiến được cứu từ các yêu cầu hoàn thành
        var completedRequests = rescueRequestRepository.findByStatus("COMPLETED");
        int totalPeopleRescued = completedRequests.stream()
                .mapToInt(r -> r.getNumberOfPeople() != null ? r.getNumberOfPeople() : 0)
                .sum();
        analytics.put("totalPeopleRescued", totalPeopleRescued);

        // 2. Phân bổ theo trạng thái (Pie Chart) - KHÔNG PHÂN BIỆT CHỮ HOA CHỮ THƯỜNG
        Map<String, Long> statusDistribution = new HashMap<>();
        String[] statuses = {"PENDING", "VERIFIED", "ASSIGNED", "IN_PROGRESS", "COMPLETED", "CANCELLED"};
        for (String s : statuses) {
            statusDistribution.put(s, 0L);
        }
        List<vn.rescue.core.domain.entities.RescueRequest> allRequests = rescueRequestRepository.findAll();
        for (vn.rescue.core.domain.entities.RescueRequest req : allRequests) {
            if (req.getStatus() != null) {
                String normalizedStatus = req.getStatus().trim().toUpperCase();
                statusDistribution.put(normalizedStatus, statusDistribution.getOrDefault(normalizedStatus, 0L) + 1);
            }
        }
        analytics.put("statusDistribution", statusDistribution);

        // 3. Xu hướng 7 ngày qua (Line Chart)
        List<Map<String, Object>> trend = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        for (int i = 6; i >= 0; i--) {
            LocalDateTime start = now.minusDays(i).withHour(0).withMinute(0).withSecond(0).withNano(0);
            LocalDateTime end = start.plusDays(1).minusNanos(1);
            
            long count = rescueRequestRepository.findByCreatedAtBetweenOrderByCreatedAtAsc(start, end).size();
            
            Map<String, Object> dayData = new HashMap<>();
            dayData.put("date", start.toLocalDate().toString());
            dayData.put("count", count);
            trend.add(dayData);
        }
        analytics.put("requestTrend", trend);

        // 4. Top vật phẩm tiêu thụ (Bar Chart)
        List<ItemConsumptionDTO> consumptionRaw = distributionDetailRepository.aggregateItemConsumption();
        List<Map<String, Object>> itemStats = (consumptionRaw != null) ? consumptionRaw.stream().limit(5).map(item -> {
            String itemId = item.get_id();
            var itemInfo = (itemId != null) ? reliefItemRepository.findById(itemId).orElse(null) : null;
            Map<String, Object> m = new HashMap<>();
            m.put("name", itemInfo != null ? itemInfo.getItemName() : "Khác");
            m.put("value", item.getTotalQuantity() != null ? item.getTotalQuantity() : 0);
            return m;
        }).collect(Collectors.toList()) : new ArrayList<>();
        analytics.put("topItems", itemStats);

        return analytics;
    }

    /**
     * Lấy danh sách các mặt hàng đã từng giao dịch tại kho của đội
     */
    public List<Map<String, Object>> getAvailableItems() {
        Map<String, String> context = getCurrentUserContext();
        if (context == null || context.containsKey("empty")) return new ArrayList<>();
        
        String warehouseId = context.get("warehouseId");
        
        // Lấy tất cả itemId duy nhất từ giao dịch kho của kho này
        Set<String> itemIds = stockTransactionRepository.findByWarehouseId(warehouseId).stream()
                .map(StockTransaction::getItemId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        
        List<Map<String, Object>> items = new ArrayList<>();
        for (String id : itemIds) {
            reliefItemRepository.findById(id).ifPresent(item -> {
                Map<String, Object> m = new HashMap<>();
                m.put("id", item.getId());
                m.put("name", item.getItemName());
                m.put("unit", item.getUnit());
                items.add(m);
            });
        }
        // Sắp xếp theo tên
        items.sort(Comparator.comparing(m -> m.get("name").toString()));
        return items;
    }


    /**
     * Lấy xu hướng xuất nhập kho (Line Chart)
     */
    public Map<String, Object> getWarehouseTrend(String period, String itemId) {
        int days = period.equalsIgnoreCase("month") ? 30 : 7;
        LocalDateTime start = LocalDateTime.now().minusDays(days).withHour(0).withMinute(0).withSecond(0).withNano(0);
        LocalDateTime end = LocalDateTime.now();

        // Lấy context để lọc
        Map<String, String> context = getCurrentUserContext();
        if (context != null && context.containsKey("empty")) return new HashMap<>(); // Trống nếu chưa có đội
        
        String warehouseId = context != null ? context.get("warehouseId") : null;

        List<StockTransaction> transactions;
        if (warehouseId != null) {
            transactions = stockTransactionRepository.findByTimestampBetweenOrderByTimestampAsc(start, end).stream()
                    .filter(tx -> warehouseId.equals(tx.getWarehouseId()))
                    .filter(tx -> itemId == null || itemId.isEmpty() || itemId.equals(tx.getItemId()))
                    .collect(Collectors.toList());
        } else {
            transactions = stockTransactionRepository.findByTimestampBetweenOrderByTimestampAsc(start, end).stream()
                    .filter(tx -> itemId == null || itemId.isEmpty() || itemId.equals(tx.getItemId()))
                    .collect(Collectors.toList());
        }
        
        Map<String, Map<String, Double>> grouped = new LinkedHashMap<>();
        
        // Khởi tạo các ngày
        for (int i = days - 1; i >= 0; i--) {
            String date = LocalDate.now().minusDays(i).toString();
            Map<String, Double> dayData = new HashMap<>();
            dayData.put("IMPORT", 0.0);
            dayData.put("EXPORT", 0.0);
            grouped.put(date, dayData);
        }

        // Điền dữ liệu thực tế
        for (StockTransaction tx : transactions) {
            String date = tx.getTimestamp().toLocalDate().toString();
            if (grouped.containsKey(date)) {
                String type = tx.getTransactionType();
                double qty = tx.getQuantity() != null ? tx.getQuantity().doubleValue() : 0.0;
                grouped.get(date).put(type, grouped.get(date).getOrDefault(type, 0.0) + qty);
            }
        }

        List<Map<String, Object>> trendData = grouped.entrySet().stream().map(entry -> {
            Map<String, Object> m = new HashMap<>();
            m.put("date", entry.getKey());
            m.put("import", entry.getValue().get("IMPORT"));
            m.put("export", entry.getValue().get("EXPORT"));
            return m;
        }).collect(Collectors.toList());

        // Xác định đơn vị (unit)
        String unit = "đơn vị";
        if (itemId != null && !itemId.isEmpty()) {
            unit = reliefItemRepository.findById(itemId).map(ReliefItem::getUnit).orElse("đơn vị");
        }

        Map<String, Object> result = new HashMap<>();
        result.put("trend", trendData);
        result.put("unit", unit);
        return result;
    }

    /**
     * Lấy thống kê mở rộng (Nhiệm vụ xong, Người cứu được)
     */
    public Map<String, Object> getExtendedStats() {
        Map<String, String> context = getCurrentUserContext();
        if (context != null && context.containsKey("empty")) {
            Map<String, Object> empty = new HashMap<>();
            empty.put("totalCompletedMissions", 0);
            empty.put("totalPeopleRescued", 0);
            return empty;
        }

        String teamId = context != null ? context.get("teamId") : null;
        Map<String, Object> stats = new HashMap<>();
        
        long totalMissions;
        if (teamId != null) {
            totalMissions = assignmentRepository.findAll().stream()
                    .filter(a -> teamId.equals(a.getTeamId()))
                    .count();
        } else {
            totalMissions = assignmentRepository.count();
        }
        stats.put("totalCompletedMissions", totalMissions);

        List<Assignment> assignments;
        if (teamId != null) {
            assignments = assignmentRepository.findAll().stream()
                    .filter(a -> teamId.equals(a.getTeamId()))
                    .collect(Collectors.toList());
        } else {
            assignments = assignmentRepository.findAll();
        }
        
        int totalPeopleRescued = assignments.stream()
                .filter(a -> "COMPLETED".equalsIgnoreCase(a.getStatus()))
                .mapToInt(a -> a.getRescuedCount() != null ? a.getRescuedCount() : 0)
                .sum();
        
        // Nếu Assignment chưa có đủ thông tin rescuedCount, lấy từ RescueRequest
        if (totalPeopleRescued == 0) {
            totalPeopleRescued = rescueRequestRepository.findByStatus("COMPLETED").stream()
                .mapToInt(r -> r.getNumberOfPeople() != null ? r.getNumberOfPeople() : 0)
                .sum();
        }
        
        stats.put("totalPeopleRescued", totalPeopleRescued);
        return stats;
    }

    /**
     * Lấy lịch sử cứu hộ
     */
    public List<Map<String, Object>> getRescueHistory() {
        Map<String, String> context = getCurrentUserContext();
        if (context != null && context.containsKey("empty")) return new ArrayList<>();

        String teamId = context != null ? context.get("teamId") : null;

        return assignmentRepository.findAll().stream()
                .filter(a -> teamId == null || teamId.equals(a.getTeamId()))
                .sorted(Comparator.comparing(Assignment::getAssignedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(20)
                .map(a -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("assignmentId", a.getId());
                    m.put("status", a.getStatus());
                    m.put("time", a.getCompletedAt() != null ? a.getCompletedAt() : a.getAssignedAt());
                    
                    String requestId = a.getRequestId();
                    var request = (requestId != null) ? rescueRequestRepository.findById(requestId).orElse(null) : null;
                    if (request != null) {
                        m.put("citizenName", request.getCitizenName());
                        m.put("location", request.getAddressText());
                        m.put("peopleCount", request.getNumberOfPeople());
                    }
                    
                    // Mức độ hoàn thành (%)
                    int completion = 0;
                    if ("COMPLETED".equalsIgnoreCase(a.getStatus())) completion = 100;
                    else if ("RESCUING".equalsIgnoreCase(a.getStatus())) completion = 70;
                    else if ("MOVING".equalsIgnoreCase(a.getStatus())) completion = 40;
                    else if ("ASSIGNED".equalsIgnoreCase(a.getStatus())) completion = 20;
                    m.put("completionLevel", completion);
                    
                    return m;
                }).collect(Collectors.toList());
    }

    /**
     * Lấy lịch sử kho (Nhập/Xuất)
     */
    public List<Map<String, Object>> getWarehouseHistory(String type) {
        Map<String, String> context = getCurrentUserContext();
        if (context != null && context.containsKey("empty")) return new ArrayList<>();

        String warehouseId = context != null ? context.get("warehouseId") : null;

        return stockTransactionRepository.findByTransactionType(type.toUpperCase()).stream()
                .filter(tx -> warehouseId == null || warehouseId.equals(tx.getWarehouseId()))
                .sorted(Comparator.comparing(StockTransaction::getTimestamp, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(20)
                .map(tx -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("id", tx.getId());
                    m.put("itemName", tx.getItemId()); // Sẽ tốt hơn nếu join với ReliefItem
                    m.put("quantity", tx.getQuantity());
                    m.put("time", tx.getTimestamp());
                    m.put("reason", tx.getReason());
                    m.put("reference", tx.getReferenceNumber());
                    m.put("source", tx.getSource());
                    
                    // Tìm tên vật phẩm nếu có thể
                    String itemId = tx.getItemId();
                    if (itemId != null) {
                        reliefItemRepository.findById(itemId).ifPresent(item -> m.put("itemName", item.getItemName()));
                    }
                    
                    return m;
                }).collect(Collectors.toList());
    }

    /**
     * Lấy lịch sử sử dụng phương tiện
     */
    public List<Map<String, Object>> getVehicleUsageHistory() {
        Map<String, String> context = getCurrentUserContext();
        if (context != null && context.containsKey("empty")) return new ArrayList<>();

        String teamId = context != null ? context.get("teamId") : null;

        return assignmentRepository.findAll().stream()
                .filter(a -> (teamId == null || teamId.equals(a.getTeamId())) && a.getVehicleIds() != null && !a.getVehicleIds().isEmpty())
                .sorted(Comparator.comparing(Assignment::getAssignedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(20)
                .map(a -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("assignmentId", a.getId());
                    m.put("time", a.getAssignedAt());
                    m.put("status", a.getStatus()); // Bao gồm cả trạng thái trả xe (COMPLETED có nghĩa là đã xong và trả xe)
                    
                    List<Map<String, String>> vehicleDetails = new ArrayList<>();
                    if (a.getVehicleIds() != null) {
                        for (String vid : a.getVehicleIds()) {
                            if (vid != null) {
                                vehiclesRepository.findById(vid).ifPresent(v -> {
                                    Map<String, String> vd = new HashMap<>();
                                    vd.put("licensePlate", v.getLicensePlate());
                                    vd.put("type", v.getVehicleType());
                                    vd.put("vStatus", v.getStatus());
                                    vehicleDetails.add(vd);
                                });
                            }
                        }
                    }
                    m.put("vehicles", vehicleDetails);
                    
                    String requestId = a.getRequestId();
                    var request = (requestId != null) ? rescueRequestRepository.findById(requestId).orElse(null) : null;
                    if (request != null) {
                        m.put("location", request.getAddressText());
                    }
                    
                    return m;
                }).collect(Collectors.toList());
    }
}