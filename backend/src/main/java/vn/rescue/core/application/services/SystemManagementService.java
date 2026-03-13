package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.*;
import vn.rescue.core.domain.repositories.*;
import vn.rescue.core.application.dto.NotificationDto;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class SystemManagementService {
    private final RoleRepository roleRepository;
    private final SystemLogRepository systemLogRepository;
    private final NotificationRepository notificationRepository;
    private final SystemConfigRepository systemConfigRepository;

    public void logAction(String userId, String action, String details) {
        log.info("USER [{}]: ACTION [{}] - DETAIL: {}", userId, action, details);
        SystemLog logEntry = SystemLog.builder()
                .userId(userId)
                .action(action)
                .details(details)
                .createdAt(LocalDateTime.now())
                .build();
        systemLogRepository.save(logEntry);
    }

    public List<SystemLog> getAllLogs() {
        return systemLogRepository.findAll();
    }

    public Notification sendNotification(NotificationDto dto) {
        Notification notification = Notification.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .type(dto.getType())
                .userId(dto.getUserId())
                .createdAt(LocalDateTime.now())
                .build();
        return notificationRepository.save(notification);
    }

    public List<Notification> getUserNotifications(String userId) {
        return notificationRepository.findByUserIdOrUserIdIsNullOrderByCreatedAtDesc(userId);
    }

    public List<Notification> getAllNotifications() {
        return notificationRepository.findAll();
    }

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
