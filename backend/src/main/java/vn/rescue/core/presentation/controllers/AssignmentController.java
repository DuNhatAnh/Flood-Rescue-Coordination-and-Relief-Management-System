package vn.rescue.core.presentation.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.TaskAssignmentResponse;
import vn.rescue.core.application.services.RescueCoordinationService;
import vn.rescue.core.domain.entities.Assignment;
import vn.rescue.core.presentation.common.ApiResponse;
import org.springframework.http.ResponseEntity;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import vn.rescue.core.application.dto.AssignmentRequest;

@RestController
@RequestMapping("/api/v1/assignments")
public class AssignmentController {

    @Autowired
    private RescueCoordinationService rescueCoordinationService;

    @PostMapping
    public ResponseEntity<ApiResponse<Assignment>> createAssignment(@RequestBody AssignmentRequest request) {
        Assignment assignment = rescueCoordinationService.createAssignment(request);
        return ResponseEntity.ok(ApiResponse.success(assignment, "Assignment created successfully"));
    }

    @GetMapping("/my-tasks")
    public ResponseEntity<ApiResponse<List<TaskAssignmentResponse>>> getMyTasks(
            @RequestParam(value = "teamId", required = false) String teamId) {
        // In a real app, teamId would come from the authenticated user
        if (teamId == null)
            return ResponseEntity.ok(ApiResponse.success(new ArrayList<>(), "No team ID provided"));
        List<TaskAssignmentResponse> assignments = rescueCoordinationService.getAssignmentsByTeam(teamId);
        return ResponseEntity.ok(ApiResponse.success(assignments, "My tasks retrieved"));
    }

    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<TaskAssignmentResponse>>> getAllAssignments() {
        List<TaskAssignmentResponse> assignments = rescueCoordinationService.getAllAssignments();
        return ResponseEntity.ok(ApiResponse.success(assignments, "All assignments retrieved"));
    }

    @PutMapping("/{id}/status")
    public void updateStatus(@PathVariable("id") String id, @RequestBody Map<String, Object> body) {
        rescueCoordinationService.updateAssignmentStatus(id, body);
    }

    @PutMapping("/{id}/vehicle")
    @SuppressWarnings("unchecked")
    public void updateVehicle(@PathVariable("id") String id, @RequestBody Map<String, Object> body) {
        java.util.List<String> newVehicleIds = (java.util.List<String>) body.get("newVehicleIds");
        String reason = (String) body.get("reason");
        rescueCoordinationService.updateAssignmentVehicles(id, newVehicleIds, reason);
    }
}
