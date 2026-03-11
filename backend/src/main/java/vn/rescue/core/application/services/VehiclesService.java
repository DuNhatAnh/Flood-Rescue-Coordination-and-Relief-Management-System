package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.VehicleRequest;
import vn.rescue.core.application.dto.VehicleResponse;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.repositories.VehiclesRepository;

@Service
@RequiredArgsConstructor
public class VehiclesService {
    private final VehiclesRepository vehiclesRepository;

    public VehicleResponse createVehicle(VehicleRequest request) {
        // 1. Chuyển DTO sang Entity
        Vehicles vehicle = new Vehicles();
        vehicle.setVehicleType(request.getVehicleType());
        vehicle.setLicensePlate(request.getLicensePlate());
        vehicle.setCurrentLocation(request.getCurrentLocation());
        vehicle.setTeamId(request.getTeamId());
        vehicle.setStatus("AVAILABLE"); // Gán mặc định theo DB

        // 2. Lưu vào Database
        Vehicles saved = vehiclesRepository.save(vehicle);

        // 3. Chuyển Entity đã lưu sang Response DTO
        return VehicleResponse.builder()
                .id(saved.getId())
                .vehicleType(saved.getVehicleType())
                .licensePlate(saved.getLicensePlate())
                .status(saved.getStatus())
                .currentLocation(saved.getCurrentLocation())
                .teamId(saved.getTeamId())
                .build();
    }
}