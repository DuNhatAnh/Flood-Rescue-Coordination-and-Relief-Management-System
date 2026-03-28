package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.AssignmentRequest;
import vn.rescue.core.application.dto.AssignmentResponse;
import vn.rescue.core.domain.entities.*;
import vn.rescue.core.domain.repositories.*;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
public class AssignmentService {

    private final AssignmentRepository assignmentRepo;
    private final RescueRequestRepository requestRepo;
    private final VehiclesRepository vehicleRepo;
    private final RequestStatusHistoryRepository historyRepo;

    @Transactional
    public AssignmentResponse assignVehicleToRequest(AssignmentRequest requestDto) {

        // 1. Kiểm tra nhiệm vụ có tồn tại và đang chờ không
        RescueRequest rescueRequest = requestRepo.findById(requestDto.getRequestId())
                .orElseThrow(() -> new RuntimeException("Nhiệm vụ không tồn tại!"));

        if ("ASSIGNED".equals(rescueRequest.getStatus())) {
            throw new RuntimeException("Nhiệm vụ này đã được gán cho đội khác.");
        }

        // 2. Kiểm tra danh sách phương tiện
        java.util.List<String> vehicleIds = requestDto.getVehicleIds();
        if (vehicleIds == null || vehicleIds.isEmpty()) {
            throw new RuntimeException("Chưa chọn phương tiện nào!");
        }

        java.util.List<Vehicles> vehicles = new java.util.ArrayList<>();
        for (String vId : vehicleIds) {
            Vehicles v = vehicleRepo.findById(vId)
                    .orElseThrow(() -> new RuntimeException("Phương tiện " + vId + " không tồn tại!"));
            if (!"AVAILABLE".equalsIgnoreCase(v.getStatus())) {
                throw new RuntimeException("Phương tiện " + v.getLicensePlate() + " hiện đang bận hoặc bảo trì.");
            }
            vehicles.add(v);
        }

        // 3. Tạo bản ghi Assignment mới
        Assignment assignment = new Assignment();
        assignment.setRequestId(rescueRequest.getId());
        assignment.setVehicleIds(vehicleIds);
        assignment.setTeamId(requestDto.getTeamId());
        assignment.setStatus("ACTIVE");
        assignment.setAssignedAt(LocalDateTime.now());
        Assignment savedAssignment = assignmentRepo.save(assignment);

        // 4. Cập nhật trạng thái RescueRequest
        rescueRequest.setStatus("ASSIGNED");
        rescueRequest.setTeamId(requestDto.getTeamId());
        requestRepo.save(rescueRequest);

        // 5. Cập nhật trạng thái các Vehicle
        for (Vehicles v : vehicles) {
            v.setStatus("BUSY");
            vehicleRepo.save(v);
        }

        // 6. Ghi log lịch sử trạng thái
        String vehicleInfo = vehicles.stream().map(Vehicles::getLicensePlate).collect(java.util.stream.Collectors.joining(", "));
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRequestId(rescueRequest.getId());
        history.setStatus("ASSIGNED");
        history.setNote("Điều động các xe: " + vehicleInfo + ". Ghi chú: " + (requestDto.getNote() != null ? requestDto.getNote() : ""));
        history.setCreatedAt(LocalDateTime.now());
        historyRepo.save(history);

        // 7. Trả về Response
        // 7. Trả về Response
        return AssignmentResponse.builder()
                .assignmentId(savedAssignment.getId())
                .requestId(rescueRequest.getId())
                .customId(rescueRequest.getCustomId())
                .citizenName(rescueRequest.getCitizenName())
                .vehicleIds(vehicleIds)
                .licensePlate(vehicleInfo)
                .vehicleType(vehicles.stream().map(Vehicles::getVehicleType).distinct().collect(java.util.stream.Collectors.joining(", ")))
                .teamId(requestDto.getTeamId())
                .status("SUCCESS")
                .assignedAt(savedAssignment.getAssignedAt())
                .message("Đã điều động " + vehicles.size() + " phương tiện thành công.")
                .build();
    }
}