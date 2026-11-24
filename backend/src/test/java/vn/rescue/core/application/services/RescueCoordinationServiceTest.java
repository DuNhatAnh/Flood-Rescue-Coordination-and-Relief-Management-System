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

import java.time.LocalDateTime;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
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

    // =========================================================================
    // KCPM-125: HỘP TRẮNG - QUẢN LÝ ĐỘI SẴN SÀNG & LUÂN CHUYỂN TRẠNG THÁI (EPIC 04)
    // ==========================================

    @Test
    @DisplayName("WB_TEAM_01: getAvailableTeams() - Lấy danh sách đội cứu hộ sẵn sàng (AVAILABLE)")
    void testGetAvailableTeams_Success() {
        RescueTeam team1 = new RescueTeam();
        team1.setId("TEAM-01");
        team1.setTeamName("Đội Cứu hộ 1");
        team1.setStatus("AVAILABLE");

        RescueTeam team2 = new RescueTeam();
        team2.setId("TEAM-02");
        team2.setTeamName("Đội Cứu hộ 2");
        team2.setStatus("AVAILABLE");

        when(rescueTeamRepository.findByStatusIgnoreCase("AVAILABLE")).thenReturn(List.of(team1, team2));

        List<RescueTeam> result = rescueCoordinationService.getAvailableTeams();

        assertNotNull(result);
        assertEquals(2, result.size());
        assertEquals("TEAM-01", result.get(0).getId());
        assertEquals("AVAILABLE", result.get(0).getStatus());
        verify(rescueTeamRepository, times(1)).findByStatusIgnoreCase("AVAILABLE");
    }

    @Test
    @DisplayName("WB_TEAM_01_B: getAllTeams() - Lấy danh sách tất cả các đội cứu hộ")
    void testGetAllTeams_Success() {
        RescueTeam team1 = new RescueTeam();
        team1.setId("TEAM-01");
        when(rescueTeamRepository.findAll()).thenReturn(List.of(team1));

        List<RescueTeam> result = rescueCoordinationService.getAllTeams();

        assertNotNull(result);
        assertEquals(1, result.size());
        verify(rescueTeamRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("WB_TEAM_01_C: getTeamById() - Lấy thông tin đội cứu hộ theo ID")
    void testGetTeamById_Success() {
        String teamId = "TEAM-01";
        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));

        Optional<RescueTeam> result = rescueCoordinationService.getTeamById(teamId);

        assertTrue(result.isPresent());
        assertEquals(teamId, result.get().getId());
        verify(rescueTeamRepository, times(1)).findById(teamId);
    }

    @Test
    @DisplayName("WB_TEAM_02: updateTeam() - Đổi tên đội cứu hộ thành công, lưu DB và gửi thông báo notify")
    void testUpdateTeam_Success() {
        String teamId = "TEAM-01";
        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setTeamName("Tên Đội Cũ");
        team.setStatus("AVAILABLE");

        User member = new User();
        member.setId("USER-01");
        member.setFullName("Nguyễn Văn A");
        member.setTeamId(teamId);

        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(rescueTeamRepository.save(any(RescueTeam.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userRepository.findByTeamId(teamId)).thenReturn(List.of(member));

        RescueTeam updated = rescueCoordinationService.updateTeam(teamId, "Tên Đội Mới");

        assertNotNull(updated);
        assertEquals("Tên Đội Mới", updated.getTeamName());
        verify(rescueTeamRepository, times(1)).findById(teamId);
        verify(rescueTeamRepository, times(1)).save(team);
        verify(userRepository, times(1)).findByTeamId(teamId);
        verify(systemManagementService, times(1)).sendNotification(any());
    }

    @Test
    @DisplayName("WB_STM_01: refreshTeamStatus() - Đội không còn nhiệm vụ nào đang chạy -> Chuyển về AVAILABLE")
    void testRefreshTeamStatus_WhenNoActiveAssignments_ShouldSetAvailable() {
        String teamId = "TEAM-01";
        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setStatus("BUSY");

        Assignment finishedAssignment = new Assignment();
        finishedAssignment.setId("ASN-01");
        finishedAssignment.setTeamId(teamId);
        finishedAssignment.setStatus("COMPLETED");

        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(assignmentRepository.findByTeamId(teamId)).thenReturn(List.of(finishedAssignment));
        when(rescueTeamRepository.save(any(RescueTeam.class))).thenAnswer(inv -> inv.getArgument(0));

        org.springframework.test.util.ReflectionTestUtils.invokeMethod(rescueCoordinationService, "refreshTeamStatus", teamId);

        assertEquals("AVAILABLE", team.getStatus());
        verify(rescueTeamRepository, times(1)).save(team);
    }

    @Test
    @DisplayName("WB_STM_02: refreshTeamStatus() - Đội còn nhiệm vụ đang chạy (IN_PROGRESS/MOVING/...) -> Giữ BUSY")
    void testRefreshTeamStatus_WhenHasActiveAssignments_ShouldSetBusy() {
        String teamId = "TEAM-01";
        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setStatus("AVAILABLE");

        Assignment activeAssignment = new Assignment();
        activeAssignment.setId("ASN-02");
        activeAssignment.setTeamId(teamId);
        activeAssignment.setStatus("MOVING");

        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(assignmentRepository.findByTeamId(teamId)).thenReturn(List.of(activeAssignment));
        when(rescueTeamRepository.save(any(RescueTeam.class))).thenAnswer(inv -> inv.getArgument(0));

        org.springframework.test.util.ReflectionTestUtils.invokeMethod(rescueCoordinationService, "refreshTeamStatus", teamId);

        assertEquals("BUSY", team.getStatus());
        verify(rescueTeamRepository, times(1)).save(team);
    }

    @Test
    @DisplayName("WB_STM_03: refreshTeamStatus() - Đội không tồn tại trong DB -> Bỏ qua không cập nhật")
    void testRefreshTeamStatus_WhenTeamNotFound_ShouldDoNothing() {
        String nonExistTeamId = "TEAM-999";
        when(rescueTeamRepository.findById(nonExistTeamId)).thenReturn(Optional.empty());

        org.springframework.test.util.ReflectionTestUtils.invokeMethod(rescueCoordinationService, "refreshTeamStatus", nonExistTeamId);

        verify(rescueTeamRepository, never()).save(any());
    }

    @Test
    @DisplayName("WB_STM_04: Luân chuyển trạng thái đội gián tiếp qua updateAssignmentStatus sang CANCELLED")
    void testUpdateAssignmentStatus_Cancelled_ShouldTriggerRefreshTeamStatus() {
        String assignmentId = "ASN-100";
        String teamId = "TEAM-01";
        String userId = "ADMIN-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setRequestId("REQ-100");
        assignment.setStatus("IN_PROGRESS");
        assignment.setVehicleIds(List.of("VEH-01"));

        RescueRequest request = new RescueRequest();
        request.setId("REQ-100");
        request.setStatus("IN_PROGRESS");

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ROLE_ADMIN");

        Vehicles vehicle = new Vehicles();
        vehicle.setId("VEH-01");
        vehicle.setStatus("BUSY");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setStatus("BUSY");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));
        when(rescueRequestRepository.findById("REQ-100")).thenReturn(Optional.of(request));
        when(vehiclesRepository.findById("VEH-01")).thenReturn(Optional.of(vehicle));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(assignmentRepository.findByTeamId(teamId)).thenReturn(List.of(assignment));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "CANCELLED");
        body.put("note", "Hủy nhiệm vụ điều phối");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertEquals("CANCELLED", assignment.getStatus());
        assertEquals("AVAILABLE", vehicle.getStatus());
        verify(rescueTeamRepository, atLeastOnce()).save(team);
    }


    // ==========================================
    // 3. KIỂM THỬ XÁC MINH & GÁN ĐỘ KHẨN CẤP (updateUrgency & verifyRequest)
    // ==========================================

    @Test
    @DisplayName("WB_COORD_01: Cập nhật độ khẩn cấp thành công khi đơn cứu hộ tồn tại")
    void testUpdateUrgency_Success_WhenRequestExists() {
        String requestId = "REQ-001";
        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setUrgencyLevel("LOW");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));

        rescueCoordinationService.updateUrgency(requestId, "CRITICAL");

        assertEquals("CRITICAL", request.getUrgencyLevel());
        verify(rescueRequestRepository, times(1)).save(request);
    }

    @Test
    @DisplayName("WB_COORD_02: Cập nhật độ khẩn cấp khi đơn không tồn tại -> Không ném exception và không gọi save")
    void testUpdateUrgency_WhenRequestNotFound_ShouldDoNothing() {
        String requestId = "REQ-NONEXIST";
        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.empty());

        assertDoesNotThrow(() -> rescueCoordinationService.updateUrgency(requestId, "HIGH"));
        verify(rescueRequestRepository, never()).save(any());
    }

    @Test
    @DisplayName("WB_COORD_03: Xác minh đơn cứu hộ thành công theo UUID chuẩn")
    void testVerifyRequest_Success_WithUuid() {
        String requestId = "REQ-UUID-12345";
        String verifiedBy = "coordinator@rescue.vn";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setVerified(false);

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));

        rescueCoordinationService.verifyRequest(requestId, verifiedBy);

        assertTrue(request.isVerified());
        assertEquals(verifiedBy, request.getVerifiedBy());
        verify(rescueRequestRepository, times(1)).save(request);
    }

    @Test
    @DisplayName("WB_COORD_04: Xác minh đơn cứu hộ thành công theo Custom ID (fallback khi findById rỗng)")
    void testVerifyRequest_Success_WithCustomIdFallback() {
        String customId = "REQ-20261124-001";
        String verifiedBy = "leader@rescue.vn";

        RescueRequest request = new RescueRequest();
        request.setId("UUID-INTERNAL-999");
        request.setCustomId(customId);
        request.setVerified(false);

        when(rescueRequestRepository.findById(customId)).thenReturn(Optional.empty());
        when(rescueRequestRepository.findFirstByCustomId(customId)).thenReturn(Optional.of(request));

        rescueCoordinationService.verifyRequest(customId, verifiedBy);

        assertTrue(request.isVerified());
        assertEquals(verifiedBy, request.getVerifiedBy());
        verify(rescueRequestRepository, times(1)).save(request);
    }

    @Test
    @DisplayName("WB_COORD_05: Xác minh đơn khi cả 2 cách tìm kiếm đều không thấy -> Không ném exception và không gọi save")
    void testVerifyRequest_WhenNotFoundAnywhere_ShouldDoNothing() {
        String nonExistId = "REQ-404";

        when(rescueRequestRepository.findById(nonExistId)).thenReturn(Optional.empty());
        when(rescueRequestRepository.findFirstByCustomId(nonExistId)).thenReturn(Optional.empty());

        assertDoesNotThrow(() -> rescueCoordinationService.verifyRequest(nonExistId, "coordinator@rescue.vn"));
        verify(rescueRequestRepository, never()).save(any());
    }

    // ==========================================
    // 4. KIỂM THỬ NGOẠI LỆ BẢO MẬT & LUỒNG NGHIỆP VỤ MỞ RỘNG
    // (updateAssignmentStatus)
    // ==========================================

    @Test
    @DisplayName("WB_COORD_06: Chặn cập nhật khi thiếu userId hoặc userId rỗng -> Ném RuntimeException")
    void testUpdateAssignmentStatus_WhenUserIdMissingOrEmpty_ShouldThrowRuntimeException() {
        String assignmentId = "ASSIGN-SEC-01";
        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));

        Map<String, Object> bodyNull = new HashMap<>();
        bodyNull.put("userId", null);
        RuntimeException exNull = assertThrows(RuntimeException.class,
                () -> rescueCoordinationService.updateAssignmentStatus(assignmentId, bodyNull));
        assertTrue(exNull.getMessage().contains("Thiếu thông tin nhận diện người dùng"));

        Map<String, Object> bodyEmpty = new HashMap<>();
        bodyEmpty.put("userId", "");
        RuntimeException exEmpty = assertThrows(RuntimeException.class,
                () -> rescueCoordinationService.updateAssignmentStatus(assignmentId, bodyEmpty));
        assertTrue(exEmpty.getMessage().contains("Thiếu thông tin nhận diện người dùng"));
    }

    @Test
    @DisplayName("WB_COORD_07: Chặn cập nhật khi không tìm thấy người dùng trong DB -> Ném RuntimeException")
    void testUpdateAssignmentStatus_WhenUserNotFoundInDb_ShouldThrowRuntimeException() {
        String assignmentId = "ASSIGN-SEC-02";
        String userId = "USER-NOT-FOUND";
        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> rescueCoordinationService.updateAssignmentStatus(assignmentId, body));
        assertTrue(ex.getMessage().contains("Không tìm thấy người dùng"));
    }

    @Test
    @DisplayName("WB_COORD_08: Chặn cập nhật khi User thuộc team nhưng role sai (không phải Staff/Leader) -> Ném RuntimeException")
    void testUpdateAssignmentStatus_WhenUserHasTeamIdButWrongRole_ShouldThrowRuntimeException() {
        String assignmentId = "ASSIGN-SEC-03";
        String userId = "USER-CITIZEN-IN-TEAM";
        String teamId = "TEAM-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);

        User citizenInTeam = new User();
        citizenInTeam.setId(userId);
        citizenInTeam.setTeamId(teamId);
        citizenInTeam.setRoleId("ROLE_VOLUNTEER"); // Không phải STAFF, LEADER, ADMIN, COORDINATOR

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(citizenInTeam));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "IN_PROGRESS");

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> rescueCoordinationService.updateAssignmentStatus(assignmentId, body));
        assertTrue(ex.getMessage().contains("Chỉ thành viên đội cứu hộ hoặc điều phối viên mới có quyền"));
    }

    @Test
    @DisplayName("WB_COORD_09: Nhân viên cứu hộ (Staff) báo COMPLETED -> Tự động chuyển targetStatus sang REPORTED")
    void testUpdateAssignmentStatus_WhenStaffReportsCompleted_ShouldDowngradeToReported() {
        String assignmentId = "ASSIGN-WF-01";
        String userId = "USER-STAFF-01";
        String teamId = "TEAM-01";
        String requestId = "REQ-WF-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setRequestId(requestId);

        User staffUser = new User();
        staffUser.setId(userId);
        staffUser.setTeamId(teamId);
        staffUser.setRoleId("RESCUE_STAFF");
        staffUser.setFullName("Nguyễn Văn Cứu Hộ");

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setAddressText("Khu phố 3, An Sơn");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(staffUser));
        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "COMPLETED");
        body.put("note", "Đã tiếp cận và đưa nạn nhân lên bờ");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertEquals("REPORTED", assignment.getStatus(),
                "Staff báo hoàn thành phải tự hạ sang REPORTED chờ điều phối viên duyệt");
        assertEquals("REPORTED", request.getStatus());
        verify(systemManagementService, times(1)).logAction(eq("Nguyễn Văn Cứu Hộ"), eq("BÁO CÁO CỨU HỘ"), anyString(),
                eq("RESCUE"));
        verify(assignmentRepository, times(1)).save(assignment);
    }

    @Test
    @DisplayName("WB_COORD_10: Tự động xuất kho vật phẩm cứu trợ khi chuyển sang trạng thái tác chiến (MOVING) kèm fallback tên/đơn vị")
    void testUpdateAssignmentStatus_AutoExportItems_WhenTransitionToMoving() {
        String assignmentId = "ASSIGN-INV-01";
        String userId = "USER-STAFF-01";
        String teamId = "TEAM-01";
        String warehouseId = "WH-CENTRAL-01";

        MissionItem existingItem = new MissionItem();
        existingItem.setItemId("ITEM-MI-TOM");
        existingItem.setItemName("Mì ăn liền");
        existingItem.setUnit("Thùng");
        existingItem.setQuantity(50);

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("ASSIGNED");
        assignment.setItemsExported(false);
        assignment.setMissionItems(List.of(existingItem));

        User staffUser = new User();
        staffUser.setId(userId);
        staffUser.setTeamId(teamId);
        staffUser.setRoleId("RESCUE_STAFF");

        Warehouse warehouse = new Warehouse();
        warehouse.setId(warehouseId);
        warehouse.setWarehouseName("Kho Tổng Cứu Trợ");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(staffUser));
        when(warehouseRepository.findByManagerId(userId)).thenReturn(Optional.of(warehouse));

        // Item 1: itemName null -> fallback lấy từ assignment.getMissionItems()
        Map<String, Object> itemMap1 = new HashMap<>();
        itemMap1.put("itemId", "ITEM-MI-TOM");
        itemMap1.put("itemName", null);
        itemMap1.put("unit", null);
        itemMap1.put("quantity", 50);

        // Item 2: quantity không phải kiểu Number -> fallback về 0
        Map<String, Object> itemMap2 = new HashMap<>();
        itemMap2.put("itemId", "ITEM-NUOC");
        itemMap2.put("itemName", "Nước khoáng");
        itemMap2.put("unit", "Chai");
        itemMap2.put("quantity", "KHONG_PHAI_SO");

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "MOVING");
        body.put("items", List.of(itemMap1, itemMap2));

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertTrue(assignment.isItemsExported(), "Nhiệm vụ phải được đánh dấu đã xuất kho");
        assertNotNull(assignment.getMissionItems());
        assertEquals(2, assignment.getMissionItems().size());
        assertEquals("Mì ăn liền", assignment.getMissionItems().get(0).getItemName(),
                "Fallback itemName từ existing mission item");
        assertEquals(0, assignment.getMissionItems().get(1).getQuantity(),
                "Quantity không phải Number thì fallback về 0");
        verify(inventoryService, times(1)).batchExport(eq(warehouseId), eq(assignmentId), anyList(), eq(userId));
    }

    @Test
    @DisplayName("WB_COORD_11: Điều phối viên nghiệm thu COMPLETED với ảnh, số người cứu, occurredAt, và tự động hoàn kho hàng dư")
    void testUpdateAssignmentStatus_WithImagesRescuedCountAndActualItems_WhenCompletedByCoordinator() {
        String assignmentId = "ASSIGN-DATA-01";
        String userId = "USER-COORD-01";
        String teamId = "TEAM-01";
        String requestId = "REQ-DATA-01";
        String warehouseId = "WH-MAIN";

        MissionItem plannedItem = new MissionItem();
        plannedItem.setItemId("ITEM-AO-PHAO");
        plannedItem.setItemName("Áo phao");
        plannedItem.setUnit("Cái");
        plannedItem.setQuantity(20);

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setRequestId(requestId);
        assignment.setMissionItems(List.of(plannedItem));
        assignment.setAssignedItems(List.of(plannedItem));
        assignment.setItemsExported(true);

        User coordUser = new User();
        coordUser.setId(userId);
        coordUser.setRoleId("COORDINATOR");

        RescueRequest request = new RescueRequest();
        request.setId(requestId);

        Distribution distribution = new Distribution();
        distribution.setWarehouseId(warehouseId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(coordUser));
        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueReportRepository.findByAssignmentId(assignmentId)).thenReturn(Optional.empty());
        // Fallback: tìm theo assignmentId rỗng thì tìm theo requestId
        when(distributionRepository.findByRequestId(assignmentId)).thenReturn(Collections.emptyList());
        when(distributionRepository.findByRequestId(requestId)).thenReturn(List.of(distribution));

        Map<String, Object> actualItemMap = new HashMap<>();
        actualItemMap.put("itemId", "ITEM-AO-PHAO");
        actualItemMap.put("itemName", null); // Fallback sang assignedItems
        actualItemMap.put("unit", null);
        actualItemMap.put("quantity", 12); // Phát 12 cái, dư 8 cái hoàn kho

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "COMPLETED");
        body.put("imageUrls", List.of("https://cdn.rescue.vn/evidence1.jpg", "https://cdn.rescue.vn/evidence2.jpg"));
        body.put("rescuedCount", 8);
        body.put("occurredAt", "2026-11-24T20:00:00");
        body.put("actualItems", List.of(actualItemMap));

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertEquals("COMPLETED", assignment.getStatus());
        assertEquals(8, assignment.getRescuedCount());
        assertEquals(2, assignment.getImageUrls().size());
        assertNotNull(assignment.getCompletedAt());
        assertNotNull(assignment.getActualCompletedAt(), "Phải parse occurredAt khi có trong request body");
        verify(rescueReportRepository, times(1)).save(any(RescueReport.class));
        verify(inventoryService, times(1)).batchReturn(eq(warehouseId), eq(assignmentId), anyList(), eq(userId));
    }

    @Test
    @DisplayName("WB_COORD_12: Điều phối viên từ chối báo cáo (REJECTED) -> Đơn cứu nạn quay về VERIFIED và giải phóng phương tiện")
    void testUpdateAssignmentStatus_WhenRejectedByCoordinator_ShouldResetRequestToVerified() {
        String assignmentId = "ASSIGN-REJ-01";
        String userId = "USER-COORD-01";
        String teamId = "TEAM-01";
        String requestId = "REQ-REJ-01";
        String vehicleId = "VEH-CANO-02";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setRequestId(requestId);
        assignment.setVehicleIds(List.of(vehicleId));

        User coordUser = new User();
        coordUser.setId(userId);
        coordUser.setRoleId("COORDINATOR");

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("IN_PROGRESS");

        Vehicles vehicle = new Vehicles();
        vehicle.setId(vehicleId);
        vehicle.setStatus("BUSY");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(coordUser));
        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(vehiclesRepository.findById(vehicleId)).thenReturn(Optional.of(vehicle));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "REJECTED");
        body.put("note", "Báo cáo thiếu ảnh hiện trường, yêu cầu kiểm tra lại");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertEquals("REJECTED", assignment.getStatus());
        assertEquals("VERIFIED", request.getStatus(),
                "Yêu cầu cứu hộ phải quay lại trạng thái VERIFIED khi nhiệm vụ bị từ chối");
        assertEquals("AVAILABLE", vehicle.getStatus(), "Phương tiện phải được giải phóng về AVAILABLE");
        verify(vehiclesRepository, times(1)).save(vehicle);
    }

    // =========================================================================
    // WB_COORD_13 -> WB_COORD_26: TỐI ĐA HÓA ĐỘ BAO PHỦ RẼ NHÁNH (BRANCH COVERAGE)
    // =========================================================================

    @Test
    @DisplayName("WB_COORD_13: createAssignment khi vehicleIds = null và missionItems != null -> Phân công thành công không gắn xe")
    void testCreateAssignment_WhenVehicleIdsNullAndMissionItemsNotNull_ShouldSucceed() {
        String requestId = "REQ-NO-VEH-01";
        String teamId = "TEAM-01";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");
        request.setAddressText("123 Thôn Đông");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setTeamName("Đội Cứu nạn 1");
        team.setStatus("AVAILABLE");

        MissionItem item = new MissionItem();
        item.setItemId("ITEM-AO-PHAO");
        item.setItemName("Áo phao");
        item.setQuantity(10);

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(assignmentRepository.save(any(Assignment.class))).thenAnswer(inv -> inv.getArgument(0));

        AssignmentRequest dto = new AssignmentRequest();
        dto.setRequestId(requestId);
        dto.setTeamId(teamId);
        dto.setVehicleIds(null); // vehicleIds null
        dto.setMissionItems(List.of(item)); // missionItems not null
        dto.setAssignedBy("coordinator@rescue.vn");

        Assignment result = rescueCoordinationService.createAssignment(dto);

        assertNotNull(result);
        assertNull(result.getVehicleIds());
        assertEquals(1, result.getMissionItems().size());
        assertEquals(1, result.getAssignedItems().size());
        verify(vehiclesRepository, never()).findById(any());
        verify(rescueTeamRepository, times(1)).save(team);
    }

    @Test
    @DisplayName("WB_COORD_14: createAssignment khi vehicleIds là danh sách rỗng -> Bỏ qua kiểm tra xe")
    void testCreateAssignment_WhenVehicleIdsEmptyList_ShouldSucceed() {
        String requestId = "REQ-EMPTY-VEH";
        String teamId = "TEAM-01";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setStatus("AVAILABLE");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(assignmentRepository.save(any(Assignment.class))).thenAnswer(inv -> inv.getArgument(0));

        AssignmentRequest dto = new AssignmentRequest();
        dto.setRequestId(requestId);
        dto.setTeamId(teamId);
        dto.setVehicleIds(Collections.emptyList()); // vehicleIds != null nhưng isEmpty() == true
        dto.setMissionItems(null);

        Assignment result = rescueCoordinationService.createAssignment(dto);

        assertNotNull(result);
        assertTrue(result.getVehicleIds().isEmpty());
        assertNotNull(result.getMissionItems());
        assertTrue(result.getMissionItems().isEmpty());
    }

    @Test
    @DisplayName("WB_COORD_15: updateAssignmentStatus khi user.getRoleId() == null -> Ném RuntimeException chặn quyền")
    void testUpdateAssignmentStatus_WhenUserRoleIdNull_ShouldThrowRuntimeException() {
        String assignmentId = "ASSIGN-ROLE-NULL";
        String userId = "USER-NO-ROLE";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId("TEAM-01");

        User user = new User();
        user.setId(userId);
        user.setRoleId(null); // roleId == null
        user.setTeamId("TEAM-01"); // đúng team nhưng không có role STAFF hay LEADER

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        Map<String, Object> body = Map.of("userId", userId, "status", "IN_PROGRESS");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });
        assertTrue(ex.getMessage().contains("Chỉ thành viên đội cứu hộ hoặc điều phối viên"));
    }

    @Test
    @DisplayName("WB_COORD_16: updateAssignmentStatus khi user có vai trò LEADER cập nhật nhiệm vụ đội mình -> Thành công")
    void testUpdateAssignmentStatus_WhenUserIsLeader_ShouldSucceed() {
        String assignmentId = "ASSIGN-LEADER-01";
        String userId = "USER-LEADER-01";
        String teamId = "TEAM-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("ASSIGNED");
        assignment.setRequestId("REQ-01");

        User leaderUser = new User();
        leaderUser.setId(userId);
        leaderUser.setRoleId("ROLE_LEADER");
        leaderUser.setTeamId(teamId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(leaderUser));

        Map<String, Object> body = Map.of("userId", userId, "status", "MOVING");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertEquals("MOVING", assignment.getStatus());
        verify(assignmentRepository, times(1)).save(assignment);
    }

    @Test
    @DisplayName("WB_COORD_17: updateAssignmentStatus khi user.getTeamId() == null và không phải Elevated -> Ném RuntimeException")
    void testUpdateAssignmentStatus_WhenUserTeamIdNull_ShouldThrowRuntimeException() {
        String assignmentId = "ASSIGN-NOTEAM-01";
        String userId = "USER-NOTEAM-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId("TEAM-01");

        User user = new User();
        user.setId(userId);
        user.setRoleId("ROLE_VOLUNTEER");
        user.setTeamId(null); // teamId null

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        Map<String, Object> body = Map.of("userId", userId, "status", "IN_PROGRESS");

        RuntimeException ex = assertThrows(RuntimeException.class, () -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });
        assertTrue(ex.getMessage().contains("Bạn không có quyền cập nhật trạng thái cho nhiệm vụ này!"));
    }

    @Test
    @DisplayName("WB_COORD_18: updateAssignmentStatus chặn nhảy cóc từ PENDING sang REPORTED -> Ném 400 BadRequestException")
    void testUpdateAssignmentStatus_WhenJumpingFromPendingToReported_ShouldThrowBadRequestException() {
        String assignmentId = "ASSIGN-JUMP-01";
        String userId = "USER-COORD-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setStatus("PENDING");

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ROLE_ADMIN");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));

        Map<String, Object> body = Map.of("userId", userId, "status", "REPORTED");

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });
        assertTrue(ex.getMessage().contains("Không thể chuyển trạng thái từ PENDING trực tiếp sang REPORTED"));
    }

    @Test
    @DisplayName("WB_COORD_19: updateAssignmentStatus chặn nhảy cóc từ ASSIGNED sang REPORTED -> Ném 400 BadRequestException")
    void testUpdateAssignmentStatus_WhenJumpingFromAssignedToReported_ShouldThrowBadRequestException() {
        String assignmentId = "ASSIGN-JUMP-02";
        String userId = "USER-COORD-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setStatus("ASSIGNED");

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ROLE_ADMIN");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));

        Map<String, Object> body = Map.of("userId", userId, "status", "REPORTED");

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            rescueCoordinationService.updateAssignmentStatus(assignmentId, body);
        });
        assertTrue(ex.getMessage().contains("Không thể chuyển trạng thái từ ASSIGNED trực tiếp sang REPORTED"));
    }

    @Test
    @DisplayName("WB_COORD_20: updateAssignmentStatus lưu reportNote khi trạng thái là MOVING kèm note")
    void testUpdateAssignmentStatus_WhenMovingWithNote_ShouldSaveReportNote() {
        String assignmentId = "ASSIGN-NOTE-01";
        String userId = "USER-STAFF-01";
        String teamId = "TEAM-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("ASSIGNED");

        User staffUser = new User();
        staffUser.setId(userId);
        staffUser.setRoleId("ROLE_STAFF");
        staffUser.setTeamId(teamId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(staffUser));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "MOVING");
        body.put("note", "Đang trên đường đến hiện trường cách 2km");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertEquals("MOVING", assignment.getStatus());
        assertEquals("Đang trên đường đến hiện trường cách 2km", assignment.getReportNote());
    }

    @Test
    @DisplayName("WB_COORD_21: updateAssignmentStatus khi requestId không tìm thấy trong RescueRequestRepository -> Vẫn cập nhật Assignment an toàn")
    void testUpdateAssignmentStatus_WhenRescueRequestNotFound_ShouldStillSaveAssignment() {
        String assignmentId = "ASSIGN-NOREQ-01";
        String userId = "USER-ADMIN-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId("TEAM-01");
        assignment.setStatus("IN_PROGRESS");
        assignment.setRequestId("NON_EXISTING_REQ");

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ADMIN");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));
        when(rescueRequestRepository.findById("NON_EXISTING_REQ")).thenReturn(Optional.empty());

        Map<String, Object> body = Map.of("userId", userId, "status", "IN_PROGRESS");

        assertDoesNotThrow(() -> rescueCoordinationService.updateAssignmentStatus(assignmentId, body));
        verify(assignmentRepository, times(1)).save(assignment);
        verify(requestStatusHistoryRepository, never()).save(any());
    }

    @Test
    @DisplayName("WB_COORD_22: updateAssignmentStatus khi note == null -> Ghi nhận RequestStatusHistory với note mặc định")
    void testUpdateAssignmentStatus_WhenNoteIsNull_ShouldUseDefaultHistoryNote() {
        String assignmentId = "ASSIGN-NONOTE-01";
        String userId = "USER-ADMIN-01";
        String requestId = "REQ-NONOTE-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId("TEAM-01");
        assignment.setStatus("IN_PROGRESS");
        assignment.setRequestId(requestId);

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ADMIN");

        RescueRequest request = new RescueRequest();
        request.setId(requestId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));
        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(request));

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "IN_PROGRESS");
        body.put("note", null); // note là null

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        verify(requestStatusHistoryRepository).save(argThat(h ->
                h.getNote().equals("Trạng thái nhiệm vụ chuyển sang IN_PROGRESS")
        ));
    }

    @Test
    @DisplayName("WB_COORD_23: updateAssignmentStatus khi RescueReport đã tồn tại sẵn -> Không tạo báo cáo trùng lặp")
    void testUpdateAssignmentStatus_WhenRescueReportAlreadyExists_ShouldNotDuplicateReport() {
        String assignmentId = "ASSIGN-DUPREPORT-01";
        String userId = "USER-ADMIN-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId("TEAM-01");
        assignment.setStatus("IN_PROGRESS");

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ADMIN");

        RescueReport existingReport = new RescueReport();
        existingReport.setId("REP-EXISTING-01");
        existingReport.setAssignmentId(assignmentId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));
        when(rescueReportRepository.findByAssignmentId(assignmentId)).thenReturn(Optional.of(existingReport));

        Map<String, Object> body = Map.of("userId", userId, "status", "COMPLETED");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        // Không gọi rescueReportRepository.save() vì report đã tồn tại
        verify(rescueReportRepository, never()).save(any(RescueReport.class));
    }

    @Test
    @DisplayName("WB_COORD_24: updateAssignmentStatus điều phối viên duyệt APPROVED -> Gửi thông báo phê duyệt cho đội cứu hộ")
    void testUpdateAssignmentStatus_WhenApprovedByCoordinator_ShouldNotifyTeam() {
        String assignmentId = "ASSIGN-APP-01";
        String userId = "USER-COORD-01";
        String teamId = "TEAM-01";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("IN_PROGRESS");

        User coordUser = new User();
        coordUser.setId(userId);
        coordUser.setRoleId("ROLE_COORDINATOR");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(coordUser));

        Map<String, Object> body = Map.of("userId", userId, "status", "APPROVED");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertEquals("APPROVED", assignment.getStatus());
        verify(assignmentRepository).save(assignment);
    }

    @Test
    @DisplayName("WB_COORD_25: updateAssignmentStatus hủy nhiệm vụ CANCELLED và giải phóng phương tiện khi xe không tìm thấy trong DB")
    void testUpdateAssignmentStatus_WhenCancelledAndVehicleNotFound_ShouldHandleGracefully() {
        String assignmentId = "ASSIGN-CANCEL-01";
        String userId = "USER-ADMIN-01";
        String teamId = "TEAM-01";
        String vehicleId = "VEH-NOT-FOUND";

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setVehicleIds(List.of(vehicleId));

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ADMIN");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));
        when(vehiclesRepository.findById(vehicleId)).thenReturn(Optional.empty());

        Map<String, Object> body = Map.of("userId", userId, "status", "CANCELLED");

        assertDoesNotThrow(() -> rescueCoordinationService.updateAssignmentStatus(assignmentId, body));

        assertEquals("CANCELLED", assignment.getStatus());
        verify(vehiclesRepository, never()).save(any());
    }

    @Test
    @DisplayName("WB_COORD_26: updateAssignmentStatus hoàn kho trực tiếp từ distribution của assignmentId và trường hợp không có distribution")
    void testUpdateAssignmentStatus_ReturnSurplusItems_DirectDistribution() {
        String assignmentId = "ASSIGN-RETURN-DIRECT";
        String userId = "USER-ADMIN-01";
        String teamId = "TEAM-01";
        String warehouseId = "WH-DIRECT";

        MissionItem planned = new MissionItem();
        planned.setItemId("ITEM-GAO");
        planned.setQuantity(50);

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setMissionItems(List.of(planned));

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ADMIN");

        Distribution directDist = new Distribution();
        directDist.setWarehouseId(warehouseId);

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));
        when(rescueReportRepository.findByAssignmentId(assignmentId)).thenReturn(Optional.empty());
        // Tìm thấy trực tiếp qua assignmentId (không rỗng)
        when(distributionRepository.findByRequestId(assignmentId)).thenReturn(List.of(directDist));

        Map<String, Object> body = Map.of("userId", userId, "status", "COMPLETED");

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        verify(inventoryService, times(1)).batchReturn(eq(warehouseId), eq(assignmentId), anyList(), eq(userId));
    }

    @Test
    @DisplayName("WB_COORD_27: updateAssignmentStatus xử lý actualItems fallback từ assignedItems và mặc định tên vật phẩm")
    void testUpdateAssignmentStatus_ActualItems_FallbackAssignedItemsAndDefaults() {
        String assignmentId = "ASSIGN-ACTUAL-FB";
        String userId = "USER-ADMIN-01";
        String teamId = "TEAM-01";

        MissionItem assignedItem = new MissionItem();
        assignedItem.setItemId("ITEM-THUOC");
        assignedItem.setItemName("Thuốc sát trùng");
        assignedItem.setUnit("Hộp");
        assignedItem.setQuantity(5);

        Assignment assignment = new Assignment();
        assignment.setId(assignmentId);
        assignment.setTeamId(teamId);
        assignment.setStatus("IN_PROGRESS");
        assignment.setMissionItems(Collections.emptyList()); // không có trong missionItems
        assignment.setAssignedItems(List.of(assignedItem)); // có trong assignedItems

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ADMIN");

        when(assignmentRepository.findById(assignmentId)).thenReturn(Optional.of(assignment));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));

        // Item 1: Fallback từ assignedItems
        Map<String, Object> item1 = new HashMap<>();
        item1.put("itemId", "ITEM-THUOC");
        item1.put("itemName", null);
        item1.put("unit", null);
        item1.put("quantity", 3);

        // Item 2: Không có trong assignedItems lẫn missionItems -> Fallback tên "Vật phẩm" và unit "-", qty không phải Number
        Map<String, Object> item2 = new HashMap<>();
        item2.put("itemId", "ITEM-UNKNOWN");
        item2.put("itemName", null);
        item2.put("unit", null);
        item2.put("quantity", "ABC");

        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("status", "IN_PROGRESS");
        body.put("actualItems", List.of(item1, item2));

        rescueCoordinationService.updateAssignmentStatus(assignmentId, body);

        assertNotNull(assignment.getActualDistributedItems());
        assertEquals(2, assignment.getActualDistributedItems().size());
        assertEquals("Thuốc sát trùng", assignment.getActualDistributedItems().get(0).getItemName());
        assertEquals("Hộp", assignment.getActualDistributedItems().get(0).getUnit());
        assertEquals("Vật phẩm", assignment.getActualDistributedItems().get(1).getItemName());
        assertEquals("-", assignment.getActualDistributedItems().get(1).getUnit());
        assertEquals(0, assignment.getActualDistributedItems().get(1).getQuantity());
    }

    @Test
    @DisplayName("WB_COORD_28: updateAssignmentStatus REJECTED không truyền note và REPORTED khi RescueRequest không tồn tại")
    void testUpdateAssignmentStatus_RejectedWithoutNote_And_ReportedWithoutRescueRequest() {
        String assignmentId1 = "ASSIGN-REJ-NONOTE";
        String userId = "USER-ADMIN-01";
        String teamId = "TEAM-01";

        Assignment assignment1 = new Assignment();
        assignment1.setId(assignmentId1);
        assignment1.setTeamId(teamId);
        assignment1.setStatus("IN_PROGRESS");

        User adminUser = new User();
        adminUser.setId(userId);
        adminUser.setRoleId("ADMIN");

        when(assignmentRepository.findById(assignmentId1)).thenReturn(Optional.of(assignment1));
        when(userRepository.findById(userId)).thenReturn(Optional.of(adminUser));

        // 1. REJECTED không note
        Map<String, Object> body1 = new HashMap<>();
        body1.put("userId", userId);
        body1.put("status", "REJECTED");
        body1.put("note", null);

        assertDoesNotThrow(() -> rescueCoordinationService.updateAssignmentStatus(assignmentId1, body1));

        // 2. REPORTED khi không tìm thấy RescueRequest
        String assignmentId2 = "ASSIGN-REP-NOREQ";
        Assignment assignment2 = new Assignment();
        assignment2.setId(assignmentId2);
        assignment2.setTeamId(teamId);
        assignment2.setStatus("IN_PROGRESS");
        assignment2.setRequestId("NON-EXISTENT-REQ");

        User staffUser = new User();
        staffUser.setId("USER-STAFF-NOREQ");
        staffUser.setRoleId("STAFF");
        staffUser.setTeamId(teamId);
        staffUser.setFullName("Cứu hộ viên test");

        when(assignmentRepository.findById(assignmentId2)).thenReturn(Optional.of(assignment2));
        when(userRepository.findById("USER-STAFF-NOREQ")).thenReturn(Optional.of(staffUser));
        when(rescueRequestRepository.findById("NON-EXISTENT-REQ")).thenReturn(Optional.empty());

        Map<String, Object> body2 = Map.of("userId", "USER-STAFF-NOREQ", "status", "REPORTED");

        assertDoesNotThrow(() -> rescueCoordinationService.updateAssignmentStatus(assignmentId2, body2));
        assertEquals("REPORTED", assignment2.getStatus());
    }
}
