package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.RescueRequestDto;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;

@Service
@RequiredArgsConstructor
public class RescueRequestService {

    private final RescueRequestRepository rescueRequestRepository;
    private final RequestStatusHistoryRepository statusHistoryRepository;

    @Transactional
    public RescueRequest createRequest(RescueRequestDto dto) {
        RescueRequest request = new RescueRequest();
        request.setCitizenName(dto.getCitizenName());
        request.setCitizenPhone(dto.getCitizenPhone());
        request.setLocationLat(dto.getLocationLat());
        request.setLocationLng(dto.getLocationLng());
        request.setAddressText(dto.getAddressText());
        request.setDescription(dto.getDescription());
        request.setUrgencyLevel(dto.getUrgencyLevel());
        request.setNumberOfPeople(dto.getNumberOfPeople() != null ? dto.getNumberOfPeople() : 1);
        request.setStatus("PENDING");

        RescueRequest savedRequest = rescueRequestRepository.save(request);

        // Tự động ghi log trạng thái ban đầu
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRescueRequest(savedRequest);
        history.setStatus("PENDING");
        history.setNote("Yêu cầu mới được tạo từ người dân");
        statusHistoryRepository.save(history);

        return savedRequest;
    }

    public RescueRequest getById(Long id) {
        return rescueRequestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu với ID: " + id));
    }
}
