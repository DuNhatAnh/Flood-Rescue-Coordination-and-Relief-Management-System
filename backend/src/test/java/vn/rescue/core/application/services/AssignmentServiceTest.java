package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.AssignmentRequest;
import vn.rescue.core.application.dto.AssignmentResponse;
import vn.rescue.core.domain.entities.Assignment;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.repositories.AssignmentRepository;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-125: Hộp trắng - Điều phối & Chặn xe/đội bận (AssignmentService)")
class AssignmentServiceTest {

    @Mock
    private AssignmentRepository assignmentRepo;

    @Mock
    private RescueRequestRepository requestRepo;

    @Mock
    private VehiclesRepository vehicleRepo;

    @Mock
    private RequestStatusHistoryRepository historyRepo;

    @InjectMocks
    private AssignmentService assignmentService;

    @Test
    @DisplayName("WB_ASSIGN_01: Điều phối thành công khi yêu cầu PENDING, xe AVAILABLE -> Tạo Assignment ACTIVE, xe BUSY, yêu cầu ASSIGNED")
    void testAssignVehicleToRequest_Success_WithNote() {
        String requestId = "REQ-001";
        String teamId = "TEAM-01";
        String v1Id = "VEH-01";
        String v2Id = "VEH-02";

        RescueRequest rescueRequest = new RescueRequest();
        rescueRequest.setId(requestId);
        rescueRequest.setCustomId("YC-001");
        rescueRequest.setCitizenName("Nguyễn Văn An");
        rescueRequest.setStatus("PENDING");

        Vehicles v1 = new Vehicles();
        v1.setId(v1Id);
        v1.setLicensePlate("43A-001");
        v1.setVehicleType("CANO");
        v1.setStatus("AVAILABLE");

        Vehicles v2 = new Vehicles();
        v2.setId(v2Id);
        v2.setLicensePlate("43A-002");
        v2.setVehicleType("THUYEN");
        v2.setStatus("AVAILABLE");

        when(requestRepo.findById(requestId)).thenReturn(Optional.of(rescueRequest));
        when(vehicleRepo.findById(v1Id)).thenReturn(Optional.of(v1));
        when(vehicleRepo.findById(v2Id)).thenReturn(Optional.of(v2));
        when(assignmentRepo.save(any(Assignment.class))).thenAnswer(inv -> {
            Assignment a = inv.getArgument(0);
            a.setId("ASN-001");
            return a;
        });

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setTeamId(teamId);
        requestDto.setVehicleIds(List.of(v1Id, v2Id));
        requestDto.setNote("Khẩn cấp - ngập sâu 2 mét");

        AssignmentResponse response = assignmentService.assignVehicleToRequest(requestDto);

        assertNotNull(response);
        assertEquals("ASN-001", response.getAssignmentId());
        assertEquals(requestId, response.getRequestId());
        assertEquals("YC-001", response.getCustomId());
        assertEquals("Nguyễn Văn An", response.getCitizenName());
        assertEquals(teamId, response.getTeamId());
        assertEquals("SUCCESS", response.getStatus());
        assertEquals("43A-001, 43A-002", response.getLicensePlate());
        assertEquals("Đã điều động 2 phương tiện thành công.", response.getMessage());

        assertEquals("ASSIGNED", rescueRequest.getStatus());
        assertEquals(teamId, rescueRequest.getTeamId());
        assertEquals("BUSY", v1.getStatus());
        assertEquals("BUSY", v2.getStatus());

        verify(assignmentRepo, times(1)).save(any(Assignment.class));
        verify(requestRepo, times(1)).save(rescueRequest);
        verify(vehicleRepo, times(1)).save(v1);
        verify(vehicleRepo, times(1)).save(v2);
        verify(historyRepo, times(1)).save(any(RequestStatusHistory.class));
    }

    @Test
    @DisplayName("WB_ASSIGN_02: Điều phối thành công khi ghi chú note = null -> Xử lý chuỗi rỗng an toàn")
    void testAssignVehicleToRequest_Success_WithNullNote() {
        String requestId = "REQ-002";
        RescueRequest rescueRequest = new RescueRequest();
        rescueRequest.setId(requestId);
        rescueRequest.setCustomId("YC-002");
        rescueRequest.setCitizenName("Trần Thị Bình");
        rescueRequest.setStatus("VERIFIED");

        Vehicles v1 = new Vehicles();
        v1.setId("VEH-01");
        v1.setLicensePlate("43A-001");
        v1.setVehicleType("CANO");
        v1.setStatus("AVAILABLE");

        when(requestRepo.findById(requestId)).thenReturn(Optional.of(rescueRequest));
        when(vehicleRepo.findById("VEH-01")).thenReturn(Optional.of(v1));
        when(assignmentRepo.save(any(Assignment.class))).thenAnswer(inv -> {
            Assignment a = inv.getArgument(0);
            a.setId("ASN-002");
            return a;
        });

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setTeamId("TEAM-02");
        requestDto.setVehicleIds(List.of("VEH-01"));
        requestDto.setNote(null);

        AssignmentResponse response = assignmentService.assignVehicleToRequest(requestDto);

        assertNotNull(response);
        assertEquals("ASN-002", response.getAssignmentId());
        verify(historyRepo, times(1)).save(argThat(h -> h.getNote().endsWith("Ghi chú: ")));
    }

    @Test
    @DisplayName("WB_ASSIGN_03: Yêu cầu cứu hộ không tồn tại -> Ném ResourceNotFoundException (404)")
    void testAssignVehicleToRequest_WhenRequestNotFound_ShouldThrowResourceNotFoundException() {
        String nonExistRequestId = "REQ-404";
        when(requestRepo.findById(nonExistRequestId)).thenReturn(Optional.empty());

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(nonExistRequestId);

        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class, () -> {
            assignmentService.assignVehicleToRequest(requestDto);
        });

        assertTrue(ex.getMessage().contains("Nhiệm vụ không tồn tại với ID: " + nonExistRequestId));
        verify(assignmentRepo, never()).save(any());
    }

    @Test
    @DisplayName("WB_ASSIGN_04: Yêu cầu đã ở trạng thái ASSIGNED, COMPLETED hoặc CANCELLED -> Ném IllegalStateException")
    void testAssignVehicleToRequest_WhenInvalidStatus_ShouldThrowIllegalStateException() {
        for (String invalidStatus : List.of("ASSIGNED", "COMPLETED", "CANCELLED")) {
            RescueRequest request = new RescueRequest();
            request.setId("REQ-INVALID");
            request.setStatus(invalidStatus);
            when(requestRepo.findById("REQ-INVALID")).thenReturn(Optional.of(request));

            AssignmentRequest requestDto = new AssignmentRequest();
            requestDto.setRequestId("REQ-INVALID");

            IllegalStateException ex = assertThrows(IllegalStateException.class, () -> {
                assignmentService.assignVehicleToRequest(requestDto);
            });

            assertTrue(ex.getMessage().contains("Không thể điều phối yêu cầu cứu hộ đã ở trạng thái: " + invalidStatus));
        }
        verify(assignmentRepo, never()).save(any());
    }

    @Test
    @DisplayName("WB_ASSIGN_05: Danh sách phương tiện null hoặc rỗng -> Ném BadRequestException (400)")
    void testAssignVehicleToRequest_WhenVehicleIdsNullOrEmpty_ShouldThrowBadRequestException() {
        RescueRequest request = new RescueRequest();
        request.setId("REQ-003");
        request.setStatus("PENDING");
        when(requestRepo.findById("REQ-003")).thenReturn(Optional.of(request));

        // Case null
        AssignmentRequest requestNull = new AssignmentRequest();
        requestNull.setRequestId("REQ-003");
        requestNull.setVehicleIds(null);

        BadRequestException ex1 = assertThrows(BadRequestException.class, () -> {
            assignmentService.assignVehicleToRequest(requestNull);
        });
        assertEquals("Chưa chọn phương tiện nào!", ex1.getMessage());

        // Case empty
        AssignmentRequest requestEmpty = new AssignmentRequest();
        requestEmpty.setRequestId("REQ-003");
        requestEmpty.setVehicleIds(Collections.emptyList());

        BadRequestException ex2 = assertThrows(BadRequestException.class, () -> {
            assignmentService.assignVehicleToRequest(requestEmpty);
        });
        assertEquals("Chưa chọn phương tiện nào!", ex2.getMessage());

        verify(assignmentRepo, never()).save(any());
    }

    @Test
    @DisplayName("WB_ASSIGN_06: Phương tiện không tồn tại trong hệ thống -> Ném ResourceNotFoundException (404)")
    void testAssignVehicleToRequest_WhenVehicleNotFound_ShouldThrowResourceNotFoundException() {
        String requestId = "REQ-004";
        String nonExistVehicleId = "VEH-404";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");
        when(requestRepo.findById(requestId)).thenReturn(Optional.of(request));
        when(vehicleRepo.findById(nonExistVehicleId)).thenReturn(Optional.empty());

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setVehicleIds(List.of(nonExistVehicleId));

        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class, () -> {
            assignmentService.assignVehicleToRequest(requestDto);
        });

        assertTrue(ex.getMessage().contains("Phương tiện " + nonExistVehicleId + " không tồn tại!"));
        verify(assignmentRepo, never()).save(any());
    }

    @Test
    @DisplayName("WB_ASSIGN_07: Phương tiện không ở trạng thái AVAILABLE (đang BUSY) -> Ném BadRequestException (400)")
    void testAssignVehicleToRequest_WhenVehicleBusy_ShouldThrowBadRequestException() {
        String requestId = "REQ-005";
        String vehicleId = "VEH-BUSY";

        RescueRequest request = new RescueRequest();
        request.setId(requestId);
        request.setStatus("PENDING");

        Vehicles busyVehicle = new Vehicles();
        busyVehicle.setId(vehicleId);
        busyVehicle.setLicensePlate("43B-999");
        busyVehicle.setStatus("BUSY");

        when(requestRepo.findById(requestId)).thenReturn(Optional.of(request));
        when(vehicleRepo.findById(vehicleId)).thenReturn(Optional.of(busyVehicle));

        AssignmentRequest requestDto = new AssignmentRequest();
        requestDto.setRequestId(requestId);
        requestDto.setVehicleIds(List.of(vehicleId));

        BadRequestException ex = assertThrows(BadRequestException.class, () -> {
            assignmentService.assignVehicleToRequest(requestDto);
        });

        assertTrue(ex.getMessage().contains("đang bận hoặc không ở trạng thái sẵn sàng (AVAILABLE)"));
        verify(assignmentRepo, never()).save(any());
    }
}
