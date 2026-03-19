package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RescueTeam;

import java.util.List;

@Repository
public interface RescueTeamRepository extends MongoRepository<RescueTeam, String> {
    List<RescueTeam> findByStatusIgnoreCase(String status);
}
