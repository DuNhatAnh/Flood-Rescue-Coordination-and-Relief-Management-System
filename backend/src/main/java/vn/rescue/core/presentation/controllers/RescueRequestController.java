package vn.rescue.core.presentation.controllers;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.application.dto.RescueRequestDto;
import vn.rescue.core.application.services.RescueRequestService;
import vn.rescue.core.domain.entities.RescueRequest;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/rescue-requests")
public class RescueRequestController {

    private final RescueRequestService rescueRequestService;

    public RescueRequestController(RescueRequestService rescueRequestService) {
        this.rescueRequestService = rescueRequestService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createRequest(@Valid @RequestBody RescueRequestDto requestDto) {

        RescueRequest savedRequest = rescueRequestService.createRequest(requestDto);

        Map<String, Object> data = Map.of(
                "requestId", savedRequest.getCustomId(),
                "status", savedRequest.getStatus());

        return ResponseEntity.ok(ApiResponse.success(data, "Rescue request created successfully"));
    }

    @GetMapping("/track/{id}")
    public ResponseEntity<ApiResponse<RescueRequest>> trackRequest(@PathVariable("id") String id) {
        RescueRequest request = rescueRequestService.getById(id);
        return ResponseEntity.ok(ApiResponse.success(request, "Rescue request found"));
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getStats() {
        return ResponseEntity.ok(ApiResponse.success(rescueRequestService.getStats(), "Statistics retrieved"));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<java.util.List<RescueRequest>>> getAllRequests() {
        return ResponseEntity.ok(ApiResponse.success(rescueRequestService.getAll(), "All rescue requests retrieved"));
    }
}
