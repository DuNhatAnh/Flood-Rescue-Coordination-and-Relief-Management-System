package vn.rescue.core.presentation.controllers;

import org.springframework.web.bind.annotation.*;
import vn.rescue.core.domain.entities.Assignment;
import java.util.List;
import java.util.ArrayList;

@RestController
@RequestMapping("/api/assignments")
public class AssignmentController {

    @PostMapping
    public Assignment createAssignment(@RequestBody Assignment assignment) {
        // Skeleton: Return the same assignment for now
        return assignment;
    }

    @GetMapping("/my-tasks")
    public List<Assignment> getMyTasks() {
        // Skeleton: Return empty list for now
        return new ArrayList<>();
    }

    @PutMapping("/{id}/status")
    public void updateStatus(@PathVariable String id, @RequestBody String status) {
        // Skeleton: Logic to update status
    }
}
