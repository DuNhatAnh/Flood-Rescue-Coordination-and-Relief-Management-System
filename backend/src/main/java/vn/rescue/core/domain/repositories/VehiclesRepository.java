package vn.rescue.core.domain.repositories;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Vehicles;

import java.util.List;
import java.util.Optional;

@Repository
public interface VehiclesRepository extends MongoRepository<Vehicles, String> {

    boolean existsByLicensePlate(String licensePlate);
    Optional<Vehicles> findByLicensePlate(String licensePlate);

    // Thống kê (SCRUM-55)
    long countByWarehouseId(String warehouseId);
    long countByStatusIgnoreCase(String status);
    long countByWarehouseIdAndStatusIgnoreCase(String warehouseId, String status);

    List<Vehicles> findByTeamId(String teamId);
    List<Vehicles> findByTeamIdAndStatus(String teamId, String status);

    // Hàm tìm kiếm chính xác để dùng trong Service (Sửa lỗi "Cannot resolve")
    Page<Vehicles> findByVehicleTypeContainingIgnoreCaseAndStatusContainingIgnoreCaseAndWarehouseIdContainingIgnoreCase(
            String vehicleType, String status, String warehouseId, Pageable pageable
    );

    List<Vehicles> findByStatusIgnoreCase(String status);
    List<Vehicles> findByWarehouseId(String warehouseId);

    @org.springframework.lang.NonNull
    Page<Vehicles> findAll(@org.springframework.lang.NonNull Pageable pageable);
}