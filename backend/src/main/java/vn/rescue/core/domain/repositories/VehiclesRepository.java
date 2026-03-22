package vn.rescue.core.domain.repositories;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Vehicles;
import java.util.Optional;

import java.util.List;

@Repository
public interface VehiclesRepository extends MongoRepository<Vehicles, String> {
    List<Vehicles> findByStatusIgnoreCase(String status);

    boolean existsByLicensePlate(String licensePlate);

    Optional<Vehicles> findByLicensePlate(String licensePlate);

    Optional<Vehicles> findByTeamId(String teamId);

    List<Vehicles> findByTeamIdAndStatus(String teamId, String status);
    // Sử dụng Query Method để Spring tự động xử lý null và khớp trường
    // Phương thức này sẽ tìm kiếm chính xác theo Loại và Trạng thái
    Page<Vehicles> findByVehicleTypeContainingAndStatusContaining(
            String vehicleType, String status, Pageable pageable
    );

    @org.springframework.lang.NonNull
    Page<Vehicles> findAll(@org.springframework.lang.NonNull Pageable pageable);
}