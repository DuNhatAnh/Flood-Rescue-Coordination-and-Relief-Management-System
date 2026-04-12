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
    /**
     * Ghi log hành động và tự động tạo thông báo nếu thuộc module quan trọng
     */
    public void logAction(String userId, String action, String details, String module) {
        // Ghi log vào console để debug
        log.info("USER [{}]: MODULE [{}] - ACTION [{}] - DETAIL: {}", userId, module, action, details);

        // 1. Lưu Log hệ thống vào Database
        SystemLog logEntry = SystemLog.builder()
                .userId(userId)
                .action(action)
                .module(module)
                .details(details)
                .createdAt(LocalDateTime.now())
                .build();
        systemLogRepository.save(logEntry);

        // 2. Tự động tạo thông báo (Đã vô hiệu hóa để tránh làm phiền, chuyển sang thông báo trúng đích trong Service)
        /*
        if (module != null && (module.equals("RESCUE") || module.equals("INVENTORY"))) {
            ...
        }
        */
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
        long totalV = vehiclesRepository.countByWarehouseId(warehouseId);
        long availableV = vehiclesRepository.countByWarehouseIdAndStatusIgnoreCase(warehouseId, "AVAILABLE");

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

    /**
     * Lấy toàn bộ danh sách thông báo (Dùng cho Admin)
     */
    public List<Notification> getAllNotifications() {
        return notificationRepository.findAllByOrderByCreatedAtDesc();
    }

    /**
     * Gửi thông báo thủ công từ DTO
     */
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

    /**
     * Đánh dấu đã đọc dựa trên ID thông báo
     * Cập nhật: Sử dụng method markAsRead() từ Entity
     */
    public void markNotificationAsRead(String notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.markAsRead(); // Gọi hàm xử lý logic bên trong Entity Notification
            notificationRepository.save(n);
            log.info("Notification {} marked as read", notificationId);
        });
    }

    /**
     * Lấy thông báo riêng cho từng User hoặc thông báo chung (UserId is Null)
     */
    public List<Notification> getUserNotifications(String userId) {
        // Chỉ lấy thông báo đích danh cho User này để tránh nhiễu và cho phép xóa sạch hoàn toàn
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    /**
     * Đếm số lượng thông báo chưa đọc (Bao gồm thông báo nặc danh/broadcast)
     */
    public long getUnreadNotificationCount(String userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    /**
     * Xóa toàn bộ thông báo của 1 user
     */
    public void deleteAllNotifications(String userId) {
        notificationRepository.deleteByUserId(userId);
        log.info("All notifications for user {} have been deleted", userId);
    }

    // --- CẤU HÌNH & QUYỀN ---
    public SystemConfig updateConfig(String key, String value) {
        SystemConfig config = systemConfigRepository.findByKey(key)
                .orElse(SystemConfig.builder().key(key).build());
        config.setValue(value);
        return systemConfigRepository.save(config);
    }

    public List<SystemConfig> getAllConfigs() {
        return systemConfigRepository.findAll();
    }

    public List<Role> getAllRoles() {
        return roleRepository.findAll();
    }
}