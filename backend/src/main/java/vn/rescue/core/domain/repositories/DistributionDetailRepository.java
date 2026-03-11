package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.DistributionDetail;

@Repository
public interface DistributionDetailRepository extends MongoRepository<DistributionDetail, String> {
}
