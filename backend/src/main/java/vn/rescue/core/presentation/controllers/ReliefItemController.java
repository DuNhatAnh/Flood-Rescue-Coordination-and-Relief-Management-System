package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.ReliefItemRequest;
import vn.rescue.core.application.services.ReliefItemService;
import vn.rescue.core.domain.entities.ReliefItem;
import vn.rescue.core.presentation.common.ApiResponse;
import org.springframework.http.ResponseEntity;

import java.util.List;

@RestController
@RequestMapping("/api/v1/relief-items")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ReliefItemController {

    private final ReliefItemService reliefItemService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ReliefItem>>> getAllReliefItems() {
        return ResponseEntity.ok(ApiResponse.success(reliefItemService.getAllReliefItems(), "Danh sách mặt hàng cứu trợ"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ReliefItem>> createReliefItem(@RequestBody ReliefItemRequest request) {
        return ResponseEntity.ok(ApiResponse.success(reliefItemService.createReliefItem(request), "Tạo mặt hàng thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ReliefItem>> updateReliefItem(@PathVariable("id") String id, @RequestBody ReliefItemRequest request) {
        return ResponseEntity.ok(ApiResponse.success(reliefItemService.updateReliefItem(id, request), "Cập nhật mặt hàng thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteReliefItem(@PathVariable("id") String id) {
        reliefItemService.deleteReliefItem(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Xóa mặt hàng thành công"));
    }
}
