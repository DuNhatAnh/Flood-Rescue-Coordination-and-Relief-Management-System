package vn.rescue.core.domain.repositories;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Vehicles;

@Repository
public interface VehiclesRepository extends JpaRepository<Vehicles, Integer> {
    // Integer ở đây tương ứng với kiểu dữ liệu của vehicle_id
}
