package vn.rescue.core.presentation.controllers;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.InventoryResponse;
import vn.rescue.core.application.dto.StockInRequest;
import vn.rescue.core.application.services.InventoryService;

import java.util.List;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
public class InventoryController {
    private final InventoryService inventoryService;

    @PostMapping("/import")
    public ResponseEntity<InventoryResponse> importStock(@Valid @RequestBody StockInRequest request) {
        return ResponseEntity.ok(inventoryService.importStock(request));
    }

    @GetMapping("/warehouse/{warehouseId}")
    public ResponseEntity<List<InventoryResponse>> getWarehouseInventory(@PathVariable("warehouseId") String warehouseId) {
        return ResponseEntity.ok(inventoryService.getWarehouseInventory(warehouseId));
    }
}
