package vn.rescue.core.presentation.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
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
    public Assignment createAssignment(@RequestParam String requestId, 
                                     @RequestParam String teamId,
                                     @RequestParam String vehicleId,
                                     @RequestParam String assignedBy) {
        return rescueCoordinationService.createAssignment(requestId, teamId, vehicleId, assignedBy);
    }

    @GetMapping("/my-tasks")
    public List<Assignment> getMyTasks(@RequestParam(required = false) String teamId) {
        // In a real app, teamId would come from the authenticated user
        if (teamId == null) return new ArrayList<>();
        return rescueCoordinationService.getAssignmentsByTeam(teamId);
    }

    @PutMapping("/{id}/status")
    public void updateStatus(@PathVariable String id, @RequestBody Map<String, Object> body) {
        // Logic to update assignment status and handle completion
        // For simplicity, just acknowledging for now or could implement in service
    }
}
