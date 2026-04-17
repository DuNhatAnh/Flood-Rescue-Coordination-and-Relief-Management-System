package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RescueReport;

import java.util.Optional;

@Repository
public interface RescueReportRepository extends MongoRepository<RescueReport, String> {
    Optional<RescueReport> findByAssignmentId(String assignmentId);
}
