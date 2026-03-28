package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.WarehouseRequest;
import vn.rescue.core.application.services.WarehouseService;
import vn.rescue.core.domain.entities.Warehouse;

import java.util.List;

@RestController
@RequestMapping("/api/warehouses")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class WarehouseController {
    private final WarehouseService warehouseService;

    @GetMapping
    public List<Warehouse> getAllWarehouses() {
        return warehouseService.getAllWarehouses();
    }

    @GetMapping("/manager/{managerId}")
    public Warehouse getWarehouseByManagerId(@PathVariable("managerId") String managerId) {
        return warehouseService.getWarehouseByManagerId(managerId);
    }

    @GetMapping("/{id}")
    public Warehouse getWarehouseById(@PathVariable("id") String id) {
        return warehouseService.getWarehouseById(id);
    }

    @PostMapping
    public Warehouse createWarehouse(@RequestBody WarehouseRequest request) {
        return warehouseService.createWarehouse(request);
    }

    @PutMapping("/{id}")
    public Warehouse updateWarehouse(@PathVariable("id") String id, @RequestBody WarehouseRequest request) {
        return warehouseService.updateWarehouse(id, request);
    }

    @DeleteMapping("/{id}")
    public void deleteWarehouse(@PathVariable("id") String id) {
        warehouseService.deleteWarehouse(id);
    }
}
