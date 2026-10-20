package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.AssignmentRequest;
import vn.rescue.core.domain.entities.Assignment;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.repositories.AssignmentRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-40: Kiểm thử Chặn điều phối yêu cầu đã Hoàn thành/Hủy")
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
    private vn.rescue.core.domain.repositories.UserRepository userRepository;

    @Mock
    private SystemManagementService systemManagementService;

    @InjectMocks
    private RescueCoordinationService rescueCoordinationService;

    @Test
    @DisplayName("Đơn cứu hộ đã COMPLETED -> Chặn điều phối, ném IllegalStateException")
    void testCreateAssignment_WhenRequestIsCompleted_ShouldThrowIllegalStateException() {
        String requestId = "REQ-001";
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
    @DisplayName("Đơn cứu hộ đã CANCELLED -> Chặn điều phối, ném IllegalStateException")
    void testCreateAssignment_WhenRequestIsCancelled_ShouldThrowIllegalStateException() {
        String requestId = "REQ-002";
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
    @DisplayName("Đơn cứu hộ không tồn tại -> Ném IllegalArgumentException")
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

    @Test
    @DisplayName("Đơn cứu hộ PENDING -> Điều phối thành công, chuyển trạng thái ASSIGNED")
    void testCreateAssignment_WhenRequestIsPending_ShouldSucceed() {
        String requestId = "REQ-003";
        String teamId = "TEAM-01";
        RescueRequest pendingRequest = new RescueRequest();
        pendingRequest.setId(requestId);
        pendingRequest.setStatus("PENDING");
        pendingRequest.setAddressText("123 Đường Lũ");

        RescueTeam team = new RescueTeam();
        team.setId(teamId);
        team.setStatus("AVAILABLE");

        when(rescueRequestRepository.findById(requestId)).thenReturn(Optional.of(pendingRequest));
        when(rescueTeamRepository.findById(teamId)).thenReturn(Optional.of(team));
        when(assignmentRepository.save(any(Assignment.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setTeamId(teamId);
        requestDto.setAssignedBy("COORDINATOR");

        Assignment result = rescueCoordinationService.createAssignment(requestDto);

        assertNotNull(result);
        assertEquals("ASSIGNED", pendingRequest.getStatus());
        assertEquals("BUSY", team.getStatus());
        verify(rescueRequestRepository).save(pendingRequest);
        verify(assignmentRepository).save(any(Assignment.class));
    }
}
