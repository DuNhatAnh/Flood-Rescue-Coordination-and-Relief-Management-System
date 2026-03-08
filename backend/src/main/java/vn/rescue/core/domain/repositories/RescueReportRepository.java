package vn.rescue.core.domain.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RescueReport;

@Repository
public interface RescueReportRepository extends JpaRepository<RescueReport, Long> {
}
