package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RescueRequest;

import java.util.Optional;

@Repository
public interface RescueRequestRepository extends MongoRepository<RescueRequest, String> {
    long countByStatus(String status);
    Optional<RescueRequest> findByCustomId(String customId);
    long countByCustomIdIsNotNull();
}
