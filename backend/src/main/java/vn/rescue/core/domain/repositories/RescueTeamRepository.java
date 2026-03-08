package vn.rescue.core.domain.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RescueTeam;

@Repository
public interface RescueTeamRepository extends JpaRepository<RescueTeam, Integer> {
}
