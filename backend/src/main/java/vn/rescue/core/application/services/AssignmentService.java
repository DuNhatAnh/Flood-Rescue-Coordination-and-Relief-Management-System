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

        // 2. Kiểm tra phương tiện có tồn tại và đang rảnh không
        Vehicles vehicle = vehicleRepo.findById(requestDto.getVehicleId())
                .orElseThrow(() -> new RuntimeException("Phương tiện không tồn tại!"));

        if (!"AVAILABLE".equalsIgnoreCase(vehicle.getStatus())) {
            throw new RuntimeException("Phương tiện hiện đang bận hoặc bảo trì.");
        }

        // 3. Tạo bản ghi Assignment mới
        Assignment assignment = new Assignment();
        assignment.setRequestId(rescueRequest.getId());
        assignment.setVehicleId(vehicle.getId());
        assignment.setTeamId(vehicle.getTeamId());
        assignment.setStatus("ACTIVE");
        assignment.setAssignedAt(LocalDateTime.now());
        Assignment savedAssignment = assignmentRepo.save(assignment);

        // 4. Cập nhật trạng thái RescueRequest
        rescueRequest.setStatus("ASSIGNED");
        rescueRequest.setTeamId(vehicle.getTeamId());
        requestRepo.save(rescueRequest);

        // 5. Cập nhật trạng thái Vehicle
        vehicle.setStatus("BUSY");
        vehicleRepo.save(vehicle);

        // 6. Ghi log lịch sử trạng thái
        RequestStatusHistory history = new RequestStatusHistory();
        history.setRequestId(rescueRequest.getId());
        history.setStatus("ASSIGNED");
        history.setNote("Điều động xe " + vehicle.getLicensePlate() + ". Ghi chú: " + requestDto.getNote());
        history.setCreatedAt(LocalDateTime.now());
        historyRepo.save(history);

        // 7. Trả về Response
        return AssignmentResponse.builder()
                .assignmentId(savedAssignment.getId())
                .requestId(rescueRequest.getId())
                .customId(rescueRequest.getCustomId())
                .citizenName(rescueRequest.getCitizenName())
                .vehicleId(vehicle.getId())
                .licensePlate(vehicle.getLicensePlate())
                .vehicleType(vehicle.getVehicleType())
                .teamId(vehicle.getTeamId())
                .status("SUCCESS")
                .assignedAt(savedAssignment.getAssignedAt())
                .message("Đã điều động phương tiện thành công.")
                .build();
    }
}