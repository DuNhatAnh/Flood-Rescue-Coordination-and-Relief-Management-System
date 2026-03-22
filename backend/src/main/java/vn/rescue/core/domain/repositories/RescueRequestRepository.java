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

    //Them dong nay de kiem tra xem co request nao dang dinh toi team nayboolean existsByTeamIdAndStatusIn(String teamId, Collection<String> statuses);
    //
    //    // Hoặc nếu bạn muốn kiểm tra đơn giản hơn cho 1 trạng thái
    //    boolean existsByTeamIdAndStatus(String teamId, String status);
    boolean existsByTeamIdAndStatusIn(String teamId, Collection<String> statuses);

    // Hoặc nếu bạn muốn kiểm tra đơn giản hơn cho 1 trạng thái
    boolean existsByTeamIdAndStatus(String teamId, String status);

    List<RescueRequest> findByStatusOrderByCreatedAtDesc(String status);
}
