package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.SystemLog;

@Repository
public interface SystemLogRepository extends MongoRepository<SystemLog, String> {
}
