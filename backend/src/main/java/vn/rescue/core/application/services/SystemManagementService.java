package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.*;
import vn.rescue.core.domain.repositories.*;
import vn.rescue.core.application.dto.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SystemManagementService {
    private final RoleRepository roleRepository;
    private final SystemLogRepository systemLogRepository;
    private final NotificationRepository notificationRepository;
    private final SystemConfigRepository systemConfigRepository;
    private final InventoryRepository inventoryRepository;
    private final VehiclesRepository vehiclesRepository;

    // --- SCRUM-54: NHẬT KÝ HỆ THỐNG ---
    public void logAction(String userId, String action, String details, String module) {
        log.info("USER [{}]: MODULE [{}] - ACTION [{}] - DETAIL: {}", userId, module, action, details);
        SystemLog logEntry = SystemLog.builder()
                .userId(userId)
                .action(action)
                .module(module)
                .details(details)
                .createdAt(LocalDateTime.now())
                .build();
        systemLogRepository.save(logEntry);
    }

    // Overload cho các trường hợp log đơn giản hơn
    public void logAction(String userId, String action, String details) {
        logAction(userId, action, details, "SYSTEM");
    }

    public List<SystemLog> getAllLogs() {
        return systemLogRepository.findAllByOrderByCreatedAtDesc();
    }

    // --- SCRUM-55: THỐNG KÊ DASHBOARD ---
    public DashboardStatsResponse getDashboardStats(String warehouseId) {
        // 1. Thống kê phương tiện
        long totalV = vehiclesRepository.countByWarehouseId(warehouseId);
        long availableV = vehiclesRepository.countByWarehouseIdAndStatusIgnoreCase(warehouseId, "AVAILABLE");

        // 2. Thống kê hàng hóa và cảnh báo hàng sắp hết
        List<Inventory> lowStockEntities = inventoryRepository.findLowStockItemsByWarehouse(warehouseId);
        List<InventoryResponse> lowStockDtos = lowStockEntities.stream()
                .map(i -> InventoryResponse.builder()
                        .itemId(i.getItemId())
                        .itemName(i.getItemName())
                        .quantity(i.getQuantity())
                        .unit(i.getUnit())
                        .minThreshold(i.getMinThreshold())
                        .status("LOW_STOCK")
                        .build())
                .collect(Collectors.toList());

        return DashboardStatsResponse.builder()
                .totalVehicles(totalV)
                .availableVehicles(availableV)
                .lowStockItems(lowStockDtos)
                .build();
    }

    // --- SCRUM-56 & 57: THÔNG BÁO ---

    // MỚI: Sửa lỗi "cannot find symbol" trong Controller
    public List<Notification> getAllNotifications() {
        return notificationRepository.findAllByOrderByCreatedAtDesc();
    }

    public Notification sendNotification(NotificationDto dto) {
        Notification notification = Notification.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .type(dto.getType())
                .priority(dto.getPriority())
                .userId(dto.getUserId())
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();
        return notificationRepository.save(notification);
    }

    public void markNotificationAsRead(String notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setRead(true); // Đảm bảo field trong Entity là isRead hoặc read tương ứng với setter
            notificationRepository.save(n);
        });
    }

    public List<Notification> getUserNotifications(String userId) {
        return notificationRepository.findByUserIdOrUserIdIsNullOrderByCreatedAtDesc(userId);
    }

    // --- CẤU HÌNH & QUYỀN ---
    public SystemConfig updateConfig(String key, String value) {
        SystemConfig config = systemConfigRepository.findByKey(key)
                .orElse(SystemConfig.builder().key(key).build());
        config.setValue(value);
        return systemConfigRepository.save(config);
    }

    public List<Role> getAllRoles() {
        return roleRepository.findAll();
    }
}