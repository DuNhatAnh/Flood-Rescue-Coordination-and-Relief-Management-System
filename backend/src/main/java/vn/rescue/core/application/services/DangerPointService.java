package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.DangerPoint;
import vn.rescue.core.domain.repositories.DangerPointRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class DangerPointService {
    private final DangerPointRepository dangerPointRepository;

    public List<DangerPoint> getAllDangerPoints() {
        return dangerPointRepository.findAll();
    }

    public DangerPoint createDangerPoint(DangerPoint dangerPoint) {
        dangerPoint.setCreatedAt(LocalDateTime.now());
        dangerPoint.setUpdatedAt(LocalDateTime.now());
        return dangerPointRepository.save(dangerPoint);
    }

    public void deleteDangerPoint(String id) {
        dangerPointRepository.deleteById(id);
    }

    public Optional<DangerPoint> getDangerPointById(String id) {
        return dangerPointRepository.findById(id);
    }
}
