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
        Vehicles vehicle = Vehicles.builder()
                .vehicleType(request.getVehicleType())
                .licensePlate(request.getLicensePlate())
                .currentLocation(request.getCurrentLocation())
                .teamId(request.getTeamId())
                .status("AVAILABLE") // Gán mặc định theo DB
                .build();

        // 2. Lưu vào Database
        Vehicles saved = vehiclesRepository.save(vehicle);

        // 3. Chuyển Entity đã lưu sang Response DTO
        return VehicleResponse.builder()
                .vehicleId(saved.getVehicleId())
                .vehicleType(saved.getVehicleType())
                .licensePlate(saved.getLicensePlate())
                .status(saved.getStatus())
                .currentLocation(saved.getCurrentLocation())
                .teamId(saved.getTeamId())
                .build();
    }
}