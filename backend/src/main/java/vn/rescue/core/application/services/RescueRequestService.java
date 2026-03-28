package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.RescueRequestDto;
import vn.rescue.core.application.dto.UpdateRescueRequestStatusDto;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.SafetyReportRepository;

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
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu với ID: " + id));
    }

    public Map<String, Long> getStats() {
        return Map.of(
                "pending", rescueRequestRepository.countByStatus("PENDING"),
                "completed", rescueRequestRepository.countByStatus("COMPLETED"),
                "safeReports", safetyReportRepository.count()
        );
    }

    public List<RescueRequest> getAll() {
        return rescueRequestRepository.findAll();
    }
}