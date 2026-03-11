package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Distribution;

@Repository
public interface DistributionRepository extends MongoRepository<Distribution, String> {
}
