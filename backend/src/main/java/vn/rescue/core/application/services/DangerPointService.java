package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.DangerPoint;
import vn.rescue.core.domain.repositories.DangerPointRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

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

    public DangerPoint updateDangerPoint(String id, DangerPoint updatedData) {
        DangerPoint existing = dangerPointRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy điểm nguy hiểm với ID: " + id));
        if (updatedData.getName() != null) existing.setName(updatedData.getName());
        if (updatedData.getAddress() != null) existing.setAddress(updatedData.getAddress());
        if (updatedData.getLatitude() != null) existing.setLatitude(updatedData.getLatitude());
        if (updatedData.getLongitude() != null) existing.setLongitude(updatedData.getLongitude());
        if (updatedData.getDepth() != null) existing.setDepth(updatedData.getDepth());
        existing.setUpdatedAt(LocalDateTime.now());
        return dangerPointRepository.save(existing);
    }

    public void deleteDangerPoint(String id) {
        if (!dangerPointRepository.existsById(id)) {
            throw new ResourceNotFoundException("Không tìm thấy điểm nguy hiểm với ID: " + id);
        }
        dangerPointRepository.deleteById(id);
    }

    public Optional<DangerPoint> getDangerPointById(String id) {
        return dangerPointRepository.findById(id);
    }
}
