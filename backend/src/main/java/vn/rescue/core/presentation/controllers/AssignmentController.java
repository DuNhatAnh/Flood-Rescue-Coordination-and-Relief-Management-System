package vn.rescue.core.presentation.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.TaskAssignmentResponse;
import vn.rescue.core.application.services.RescueCoordinationService;
import vn.rescue.core.domain.entities.Assignment;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/assignments")
public class AssignmentController {

    @Autowired
    private RescueCoordinationService rescueCoordinationService;

    @PostMapping
    public Assignment createAssignment(@RequestParam("requestId") String requestId,
            @RequestParam("teamId") String teamId,
            @RequestParam("vehicleId") String vehicleId,
            @RequestParam("assignedBy") String assignedBy) {
        return rescueCoordinationService.createAssignment(requestId, teamId, vehicleId, assignedBy);
    }

    @GetMapping("/my-tasks")
    public List<TaskAssignmentResponse> getMyTasks(@RequestParam(value = "teamId", required = false) String teamId) {
        // In a real app, teamId would come from the authenticated user
        if (teamId == null)
            return new ArrayList<>();
        return rescueCoordinationService.getAssignmentsByTeam(teamId);
    }

    @PutMapping("/{id}/status")
    public void updateStatus(@PathVariable("id") String id, @RequestBody Map<String, Object> body) {
        rescueCoordinationService.updateAssignmentStatus(id, body);
    }

    @PutMapping("/{id}/vehicle")
    public void updateVehicle(@PathVariable("id") String id, @RequestBody Map<String, String> body) {
        String newVehicleId = body.get("newVehicleId");
        String reason = body.get("reason");
        rescueCoordinationService.updateAssignmentVehicle(id, newVehicleId, reason);
    }
}
