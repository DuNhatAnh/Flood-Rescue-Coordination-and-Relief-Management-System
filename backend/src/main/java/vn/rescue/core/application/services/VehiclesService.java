package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.VehicleRequest;
import vn.rescue.core.application.dto.VehicleResponse;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class VehiclesService {
    private final VehiclesRepository vehiclesRepository;
    private final RescueRequestRepository rescueRequestRepository;
    private final SystemManagementService systemManagementService;

    // --- 1. LẤY DANH SÁCH (Sửa lỗi khớp 4 tham số: type, status, warehouseId, pageable) ---
    public Page<VehicleResponse> getAllVehicles(String type, String status, String warehouseId, Pageable pageable) {
        String typeFilter = (type != null) ? type : "";
        String statusFilter = (status != null) ? status : "";
        String warehouseFilter = (warehouseId != null) ? warehouseId : "";

        return vehiclesRepository
                .findByVehicleTypeContainingIgnoreCaseAndStatusContainingIgnoreCaseAndWarehouseIdContainingIgnoreCase(
                        typeFilter, statusFilter, warehouseFilter, pageable)
                .map(this::mapToResponse);
    }

    // --- 2. THỐNG KÊ (Dùng cho Dashboard/Charts) ---
    public Map<String, Long> getVehicleStatistics() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", vehiclesRepository.count());
        stats.put("available", vehiclesRepository.countByStatusIgnoreCase("AVAILABLE"));
        stats.put("in_use", vehiclesRepository.countByStatusIgnoreCase("IN_USE"));
        stats.put("maintenance", vehiclesRepository.countByStatusIgnoreCase("MAINTENANCE"));
        return stats;
    }

    // --- 3. THÊM MỚI ---
    @Transactional
    public VehicleResponse createVehicle(VehicleRequest request, String userId) {
        if (vehiclesRepository.existsByLicensePlate(request.getLicensePlate())) {
            throw new RuntimeException("Biển số xe đã tồn tại!");
        }
        Vehicles vehicle = new Vehicles();
        mapRequestToEntity(vehicle, request);
        vehicle.setStatus("AVAILABLE");

        Vehicles saved = vehiclesRepository.save(vehicle);
        systemManagementService.logAction(userId, "CREATE_VEHICLE", "Thêm xe mới: " + saved.getLicensePlate(), "VEHICLE");
        return mapToResponse(saved);
    }

    // --- 3. CẬP NHẬT (Sửa lỗi Cannot resolve updateVehicle) ---
    @Transactional
    public VehicleResponse updateVehicle(String id, VehicleRequest request, String userId) {
        Vehicles vehicle = vehiclesRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phương tiện ID: " + id));

        String oldPlate = vehicle.getLicensePlate();
        mapRequestToEntity(vehicle, request); // Cập nhật các thông tin từ request

        Vehicles updated = vehiclesRepository.save(vehicle);
        systemManagementService.logAction(userId, "UPDATE_VEHICLE", "Cập nhật xe từ biển " + oldPlate + " thành " + updated.getLicensePlate(), "VEHICLE");
        return mapToResponse(updated);
    }

    // --- 4. XÓA (Sửa lỗi Cannot resolve deleteVehicle) ---
    @Transactional
    public void deleteVehicle(String id, String userId) {
        Vehicles vehicle = vehiclesRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phương tiện để xóa!"));

        String plate = vehicle.getLicensePlate();
        vehiclesRepository.deleteById(id);

        // Luôn ghi log sau khi xóa thành công
        systemManagementService.logAction(userId, "DELETE_VEHICLE", "Xóa xe biển số: " + plate, "VEHICLE");
    }

    // --- HELPER METHODS ---

    private void mapRequestToEntity(Vehicles vehicle, VehicleRequest request) {
        vehicle.setVehicleType(request.getVehicleType());
        vehicle.setLicensePlate(request.getLicensePlate());
        vehicle.setCurrentLocation(request.getCurrentLocation());
        vehicle.setTeamId(request.getTeamId());
        vehicle.setWarehouseId(request.getWarehouseId());
    }

    private VehicleResponse mapToResponse(Vehicles vehicle) {
        return VehicleResponse.builder()
                .id(vehicle.getId())
                .vehicleType(vehicle.getVehicleType())
                .licensePlate(vehicle.getLicensePlate())
                .status(vehicle.getStatus())
                .currentLocation(vehicle.getCurrentLocation())
                .teamId(vehicle.getTeamId())
                .warehouseId(vehicle.getWarehouseId())
                .build();
    }
}