package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.DistributionRequest;
import vn.rescue.core.application.services.DistributionService;
import vn.rescue.core.domain.entities.Distribution;

import java.util.List;

@RestController
@RequestMapping("/api/distributions")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DistributionController {

    private final DistributionService distributionService;

    @PostMapping
    public ResponseEntity<Distribution> create(@RequestBody DistributionRequest request,
            Authentication authentication) {
        String userId = authentication.getName();
        return ResponseEntity.ok(distributionService.createDistribution(request, userId));
    }

    @GetMapping("/history")
    public ResponseEntity<List<Distribution>> getHistory() {
        return ResponseEntity.ok(distributionService.getHistory());
    }

    // BỔ SUNG: Xác nhận hoàn thành việc điều chuyển kho (Dành cho nghiệp vụ TRANSFER)
    @PostMapping("/{id}/complete-transfer")
    public ResponseEntity<Distribution> completeTransfer(@PathVariable String id) {
        return ResponseEntity.ok(distributionService.completeTransfer(id));
    }
}
