package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Assignment;

import java.util.List;
import java.util.Optional;

@Repository
public interface AssignmentRepository extends MongoRepository<Assignment, String> {
    List<Assignment> findByTeamId(String teamId);
    Optional<Assignment> findByVehicleIdAndStatus(String vehicleId, String status);
    Optional<Assignment> findByRequestId(String requestId);

}
