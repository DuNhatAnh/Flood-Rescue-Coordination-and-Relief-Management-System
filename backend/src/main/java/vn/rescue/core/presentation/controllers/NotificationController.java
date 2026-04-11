package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.NotificationDto;
import vn.rescue.core.application.services.SystemManagementService;
import vn.rescue.core.domain.entities.Notification;
import vn.rescue.core.presentation.common.ApiResponse;
import java.util.List;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // Cho phép Flutter kết nối
public class NotificationController {
    private final SystemManagementService systemManagementService;

    // SCRUM-56: Gửi thông báo
    @PostMapping
    public ResponseEntity<ApiResponse<Notification>> sendNotification(@RequestBody NotificationDto dto) {
        Notification notification = systemManagementService.sendNotification(dto);
        return ResponseEntity.ok(ApiResponse.success(notification, "Notification sent successfully"));
    }

    // SCRUM-57: Lấy thông báo theo User (Dùng cho Mobile App)
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<Notification>>> getUserNotifications(@PathVariable String userId) {
        List<Notification> notifications = systemManagementService.getUserNotifications(userId);
        return ResponseEntity.ok(ApiResponse.success(notifications, "User notifications retrieved"));
    }

    // Lấy tất cả thông báo (Dùng cho Admin Web)
    @GetMapping
    public ResponseEntity<ApiResponse<List<Notification>>> getAllNotifications() {
        List<Notification> allNotifications = systemManagementService.getAllNotifications();
        return ResponseEntity.ok(ApiResponse.success(allNotifications, "All notifications retrieved"));
    }

    // Bổ sung: Đánh dấu đã đọc (Rất quan trọng cho trải nghiệm người dùng)
    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(@PathVariable String id) {
        systemManagementService.markNotificationAsRead(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Notification marked as read"));
    }

    // Đếm số thông báo chưa đọc
    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount(@RequestParam String userId) {
        long count = systemManagementService.getUnreadNotificationCount(userId);
        return ResponseEntity.ok(ApiResponse.success(count, "Unread count retrieved"));
    }

    // Xóa tất cả thông báo của User
    @DeleteMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<Void>> deleteAll(@PathVariable String userId) {
        systemManagementService.deleteAllNotifications(userId);
        return ResponseEntity.ok(ApiResponse.success(null, "All notifications deleted"));
    }
}