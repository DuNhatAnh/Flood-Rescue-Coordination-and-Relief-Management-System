package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.SafetyReport;

@Repository
public interface SafetyReportRepository extends MongoRepository<SafetyReport, String> {
}
