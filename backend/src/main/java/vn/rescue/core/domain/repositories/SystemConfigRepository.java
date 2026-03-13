package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.SystemConfig;
import java.util.Optional;

@Repository
public interface SystemConfigRepository extends MongoRepository<SystemConfig, String> {
    Optional<SystemConfig> findByKey(String key);
}
