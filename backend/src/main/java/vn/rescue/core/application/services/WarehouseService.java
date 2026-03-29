package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.WarehouseRequest;
import vn.rescue.core.domain.entities.Warehouse;
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WarehouseService {
    private final WarehouseRepository warehouseRepository;
    private final RescueTeamRepository rescueTeamRepository;

    public List<Warehouse> getAllWarehouses() {
        return warehouseRepository.findAll();
    }

    public Warehouse createWarehouse(WarehouseRequest request) {
        if (request.getManagerId() != null) {
            handleManagerReassignment(request.getManagerId());
        }
        Warehouse warehouse = new Warehouse();
        warehouse.setWarehouseName(request.getWarehouseName());
        warehouse.setLocation(request.getLocation());
        warehouse.setManagerId(request.getManagerId());
        warehouse.setStatus(request.getStatus() != null ? request.getStatus() : "ACTIVE");
        warehouse.setCreatedAt(LocalDateTime.now());
        
        Warehouse saved = warehouseRepository.save(warehouse);
        syncTeamWithWarehouse(saved.getManagerId(), saved.getId());
        return saved;
    }

    public Warehouse updateWarehouse(String id, WarehouseRequest request) {
        Warehouse warehouse = warehouseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Warehouse not found"));
        
        if (request.getManagerId() != null && !request.getManagerId().equals(warehouse.getManagerId())) {
            handleManagerReassignment(request.getManagerId());
        }
        
        warehouse.setWarehouseName(request.getWarehouseName());
        warehouse.setLocation(request.getLocation());
        warehouse.setManagerId(request.getManagerId());
        if (request.getStatus() != null) {
            warehouse.setStatus(request.getStatus());
        }
        
        Warehouse saved = warehouseRepository.save(warehouse);
        syncTeamWithWarehouse(saved.getManagerId(), saved.getId());
        return saved;
    }

    private void syncTeamWithWarehouse(String managerId, String warehouseId) {
        if (managerId != null) {
            rescueTeamRepository.findByLeaderId(managerId).ifPresent(team -> {
                team.setWarehouseId(warehouseId);
                rescueTeamRepository.save(team);
            });
        }
    }

    private void handleManagerReassignment(String managerId) {
        warehouseRepository.findByManagerId(managerId).ifPresent(oldWarehouse -> {
            oldWarehouse.setManagerId(null);
            warehouseRepository.save(oldWarehouse);
        });
    }

    public Warehouse getWarehouseByManagerId(String managerId) {
        return warehouseRepository.findByManagerId(managerId).orElse(null);
    }

    public Warehouse getWarehouseById(String id) {
        return warehouseRepository.findById(id).orElse(null);
    }

    public void deleteWarehouse(String id) {
        warehouseRepository.deleteById(id);
    }
}
