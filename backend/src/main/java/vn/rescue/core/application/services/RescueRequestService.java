package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.RescueRequestDto;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;

import java.time.LocalDateTime;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class RescueRequestService {

    private final RescueRequestRepository rescueRequestRepository;
    private final RequestStatusHistoryRepository statusHistoryRepository;
    private final vn.rescue.core.domain.repositories.SafetyReportRepository safetyReportRepository;

    @Transactional
    public RescueRequest createRequest(RescueRequestDto dto) {
        // ... (existing code stays same)
        RescueRequest request = new RescueRequest();
        request.setCustomId(generateCustomId());
        request.setCitizenName(dto.getCitizenName());
        request.setCitizenPhone(dto.getCitizenPhone());
        request.setLocationLat(dto.getLocationLat());
        request.setLocationLng(dto.getLocationLng());
        request.setAddressText(dto.getAddressText());
        request.setDescription(dto.getDescription());
        request.setUrgencyLevel(dto.getUrgencyLevel());
        request.setNumberOfPeople(dto.getNumberOfPeople() != null ? dto.getNumberOfPeople() : 1);
        request.setStatus("PENDING");
        request.setCreatedAt(LocalDateTime.now());

        RescueRequest savedRequest = rescueRequestRepository.save(request);

        // Tự động ghi log trạng thái ban đầu
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRequestId(savedRequest.getId());
        history.setStatus("PENDING");
        history.setNote("Yêu cầu mới được tạo từ người dân");
        statusHistoryRepository.save(history);

        return savedRequest;
    }

    public String generateCustomId() {
        long count = rescueRequestRepository.countByCustomIdIsNotNull();
        return String.format("RES-%04d", count + 1);
    }

    public RescueRequest getById(String id) {
        if (id == null) {
            throw new IllegalArgumentException("ID cannot be null");
        }
        
        // Try to find by ID first, then by customId
        return rescueRequestRepository.findById(id)
                .or(() -> rescueRequestRepository.findByCustomId(id))
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu với ID: " + id));
    }

    public Map<String, Long> getStats() {
        return Map.of(
            "pending", rescueRequestRepository.countByStatus("PENDING"),
            "completed", rescueRequestRepository.countByStatus("COMPLETED"),
            "peopleSupported", 0L, // To be implemented later with actual people count
            "safeReports", safetyReportRepository.count()
        );
    }

    public java.util.List<RescueRequest> getAll() {
        return rescueRequestRepository.findAll();
    }
}
