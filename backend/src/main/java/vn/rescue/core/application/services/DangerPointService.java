package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.DangerPoint;
import vn.rescue.core.domain.repositories.DangerPointRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

@Service
@RequiredArgsConstructor
public class DangerPointService {
    private final DangerPointRepository dangerPointRepository;

    private static final double EARTH_RADIUS_METERS = 6371000.0;

    public List<DangerPoint> getAllDangerPoints() {
        return dangerPointRepository.findAll();
    }

    /**
     * KCPM-101: Lọc danh sách điểm nguy hiểm theo tọa độ GPS và bán kính (mét)
     * Áp dụng công thức Haversine tính khoảng cách trắc địa trên mặt cầu.
     */
    public List<DangerPoint> getDangerPointsNearby(Double lat, Double lng, Double radius) {
        if (lat == null && lng == null && radius == null) {
            return getAllDangerPoints();
        }

        if (lat == null || lng == null || radius == null) {
            throw new BadRequestException("Cần cung cấp đầy đủ tọa độ lat, lng và bán kính radius (mét)");
        }

        if (lat < -90.0 || lat > 90.0) {
            throw new BadRequestException("Vĩ độ (lat) không hợp lệ, phải nằm trong khoảng [-90, 90]");
        }

        if (lng < -180.0 || lng > 180.0) {
            throw new BadRequestException("Kinh độ (lng) không hợp lệ, phải nằm trong khoảng [-180, 180]");
        }

        if (radius <= 0) {
            throw new BadRequestException("Bán kính tìm kiếm (radius) phải lớn hơn 0 mét");
        }

        List<DangerPoint> allPoints = dangerPointRepository.findAll();
        return allPoints.stream()
                .filter(p -> p.getLatitude() != null && p.getLongitude() != null)
                .filter(p -> calculateDistanceMeters(lat, lng, p.getLatitude(), p.getLongitude()) <= radius)
                .collect(Collectors.toList());
    }

    /**
     * Tính khoảng cách giữa hai tọa độ GPS theo công thức Haversine (đơn vị: mét)
     */
    public double calculateDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_METERS * c;
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
