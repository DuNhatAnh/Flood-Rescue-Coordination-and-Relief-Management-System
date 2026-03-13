package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.WarehouseRequest;
import vn.rescue.core.domain.entities.Warehouse;
import vn.rescue.core.domain.repositories.WarehouseRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WarehouseService {
    private final WarehouseRepository warehouseRepository;

    public List<Warehouse> getAllWarehouses() {
        return warehouseRepository.findAll();
    }

    public Warehouse createWarehouse(WarehouseRequest request) {
        Warehouse warehouse = new Warehouse();
        warehouse.setWarehouseName(request.getWarehouseName());
        warehouse.setLocation(request.getLocation());
        warehouse.setManagerId(request.getManagerId());
        warehouse.setStatus(request.getStatus() != null ? request.getStatus() : "ACTIVE");
        warehouse.setCreatedAt(LocalDateTime.now());
        return warehouseRepository.save(warehouse);
    }

    public Warehouse updateWarehouse(String id, WarehouseRequest request) {
        Warehouse warehouse = warehouseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Warehouse not found"));
        
        warehouse.setWarehouseName(request.getWarehouseName());
        warehouse.setLocation(request.getLocation());
        warehouse.setManagerId(request.getManagerId());
        if (request.getStatus() != null) {
            warehouse.setStatus(request.getStatus());
        }
        return warehouseRepository.save(warehouse);
    }

    public void deleteWarehouse(String id) {
        warehouseRepository.deleteById(id);
    }
}
