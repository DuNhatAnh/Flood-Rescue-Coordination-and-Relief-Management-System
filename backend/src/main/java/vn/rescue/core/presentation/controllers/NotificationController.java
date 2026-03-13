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
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final SystemManagementService systemManagementService;

    @PostMapping
    public ResponseEntity<ApiResponse<Notification>> sendNotification(@RequestBody NotificationDto dto) {
        Notification notification = systemManagementService.sendNotification(dto);
        return ResponseEntity.ok(ApiResponse.success(notification, "Notification sent successfully"));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<Notification>>> getUserNotifications(@PathVariable String userId) {
        List<Notification> notifications = systemManagementService.getUserNotifications(userId);
        return ResponseEntity.ok(ApiResponse.success(notifications, "User notifications retrieved"));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Notification>>> getAllNotifications() {
        return ResponseEntity.ok(ApiResponse.success(systemManagementService.getAllNotifications(), "All notifications retrieved"));
    }
}
