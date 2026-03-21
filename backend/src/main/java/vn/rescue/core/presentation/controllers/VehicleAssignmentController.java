package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.AssignmentRequest;
import vn.rescue.core.application.dto.AssignmentResponse;
import vn.rescue.core.application.services.AssignmentService;

@RestController
@RequestMapping("/api/v1/assignments")
@RequiredArgsConstructor
public class VehicleAssignmentController {

    private final AssignmentService assignmentService;

    @PostMapping("/dispatch")
    public ResponseEntity<AssignmentResponse> assignVehicle(@RequestBody AssignmentRequest request) {
        // Gọi Service để xử lý nghiệp vụ gán phương tiện
        AssignmentResponse response = assignmentService.assignVehicleToRequest(request);

        // Trả về kết quả 200 OK kèm dữ liệu đã gán
        return ResponseEntity.ok(response);
    }
}
