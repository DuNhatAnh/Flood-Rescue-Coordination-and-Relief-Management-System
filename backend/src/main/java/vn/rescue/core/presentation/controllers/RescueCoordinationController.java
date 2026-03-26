package vn.rescue.core.presentation.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.RescueCoordinationService;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.presentation.common.ApiResponse;
import java.util.List;

@RestController
@RequestMapping("/api/v1/rescue-requests")
@CrossOrigin(origins = "*")
public class RescueCoordinationController {

    @Autowired
    private RescueCoordinationService rescueCoordinationService;

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<RescueRequest>>> getPendingRequests() {
        List<RescueRequest> requests = rescueCoordinationService.getPendingRequests();
        return ResponseEntity.ok(ApiResponse.success(requests, "Pending requests retrieved"));
    }

    @PutMapping("/{id}/urgency")
    public ResponseEntity<ApiResponse<Void>> updateUrgency(@PathVariable String id, @RequestBody String urgencyLevel) {
        rescueCoordinationService.updateUrgency(id, urgencyLevel);
        return ResponseEntity.ok(ApiResponse.success(null, "Urgency updated"));
    }

    @PutMapping("/{id}/verify")
    public ResponseEntity<ApiResponse<Void>> verifyRequest(@PathVariable String id, @RequestParam String verifiedBy) {
        rescueCoordinationService.verifyRequest(id, verifiedBy);
        return ResponseEntity.ok(ApiResponse.success(null, "Request verified"));
    }
}
