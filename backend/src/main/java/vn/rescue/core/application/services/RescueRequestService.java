package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.RescueRequestDto;
import vn.rescue.core.application.dto.UpdateRescueRequestStatusDto;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.SafetyReportRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class RescueRequestService {

    private final RescueRequestRepository rescueRequestRepository;
    private final RequestStatusHistoryRepository statusHistoryRepository;
    private final SafetyReportRepository safetyReportRepository;

    // TIÊM SERVICE QUẢN LÝ HỆ THỐNG ĐỂ TẠO THÔNG BÁO TỰ ĐỘNG
    private final SystemManagementService systemManagementService;

    /**
     * SCRUM-56: Tạo yêu cầu cứu hộ và tự động bắn thông báo cho Điều phối viên
     */
    @Transactional
    public RescueRequest createRequest(RescueRequestDto dto) {
        if (dto.getLocationLat() != null && (dto.getLocationLat() < 8.18 || dto.getLocationLat() > 23.39)) {
            throw new BadRequestException("Tọa độ vĩ độ nằm ngoài lãnh thổ Việt Nam (8.18 - 23.39)");
        }
        if (dto.getLocationLng() != null && (dto.getLocationLng() < 102.14 || dto.getLocationLng() > 109.46)) {
            throw new BadRequestException("Tọa độ kinh độ nằm ngoài lãnh thổ Việt Nam (102.14 - 109.46)");
        }
        RescueRequest request = new RescueRequest();

        // Tạo Custom ID (VD: RES-0001)
        String customId = generateCustomId();
        request.setCustomId(customId);

        request.setCitizenName(dto.getCitizenName());
        request.setCitizenPhone(dto.getCitizenPhone());
        request.setLocationLat(dto.getLocationLat());
        request.setLocationLng(dto.getLocationLng());
        request.setAddressText(dto.getAddressText());
        request.setDescription(dto.getDescription());
        request.setUrgencyLevel(dto.getUrgencyLevel() != null ? dto.getUrgencyLevel() : "NORMAL");
        request.setNumberOfPeople(dto.getNumberOfPeople() != null ? dto.getNumberOfPeople() : 1);
        request.setStatus("PENDING");
        request.setCreatedAt(LocalDateTime.now());

        RescueRequest savedRequest = rescueRequestRepository.save(request);

        // 1. Ghi log trạng thái vào lịch sử yêu cầu (Database Local)
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRequestId(savedRequest.getId());
        history.setStatus("PENDING");
        history.setNote("Yêu cầu mới được tạo từ người dân");
        history.setCreatedAt(LocalDateTime.now());
        statusHistoryRepository.save(history);

        // 2. KÍCH HOẠT THÔNG BÁO HỆ THỐNG (Bắn sang Flutter Dashboard)
        // Khi truyền module là "RESCUE", SystemManagementService sẽ tự tạo 1 bản ghi Notification
        systemManagementService.logAction(
                "CITIZEN", // Người thực hiện
                "YÊU CẦU CỨU HỘ MỚI", // Hành động
                "[" + customId + "] Có yêu cầu mới từ " + dto.getCitizenName() + " tại " + dto.getAddressText(), // Chi tiết
                "RESCUE" // Module kích hoạt Notification
        );

        return savedRequest;
    }

    /**
     * Cập nhật trạng thái và thông báo cho hệ thống
     */
    @Transactional
    public RescueRequest updateStatus(String id, UpdateRescueRequestStatusDto dto) {
        RescueRequest request = getById(id);
        String oldStatus = request.getStatus();

        request.setStatus(dto.getStatus());
        request.setNote(dto.getNote());
        RescueRequest savedRequest = rescueRequestRepository.save(request);

        // 1. Ghi log lịch sử thay đổi trạng thái
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRequestId(savedRequest.getId());
        history.setStatus(dto.getStatus());
        history.setNote(dto.getNote());
        history.setCreatedAt(LocalDateTime.now());
        statusHistoryRepository.save(history);

        // 2. TỰ ĐỘNG TẠO THÔNG BÁO CẬP NHẬT TRẠNG THÁI
        systemManagementService.logAction(
                "ADMIN",
                "CẬP NHẬT TRẠNG THÁI",
                "Yêu cầu #" + request.getCustomId() + " đã chuyển từ " + oldStatus + " sang " + dto.getStatus(),
                "RESCUE"
        );

        return savedRequest;
    }

    /**
     * Tạo mã ID tự động tăng (VD: 0001, 0002...)
     */
    private String generateCustomId() {
        long count = rescueRequestRepository.count();
        return String.format("%04d", count + 1);
    }

    public RescueRequest getById(String id) {
        if (id == null) {
            throw new IllegalArgumentException("ID cannot be null");
        }

        return rescueRequestRepository.findById(id)
                .or(() -> rescueRequestRepository.findFirstByCustomId(id))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy yêu cầu với ID: " + id));
    }

    public Map<String, Long> getStats() {
        long pending = rescueRequestRepository.countByStatus("PENDING");
        long completed = rescueRequestRepository.countByStatus("COMPLETED");
        long safeReports = safetyReportRepository.count();
        
        // Tính tổng số nhân khẩu được hỗ trợ (sum của number_of_people)
        long peopleSupported = rescueRequestRepository.findByStatus("COMPLETED")
                .stream()
                .mapToLong(r -> r.getNumberOfPeople() != null ? r.getNumberOfPeople() : 1)
                .sum();

        return Map.of(
                "pending", pending,
                "completed", completed,
                "peopleSupported", peopleSupported,
                "safeReports", safeReports
        );
    }

    /**
     * Xác nhận an toàn từ phía người dân (Dual-Verification)
     */
    @Transactional
    public RescueRequest confirmSafety(String id) {
        RescueRequest request = getById(id);
        
        // Cho phép xác nhận an toàn khi đã xong cứu hộ (REPORTED) hoặc đã hoàn thành (COMPLETED)
        if (!"COMPLETED".equalsIgnoreCase(request.getStatus()) && !"REPORTED".equalsIgnoreCase(request.getStatus())) {
            throw new vn.rescue.core.presentation.exceptions.BadRequestException("Chỉ có thể xác nhận an toàn cho các yêu cầu đã báo cáo hoàn thành cứu hộ!");
        }

        request.setCitizenVerified(true);
        request.setCitizenVerifiedAt(LocalDateTime.now());
        RescueRequest saved = rescueRequestRepository.save(request);

        // Ghi log lịch sử
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRequestId(saved.getId());
        history.setStatus("VERIFIED_SAFE");
        history.setNote("Người dân xác nhận đã an toàn (Báo cáo kép)");
        history.setCreatedAt(LocalDateTime.now());
        statusHistoryRepository.save(history);

        return saved;
    }

    /**
     * Tự động xác minh an toàn sau 48 giờ nếu người dân không phản hồi
     * Chạy mỗi giờ một lần
     */
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void autoVerifyOldRequests() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(24);
        List<RescueRequest> oldRequests = rescueRequestRepository.findAll().stream()
                .filter(r -> "REPORTED".equalsIgnoreCase(r.getStatus()) 
                        && r.getReportedAt() != null 
                        && r.getReportedAt().isBefore(threshold)) 
                .toList();

        for (RescueRequest request : oldRequests) {
            request.setStatus("COMPLETED"); // Tự động hoàn thành
            request.setCitizenVerified(true);
            request.setCitizenVerifiedAt(LocalDateTime.now());
            rescueRequestRepository.save(request);

            RequestStatusHistory history = new RequestStatusHistory();
            history.setRequestId(request.getId());
            history.setStatus("COMPLETED");
            history.setNote("Hệ thống tự động hoàn thành sau 24 giờ chờ duyệt");
            history.setCreatedAt(LocalDateTime.now());
            statusHistoryRepository.save(history);

            // Thông báo cho Điều phối viên
            systemManagementService.logAction(
                "SYSTEM",
                "TỰ ĐỘNG HOÀN THÀNH",
                "Yêu cầu #" + request.getCustomId() + " đã tự động hoàn thành sau 24 giờ không có phản hồi.",
                "RESCUE"
            );
        }
        
        if (!oldRequests.isEmpty()) {
            System.out.println("DEBUG: Auto-completed " + oldRequests.size() + " requests.");
        }
    }

    public void linkSafetyReportByPhone(String phone) {
        if (phone == null || phone.isEmpty()) return;
        
        // Chuẩn hóa số điện thoại: chỉ lấy các chữ số
        String normalizedPhone = phone.replaceAll("\\D", "");
        
        // Tìm các yêu cầu có liên quan
        List<RescueRequest> requests = rescueRequestRepository.findAll().stream()
                .filter(r -> {
                    if (r.getCitizenPhone() == null) return false;
                    String rPhone = r.getCitizenPhone().replaceAll("\\D", "");
                    // So khớp phần đuôi (đề phòng mã quốc gia)
                    return rPhone.endsWith(normalizedPhone) || normalizedPhone.endsWith(rPhone);
                })
                .filter(r -> List.of("RESCUING", "RETURNING", "IN_PROGRESS", "REPORTED", "COMPLETED").contains(r.getStatus().toUpperCase()))
                .toList();

        for (RescueRequest request : requests) {
            if (!request.isCitizenVerified()) {
                request.setCitizenVerified(true);
                request.setCitizenVerifiedAt(LocalDateTime.now());
                rescueRequestRepository.save(request);

                // Ghi log lịch sử
                RequestStatusHistory history = new RequestStatusHistory();
                history.setRequestId(request.getId());
                history.setStatus("CITIZEN_SAFE_REPORTED");
                history.setNote("Hệ thống tự động xác nhận an toàn qua tính năng Báo an toàn chung (SĐT: " + phone + ")");
                history.setCreatedAt(LocalDateTime.now());
                statusHistoryRepository.save(history);

                // Thông báo cho Điều phối viên
                systemManagementService.logAction(
                    "SYSTEM",
                    "DÂN BÁO AN TOÀN",
                    "Yêu cầu #" + request.getCustomId() + " vừa được người dân xác nhận an toàn thông qua tính năng Báo an toàn chung.",
                    "RESCUE"
                );
            }
        }
    }

    public static final java.util.Set<String> VALID_STATUSES = java.util.Set.of(
            "PENDING", "VERIFIED", "ASSIGNED", "IN_PROGRESS", "RESCUING",
            "RETURNING", "REPORTED", "COMPLETED", "CANCELLED", "REJECTED"
    );

    public List<RescueRequest> getRequests(String status, String district) {
        if (status != null && !status.isBlank()) {
            String upperStatus = status.trim().toUpperCase();
            if (!VALID_STATUSES.contains(upperStatus)) {
                throw new vn.rescue.core.presentation.exceptions.BadRequestException(
                        "Trạng thái không hợp lệ: " + status + ". Trạng thái hợp lệ gồm: " + VALID_STATUSES);
            }
        }

        List<RescueRequest> requests = rescueRequestRepository.findAll();

        if (status != null && !status.isBlank()) {
            String targetStatus = status.trim();
            requests = requests.stream()
                    .filter(r -> r.getStatus() != null && r.getStatus().equalsIgnoreCase(targetStatus))
                    .toList();
        }

        if (district != null && !district.isBlank()) {
            String targetDistrict = district.trim().toLowerCase();
            requests = requests.stream()
                    .filter(r -> r.getAddressText() != null && r.getAddressText().toLowerCase().contains(targetDistrict))
                    .toList();
        }

        return requests;
    }

    @Transactional
    public RescueRequest cancelRequest(String id, String reason) {
        RescueRequest request = getById(id);

        if ("COMPLETED".equalsIgnoreCase(request.getStatus())) {
            throw new vn.rescue.core.presentation.exceptions.BadRequestException(
                    "Không thể hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED!");
        }

        if ("CANCELLED".equalsIgnoreCase(request.getStatus())) {
            throw new vn.rescue.core.presentation.exceptions.BadRequestException(
                    "Yêu cầu cứu hộ này đã ở trạng thái CANCELLED trước đó!");
        }

        String cancelReason = (reason != null && !reason.isBlank())
                ? reason.trim()
                : "Người dân tự hủy yêu cầu khi nước đã rút";

        request.setStatus("CANCELLED");
        request.setNote(cancelReason);
        RescueRequest savedRequest = rescueRequestRepository.save(request);

        // Ghi log lịch sử thay đổi trạng thái
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRequestId(savedRequest.getId());
        history.setStatus("CANCELLED");
        history.setNote(cancelReason);
        history.setCreatedAt(LocalDateTime.now());
        statusHistoryRepository.save(history);

        // Kích hoạt thông báo hệ thống
        systemManagementService.logAction(
                "CITIZEN",
                "HỦY YÊU CẦU CỨU HỘ",
                "Yêu cầu #" + savedRequest.getCustomId() + " đã được người dân hủy. Lý do: " + cancelReason,
                "RESCUE"
        );

        return savedRequest;
    }

    public List<RescueRequest> getAll() {
        return rescueRequestRepository.findAll();
    }
}