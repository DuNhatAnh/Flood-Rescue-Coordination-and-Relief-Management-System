package vn.rescue.core.presentation.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.application.dto.RescueRequestDto;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/rescue-requests")
public class RescueRequestController {

    // Note: Mocking the service call for architecture foundation setup
    // private final CreateRescueUseCase createRescueUseCase;

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> createRequest(@ModelAttribute RescueRequestDto requestDto) {
        
        // 1. Convert DTO to Entity/Domain logic (UseCase layer)
        // 2. Save physical images and attachments (StoragePort)
        // 3. Emit Realtime Event to WebSocket (EventPublisher)

        // Mock response
        Map<String, Object> data = Map.of(
            "requestId", 1,
            "status", "PENDING"
        );

        return ResponseEntity.ok(ApiResponse.success(data, "Rescue request created successfully"));
    }
}
