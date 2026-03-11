package vn.rescue.core.presentation.controllers;

import org.springframework.web.bind.annotation.*;
import vn.rescue.core.domain.entities.RescueRequest;
import java.util.List;
import java.util.ArrayList;

@RestController
@RequestMapping("/api/rescue-requests")
public class RescueCoordinationController {

    @GetMapping("/pending")
    public List<RescueRequest> getPendingRequests() {
        // Skeleton: Return empty list for now
        return new ArrayList<>();
    }

    @PutMapping("/{id}/urgency")
    public void updateUrgency(@PathVariable String id, @RequestBody String urgencyLevel) {
        // Skeleton: Logic to update urgency
    }
}
