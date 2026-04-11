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
    private final RescueCoordinationService rescueCoordinationService;

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
        warehouse.setLatitude(request.getLatitude());
        warehouse.setLongitude(request.getLongitude());
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
        warehouse.setLatitude(request.getLatitude());
        warehouse.setLongitude(request.getLongitude());
        
        Warehouse saved = warehouseRepository.save(warehouse);
        syncTeamWithWarehouse(saved.getManagerId(), saved.getId());
        return saved;
    }

    private void syncTeamWithWarehouse(String managerId, String warehouseId) {
        if (managerId != null) {
            rescueTeamRepository.findByLeaderId(managerId).ifPresent(team -> {
                String oldWarehouseId = team.getWarehouseId();
                if (warehouseId != null && !warehouseId.equals(oldWarehouseId)) {
                    team.setWarehouseId(warehouseId);
                    rescueTeamRepository.save(team);
                    
                    // Lấy tên kho mới để thông báo
                    warehouseRepository.findById(warehouseId).ifPresent(w -> {
                        rescueCoordinationService.notifyTeam(team.getId(), 
                            "Cập nhật Kho quản lý", 
                            "Đội đã được Admin gán quản lý kho mới: " + w.getWarehouseName() + ". Vui lòng kiểm tra lại sơ đồ kho.", 
                            "INFO");
                    });
                }
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
