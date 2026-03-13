package vn.rescue.core.application.services;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.Role;

import java.util.Arrays;
import java.util.List;

@Service
@Slf4j
public class SystemManagementService {

    public void logAction(String userId, String action, String detail) {
        log.info("USER [{}]: ACTION [{}] - DETAIL: {}", userId, action, detail);
        // Có thể lưu vào DB SystemLog nếu cần
    }

    public List<Role> getAllRoles() {
        return Arrays.asList(
            new Role("ADMIN", "Quản trị viên", "Toàn quyền hệ thống"),
            new Role("COORDINATOR", "Điều phối viên", "Quản lý yêu cầu và phân công"),
            new Role("RESCUE_STAFF", "Nhân viên cứu hộ", "Thực hiện nhiệm vụ cứu trợ"),
            new Role("CITIZEN", "Người dân", "Gửi yêu cầu và báo an toàn")
        );
    }
}
