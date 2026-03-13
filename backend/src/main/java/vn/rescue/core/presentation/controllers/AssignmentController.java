package vn.rescue.core.presentation.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.RescueCoordinationService;
import vn.rescue.core.domain.entities.Assignment;
import java.util.List;
import java.util.ArrayList;

@RestController
@RequestMapping("/api/assignments")
public class AssignmentController {

    @Autowired
    private RescueCoordinationService rescueCoordinationService;

    @PostMapping
    public Assignment createAssignment(@RequestParam String requestId, 
                                     @RequestParam String teamId,
                                     @RequestParam String assignedBy) {
        return rescueCoordinationService.createAssignment(requestId, teamId, assignedBy);
    }

    @GetMapping("/my-tasks")
    public List<Assignment> getMyTasks() {
        // This likely needs a separate AssignmentService or filtered by teamId
        // For now, return empty or implement a basic findByTeamId
        return new ArrayList<>();
    }

    @PutMapping("/{id}/status")
    public void updateStatus(@PathVariable String id, @RequestBody String status) {
        // Logic to update assignment status
    }
}
