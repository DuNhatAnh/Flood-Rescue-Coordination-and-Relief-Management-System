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

import java.util.List;

@Service
@RequiredArgsConstructor
public class VehiclesService {
    private final VehiclesRepository vehiclesRepository;
    private final RescueRequestRepository rescueRequestRepository;

    @Transactional
    public VehicleResponse createVehicle(VehicleRequest request) {
        if (vehiclesRepository.existsByLicensePlate(request.getLicensePlate())) {
            throw new RuntimeException("Biển số xe đã tồn tại!");
        }
        Vehicles vehicle = new Vehicles();
        mapRequestToEntity(vehicle, request);
        vehicle.setStatus("AVAILABLE");
        return mapToResponse(vehiclesRepository.save(vehicle));
    }

    @Transactional
    public VehicleResponse updateVehicle(String id, VehicleRequest request) {
        Vehicles vehicle = vehiclesRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phương tiện!"));

        // Kiểm tra nếu đổi biển số thì biển số mới không được trùng với xe khác
        if (!vehicle.getLicensePlate().equals(request.getLicensePlate()) &&
                vehiclesRepository.existsByLicensePlate(request.getLicensePlate())) {
            throw new RuntimeException("Biển số xe mới đã tồn tại trên hệ thống!");
        }

        mapRequestToEntity(vehicle, request);
        return mapToResponse(vehiclesRepository.save(vehicle));
    }

    @Transactional
    public void deleteVehicle(String id) {
        Vehicles vehicle = vehiclesRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phương tiện!"));

        if (vehicle.getTeamId() != null) {
            // Kiểm tra xem Team gắn với xe này có đang làm nhiệm vụ không
            boolean isBusy = rescueRequestRepository.existsByTeamIdAndStatusIn(
                    vehicle.getTeamId(), List.of("PENDING", "ASSIGNED", "IN_PROGRESS")
            );
            if (isBusy) {
                throw new RuntimeException("Ngăn chặn xóa: Phương tiện đang thực hiện nhiệm vụ!");
            }
        }
        vehiclesRepository.deleteById(id);
    }

    /**
     * Sửa lỗi lọc: Chuyển sang dùng Query Method của Repository
     */
    public Page<VehicleResponse> getAllVehicles(String type, String status, Pageable pageable) {
        // Xử lý logic: Nếu tham số là null thì chuyển thành chuỗi rỗng để tìm kiếm "chứa tất cả"
        String typeFilter = (type != null) ? type : "";
        String statusFilter = (status != null) ? status : "";

        return vehiclesRepository
                .findByVehicleTypeContainingAndStatusContaining(typeFilter, statusFilter, pageable)
                .map(this::mapToResponse);
    }

    private void mapRequestToEntity(Vehicles vehicle, VehicleRequest request) {
        vehicle.setVehicleType(request.getVehicleType());
        vehicle.setLicensePlate(request.getLicensePlate());
        vehicle.setCurrentLocation(request.getCurrentLocation());
        vehicle.setTeamId(request.getTeamId());
    }

    private VehicleResponse mapToResponse(Vehicles vehicle) {
        return VehicleResponse.builder()
                .id(vehicle.getId())
                .vehicleType(vehicle.getVehicleType())
                .licensePlate(vehicle.getLicensePlate())
                .status(vehicle.getStatus())
                .currentLocation(vehicle.getCurrentLocation())
                .teamId(vehicle.getTeamId())
                .build();
    }
}