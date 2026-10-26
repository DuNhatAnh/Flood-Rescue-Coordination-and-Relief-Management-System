package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.AssignmentRequest;
import vn.rescue.core.application.dto.VehicleRequest;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.repositories.AssignmentRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.Collections;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("Sprint 2 Unit Tests: Fix Bug API Module Team, Vehicles, Assignment")
class Sprint2ModuleFixesTest {

    // --- Mocks cho RescueCoordinationService (Module Team) ---
    @Mock
    private RescueTeamRepository rescueTeamRepository;

    @InjectMocks
    private RescueCoordinationService rescueCoordinationService;

    // --- Mocks cho VehiclesService (Module Vehicles) ---
    @Mock
    private VehiclesRepository vehiclesRepository;

    @Mock
    private SystemManagementService systemManagementService;

    @InjectMocks
    private VehiclesService vehiclesService;

    // --- Mocks cho AssignmentService (Module Assignment) ---
    @Mock
    private AssignmentRepository assignmentRepo;

    @Mock
    private RescueRequestRepository requestRepo;

    @InjectMocks
    private AssignmentService assignmentService;

    // =========================================================================
    // 1. MODULE TEAM: Sửa lỗi BUG-TEAM-01
    // =========================================================================
    @Test
    @DisplayName("BUG-TEAM-01: Cập nhật đội cứu hộ với ID không tồn tại -> Ném ResourceNotFoundException (404)")
    void testUpdateTeam_WhenTeamNotFound_ShouldThrowResourceNotFoundException() {
        String nonExistentTeamId = "non-existent-team-id";
        when(rescueTeamRepository.findById(nonExistentTeamId)).thenReturn(Optional.empty());

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            rescueCoordinationService.updateTeam(nonExistentTeamId, "Tên Đội Mới");
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy đội cứu hộ với ID: " + nonExistentTeamId));
        verify(rescueTeamRepository, times(1)).findById(nonExistentTeamId);
        verify(rescueTeamRepository, never()).save(any());
    }

    // =========================================================================
    // 2. MODULE VEHICLES: Bắt lỗi trùng biển số xe khi tạo mới
    // =========================================================================
    @Test
    @DisplayName("BUG-VEHICLE-01: Tạo mới phương tiện với biển số đã tồn tại -> Ném BadRequestException (400)")
    void testCreateVehicle_WhenDuplicateLicensePlate_ShouldThrowBadRequestException() {
        String duplicatePlate = "29A-99999";
        VehicleRequest request = new VehicleRequest();
        request.setLicensePlate(duplicatePlate);
        request.setVehicleType("CANOE");

        when(vehiclesRepository.existsByLicensePlate(duplicatePlate)).thenReturn(true);

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            vehiclesService.createVehicle(request, "user-admin-1");
        });

        assertTrue(exception.getMessage().contains("Biển số xe đã tồn tại trong hệ thống: " + duplicatePlate));
        verify(vehiclesRepository, times(1)).existsByLicensePlate(duplicatePlate);
        verify(vehiclesRepository, never()).save(any());
    }

    // =========================================================================
    // 3. MODULE ASSIGNMENT: Chặn điều phối xe không ở trạng thái AVAILABLE
    // =========================================================================
    @Test
    @DisplayName("BUG-ASSIGNMENT-01: Điều phối phương tiện đang BUSY hoặc MAINTENANCE -> Ném BadRequestException (400)")
    void testAssignVehicle_WhenVehicleNotAvailable_ShouldThrowBadRequestException() {
        String requestId = "REQ-001";
        String vehicleId = "VEH-BUSY-01";

        // Giả lập yêu cầu cứu hộ đang ở trạng thái PENDING hợp lệ
        RescueRequest rescueRequest = new RescueRequest();
        rescueRequest.setId(requestId);
        rescueRequest.setStatus("PENDING");
        when(requestRepo.findById(requestId)).thenReturn(Optional.of(rescueRequest));

        // Giả lập phương tiện đang ở trạng thái BUSY
        Vehicles busyVehicle = new Vehicles();
        busyVehicle.setId(vehicleId);
        busyVehicle.setLicensePlate("43C-88888");
        busyVehicle.setStatus("BUSY");
        when(vehiclesRepository.findById(vehicleId)).thenReturn(Optional.of(busyVehicle));

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setTeamId("TEAM-001");
        requestDto.setVehicleIds(Collections.singletonList(vehicleId));

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            assignmentService.assignVehicleToRequest(requestDto);
        });

        assertTrue(exception.getMessage().contains("đang bận hoặc không ở trạng thái sẵn sàng (AVAILABLE)"));
        verify(assignmentRepo, never()).save(any());
    }
}
