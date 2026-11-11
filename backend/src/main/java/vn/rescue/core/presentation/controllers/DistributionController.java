package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.CancelDistributionRequest;
import vn.rescue.core.application.dto.DistributionRequest;
import vn.rescue.core.application.services.DistributionService;
import vn.rescue.core.domain.entities.Distribution;

import java.util.List;

@RestController
@RequestMapping("/api/v1/distributions")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DistributionController {

    private final DistributionService distributionService;

    @PostMapping
    public ResponseEntity<Distribution> create(@RequestBody DistributionRequest request,
            Authentication authentication) {
        String userId = (authentication != null && authentication.getName() != null) ? authentication.getName() : "system";
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

    // KCPM-103: API Hủy đợt phân phối hàng cứu trợ và cơ chế tự động hoàn kho (Rollback Inventory)
    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('ADMIN', 'WAREHOUSE_STAFF')")
    public ResponseEntity<Distribution> cancelDistribution(
            @PathVariable String id,
            @RequestBody(required = false) CancelDistributionRequest request,
            @RequestParam(required = false) String reason,
            Authentication authentication) {
        String userId = (authentication != null && authentication.getName() != null) ? authentication.getName() : "system";
        String cancelReason = (request != null && request.getReason() != null) 
                ? request.getReason() 
                : (reason != null ? reason : "Hủy theo yêu cầu điều phối");
        return ResponseEntity.ok(distributionService.cancelDistribution(id, cancelReason, userId));
    }
}
