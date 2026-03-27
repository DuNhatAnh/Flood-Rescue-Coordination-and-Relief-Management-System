package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RescueRequest;
import java.util.List;
import java.util.Optional;
import java.util.Collection;

@Repository
public interface RescueRequestRepository extends MongoRepository<RescueRequest, String> {
    List<RescueRequest> findByStatus(String status);
    long countByStatus(String status);
    Optional<RescueRequest> findFirstByCustomId(String customId);
    long countByCustomIdIsNotNull();

    boolean existsByTeamIdAndStatusIn(String teamId, Collection<String> statuses);

    boolean existsByTeamIdAndStatus(String teamId, String status);

    List<RescueRequest> findByStatusOrderByCreatedAtDesc(String status);
}
