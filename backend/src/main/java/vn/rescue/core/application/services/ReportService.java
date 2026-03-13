package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ReportService {
    private final RescueRequestRepository rescueRequestRepository;
    private final UserRepository userRepository;
    private final RescueTeamRepository rescueTeamRepository;

    public Map<String, Object> getGeneralStats() {
        return Map.of(
            "totalUsers", userRepository.count(),
            "totalRequests", rescueRequestRepository.count(),
            "pendingRequests", rescueRequestRepository.countByStatus("PENDING"),
            "completedRequests", rescueRequestRepository.countByStatus("COMPLETED"),
            "totalTeams", rescueTeamRepository.count()
        );
    }
}
