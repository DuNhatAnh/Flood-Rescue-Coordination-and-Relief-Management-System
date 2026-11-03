package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.AssignmentRequest;
import vn.rescue.core.domain.entities.*;
import vn.rescue.core.domain.repositories.*;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-61 / KCPM-78: Kiểm thử Chuỗi Luồng Nghiệp vụ Điều phối Cứu hộ & Ràng buộc Chặn lỗi")
class RescueCoordinationServiceTest {

    @Mock
    private RescueRequestRepository rescueRequestRepository;

    @Mock
    private AssignmentRepository assignmentRepository;

    @Mock
    private RescueTeamRepository rescueTeamRepository;

    @Mock
    private VehiclesRepository vehiclesRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private RequestStatusHistoryRepository requestStatusHistoryRepository;

    @Mock
    private WarehouseRepository warehouseRepository;

    @Mock
    private InventoryService inventoryService;

    @Mock
    private RescueReportRepository rescueReportRepository;

    @Mock
    private DistributionRepository distributionRepository;

    @Mock
    private ReliefItemRepository reliefItemRepository;

    @Mock
    private SystemManagementService systemManagementService;

    @InjectMocks
    private RescueCoordinationService rescueCoordinationService;

    // ==========================================
    // 1. KIỂM THỬ PHÂN CÔNG ĐỘI & CA-NÔ (createAssignment)
    // ==========================================

    @Test
    @DisplayName("TC_ASSIGN_01: Phân công thành công khi Đơn PENDING, Đội AVAILABLE và Ca-nô AVAILABLE")
    void testCreateAssignment_Success_WithTeamAndVehicles() {
        String requestId = "REQ-001";
        String teamId = "TEAM-01";
        String vehicleId = "VEH-CANO-01";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");
        request.setAddressText("123 Thôn Thượng, Đại Lộc");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setTeamName("Đội Cứu nạn 1");
        team.setStatus("AVAILABLE");

        Vehicles vehicle = new Vehicles();
        vehicle.setId(vehicleId);
        vehicle.setLicensePlate("CANO-99B");
        vehicle.setStatus("AVAILABLE");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(vehiclesRepository.findById(vehicleId)).thenReturn(Optional.of(vehicle));
        when(assignmentRepository.save(any(Assignment.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AssignmentRequest dto = new AssignmentRequest();
        dto.setRequestId(requestId);
        dto.setTeamId(teamId);
        dto.setVehicleIds(List.of(vehicleId));
        dto.setAssignedBy("coordinator@rescue.vn");

        Assignment result = rescueCoordinationService.createAssignment(dto);

        assertNotNull(result);
        assertEquals("ASSIGNED", request.getStatus());
        assertEquals("BUSY", team.getStatus());
        assertEquals("BUSY", vehicle.getStatus());
        verify(rescueRequestRepository).save(request);
        verify(rescueTeamRepository).save(team);
        verify(vehiclesRepository).save(vehicle);
        verify(assignmentRepository).save(any(Assignment.class));
    }

    @Test
    @DisplayName("TC_ASSIGN_02: Chặn phân công khi Đội cứu hộ đang bận (BUSY) -> Ném 400 BadRequestException")
    void testCreateAssignment_WhenTeamIsBusy_ShouldThrowBadRequestException() {
        String requestId = "REQ-002";
        String teamId = "TEAM-BUSY";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setTeamName("Đội Xung kích");
        team.setStatus("BUSY");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));

        AssignmentRequest dto = new AssignmentRequest();
        dto.setRequestId(requestId);
        dto.setTeamId(teamId);

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            rescueCoordinationService.createAssignment(dto);
        });

        assertTrue(ex.getMessage().contains("đang bận hoặc không ở trạng thái sẵn sàng"));
        verify(assignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_ASSIGN_03: Chặn phân công khi Đội cứu hộ không tồn tại -> Ném 404 ResourceNotFoundException")
    void testCreateAssignment_WhenTeamNotFound_ShouldThrowResourceNotFoundException() {
        String requestId = "REQ-003";
        String nonExistTeamId = "TEAM-404";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueTeamRepository.findById(nonExistTeamId)).thenReturn(Optional.empty());

        AssignmentRequest dto = new AssignmentRequest();
        dto.setRequestId(requestId);
        dto.setTeamId(nonExistTeamId);

        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class, () -> {
            rescueCoordinationService.createAssignment(dto);
        });

        assertTrue(ex.getMessage().contains("không tồn tại"));
        verify(assignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_ASSIGN_04: Chặn phân công khi Phương tiện/Ca-nô đang bận -> Ném 400 BadRequestException")
    void testCreateAssignment_WhenVehicleIsBusy_ShouldThrowBadRequestException() {
        String requestId = "REQ-004";
        String teamId = "TEAM-01";
        String vehicleId = "VEH-BUSY";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setStatus("AVAILABLE");

        Vehicles vehicle = new Vehicles();
        vehicle.setId(vehicleId);
        vehicle.setLicensePlate("CANO-02");
        vehicle.setStatus("BUSY");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(vehiclesRepository.findById(vehicleId)).thenReturn(Optional.of(vehicle));

        AssignmentRequest dto = new AssignmentRequest();
        dto.setRequestId(requestId);
        dto.setTeamId(teamId);
        dto.setVehicleIds(List.of(vehicleId));

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            rescueCoordinationService.createAssignment(dto);
        });

        assertTrue(ex.getMessage().contains("đang bận hoặc không ở trạng thái sẵn sàng"));
        verify(assignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_ASSIGN_05: Chặn phân công khi Phương tiện không tồn tại -> Ném 404 ResourceNotFoundException")
    void testCreateAssignment_WhenVehicleNotFound_ShouldThrowResourceNotFoundException() {
        String requestId = "REQ-005";
        String teamId = "TEAM-01";
        String nonExistVehId = "VEH-NOT-FOUND";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setStatus("AVAILABLE");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(vehiclesRepository.findById(nonExistVehId)).thenReturn(Optional.empty());

        AssignmentRequest dto = new AssignmentRequest();
        dto.setRequestId(requestId);
        dto.setTeamId(teamId);
        dto.setVehicleIds(List.of(nonExistVehId));

        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class, () -> {
            rescueCoordinationService.createAssignment(dto);
        });

        assertTrue(ex.getMessage().contains("không tồn tại"));
        verify(assignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_ASSIGN_06: Đơn cứu hộ đã COMPLETED -> Chặn điều phối, ném IllegalStateException")
    void testCreateAssignment_WhenRequestIsCompleted_ShouldThrowIllegalStateException() {
        String requestId = "REQ-006";
        RescueRequest completedRequest = new RescueRequest();
        completedRequest.setId(requestId);
        completedRequest.setStatus("COMPLETED");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(completedRequest));

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setTeamId("TEAM-01");

        IllegalStateException exception = assertThrows(IllegalStateException.class, () -> {
            rescueCoordinationService.createAssignment(requestDto);
        });

        assertTrue(exception.getMessage().contains("Không thể điều phối yêu cầu cứu hộ đã ở trạng thái: COMPLETED"));
        verify(assignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_ASSIGN_07: Đơn cứu hộ đã CANCELLED -> Chặn điều phối, ném IllegalStateException")
    void testCreateAssignment_WhenRequestIsCancelled_ShouldThrowIllegalStateException() {
        String requestId = "REQ-007";
        RescueRequest cancelledRequest = new RescueRequest();
        cancelledRequest.setId(requestId);
        cancelledRequest.setStatus("CANCELLED");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(cancelledRequest));

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setTeamId("TEAM-01");

        IllegalStateException exception = assertThrows(IllegalStateException.class, () -> {
            rescueCoordinationService.createAssignment(requestDto);
        });

        assertTrue(exception.getMessage().contains("Không thể điều phối yêu cầu cứu hộ đã ở trạng thái: CANCELLED"));
        verify(assignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_ASSIGN_08: Đơn cứu hộ không tồn tại -> Ném IllegalArgumentException")
    void testCreateAssignment_WhenRequestNotFound_ShouldThrowIllegalArgumentException() {
        String requestId = "NON_EXISTING";
        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.empty());
        when(rescueRequestRepository.findFirstByCustomId(requestId)).thenReturn(Optional.empty());

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setTeamId("TEAM-01");

        assertThrows(IllegalArgumentException.class, () -> {
            rescueCoordinationService.createAssignment(requestDto);
        });

        verify(assignmentRepository, never()).save(any());
    }

    // ==========================================
    // 2. KIỂM THỬ CHUYỂN TRẠNG THÁI NHIỆM VỤ (updateAssignmentStatus)
    // ==========================================

    @Test
    @DisplayName("TC_STATUS_01: Chuyển trạng thái hợp lệ tuần tự (ASSIGNED -> IN_PROGRESS) bởi thành viên đội")
    void testUpdateAssignmentStatus_Success_ToInProgress() {
        String assignmentId = "ASSIGN-001";
        String userId = "USER-STAFF-01";
        String teamId = "TEAM-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setStatus("ASSIGNED");
        assignment.setTeamId(teamId);
        assignment.setRequestId("REQ-001");

        User staffUser = new User();
        staffUser.setId(userId);
        staffUser.setRoleId("RESCUE_STAFF");
        staffUser.setTeamId(teamId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(staffUser));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "IN_PROGRESS");
        body.put("note", "Đội đang xuất phát đến hiện trường");

        assertDoesNotThrow(() -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });

        assertEquals("IN_PROGRESS", assignment.getStatus());
        verify(assignmentRepository).findById(assignmentId);
    }

    @Test
    @DisplayName("TC_STATUS_02: Chuyển trạng thái hợp lệ (IN_PROGRESS -> COMPLETED) bởi Điều phối viên")
    void testUpdateAssignmentStatus_Success_ToCompleted_ByCoordinator() {
        String assignmentId = "ASSIGN-002";
        String coordinatorId = "USER-COORD-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setTeamId("TEAM-01");
        assignment.setRequestId("REQ-002");

        User coordUser = new User();
        coordUser.setId(coordinatorId);
        coordUser.setRoleId("COORDINATOR");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(coordinatorId)).thenReturn(Optional.of(coordUser));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", coordinatorId);
        body.put("status", "COMPLETED");
        body.put("note", "Nhiệm vụ đã hoàn tất thành công");

        assertDoesNotThrow(() -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });

        assertEquals("COMPLETED", assignment.getStatus());
    }

    @Test
    @DisplayName("TC_STATUS_06: Tự động khởi tạo bản ghi RescueReport khi chuyển sang COMPLETED")
    void testUpdateAssignmentStatus_AutoCreatesRescueReport_WhenCompleted() {
        String assignmentId = "ASSIGN-REP-01";
        String coordinatorId = "USER-COORD-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setTeamId("TEAM-01");
        assignment.setRequestId("REQ-REP-01");

        User coordUser = new User();
        coordUser.setId(coordinatorId);
        coordUser.setRoleId("COORDINATOR");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(coordinatorId)).thenReturn(Optional.of(coordUser));
        when(rescueReportRepository.findByAssignmentId(assignmentId)).thenReturn(Optional.empty());

        Map<String, Object> body = new HashMap<>();
        body.put("userId", coordinatorId);
        body.put("status", "COMPLETED");
        body.put("rescuedCount", 5);
        body.put("note", "Đã cứu hộ xong 5 người");

        assertDoesNotThrow(() -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });

        assertEquals("COMPLETED", assignment.getStatus());
        verify(rescueReportRepository).save(any(RescueReport.class));
    }

    @Test
    @DisplayName("TC_STATUS_03: Chặn chuyển trạng thái nhảy cóc (từ ASSIGNED nhảy thẳng sang COMPLETED) -> Ném 400 BadRequestException")
    void testUpdateAssignmentStatus_WhenJumpingDirectlyToCompleted_ShouldThrowBadRequestException() {
        String assignmentId = "ASSIGN-003";
        String userId = "USER-COORD-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setStatus("ASSIGNED");
        assignment.setTeamId("TEAM-01");

        User coordUser = new User();
        coordUser.setId(userId);
        coordUser.setRoleId("COORDINATOR");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(coordUser));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "COMPLETED");

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });

        assertTrue(ex.getMessage().contains("Không thể chuyển trạng thái từ ASSIGNED trực tiếp sang COMPLETED"));
    }

    @Test
    @DisplayName("TC_STATUS_04: Chặn cập nhật khi người dùng không có quyền (khác đội và không phải Admin/Coordinator) -> Ném RuntimeException")
    void testUpdateAssignmentStatus_WhenUserUnauthorized_ShouldThrowRuntimeException() {
        String assignmentId = "ASSIGN-004";
        String userId = "USER-CITIZEN-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setStatus("ASSIGNED");
        assignment.setTeamId("TEAM-01");

        User citizenUser = new User();
        citizenUser.setId(userId);
        citizenUser.setRoleId("CITIZEN");
        citizenUser.setTeamId(null);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(citizenUser));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "IN_PROGRESS");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });

        assertTrue(ex.getMessage().contains("Bạn không có quyền"));
    }

    @Test
    @DisplayName("TC_STATUS_05: Chặn cập nhật khi không tìm thấy nhiệm vụ -> Ném 404 ResourceNotFoundException")
    void testUpdateAssignmentStatus_WhenAssignmentNotFound_ShouldThrowResourceNotFoundException() {
        String nonExistAssignmentId = "ASSIGN-404";
        when(assignmentRepository.findById(nonExistAssignmentId)).thenReturn(Optional.empty());

        Map<String, Object> body = new HashMap<>();
        body.put("userId", "USER-01");
        body.put("status", "IN_PROGRESS");

        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class, () -> {
            rescueCoordinationService.updateAssignmentStatus(nonExistAssignmentId, body);
        });

        assertTrue(ex.getMessage().contains("Không tìm thấy nhiệm vụ"));
    }
}
