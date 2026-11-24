package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.domain.entities.DangerPoint;
import vn.rescue.core.domain.repositories.DangerPointRepository;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-41: Kiểm thử Xử lý ngoại lệ 404 cho DangerPoint")
class DangerPointServiceTest {

    @Mock
    private DangerPointRepository dangerPointRepository;

    @InjectMocks
    private DangerPointService dangerPointService;

    @Test
    @DisplayName("Xóa DangerPoint với ID không tồn tại -> Ném ResourceNotFoundException")
    void testDeleteDangerPoint_WhenIdNotExists_ShouldThrowResourceNotFoundException() {
        String nonExistingId = "DANGER-999";
        when(dangerPointRepository.existsById(nonExistingId)).thenReturn(false);

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            dangerPointService.deleteDangerPoint(nonExistingId);
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy điểm nguy hiểm với ID: " + nonExistingId));
        verify(dangerPointRepository, never()).deleteById(any());
    }

    @Test
    @DisplayName("Xóa DangerPoint với ID tồn tại -> Gọi deleteById thành công")
    void testDeleteDangerPoint_WhenIdExists_ShouldDeleteSuccessfully() {
        String existingId = "DANGER-001";
        when(dangerPointRepository.existsById(existingId)).thenReturn(true);

        assertDoesNotThrow(() -> {
            dangerPointService.deleteDangerPoint(existingId);
        });

        verify(dangerPointRepository, times(1)).deleteById(existingId);
    }

    @Test
    @DisplayName("Cập nhật DangerPoint với ID không tồn tại -> Ném ResourceNotFoundException")
    void testUpdateDangerPoint_WhenIdNotExists_ShouldThrowResourceNotFoundException() {
        String nonExistingId = "DANGER-999";
        when(dangerPointRepository.findById(nonExistingId)).thenReturn(Optional.empty());

        DangerPoint updateData = new DangerPoint();
        updateData.setName("Vùng nước sâu mới");

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            dangerPointService.updateDangerPoint(nonExistingId, updateData);
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy điểm nguy hiểm với ID: " + nonExistingId));
        verify(dangerPointRepository, never()).save(any());
    }

    @Test
    @DisplayName("Cập nhật DangerPoint với ID tồn tại -> Cập nhật thành công")
    void testUpdateDangerPoint_WhenIdExists_ShouldUpdateSuccessfully() {
        String existingId = "DANGER-001";
        DangerPoint existingPoint = new DangerPoint();
        existingPoint.setId(existingId);
        existingPoint.setName("Cột điện ngập nước");
        existingPoint.setDepth(1.5);

        when(dangerPointRepository.findById(existingId)).thenReturn(Optional.of(existingPoint));
        when(dangerPointRepository.save(any(DangerPoint.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DangerPoint updateData = new DangerPoint();
        updateData.setName("Cột điện ngập nước sâu nguy hiểm");
        updateData.setDepth(2.5);

        DangerPoint result = dangerPointService.updateDangerPoint(existingId, updateData);

        assertNotNull(result);
        assertEquals("Cột điện ngập nước sâu nguy hiểm", result.getName());
        assertEquals(2.5, result.getDepth());
        assertNotNull(result.getUpdatedAt());
        verify(dangerPointRepository).save(existingPoint);
    }

    // =========================================================================
    // KCPM-101: BỔ SUNG KIỂM THỬ LỌC ĐIỂM NGUY HIỂM THEO BÁN KÍNH GPS (HAVERSINE)
    // =========================================================================

    @Test
    @DisplayName("KCPM-101: Lọc điểm nguy hiểm trong bán kính 1000m -> Chỉ trả về điểm gần (<= 1000m)")
    void testGetDangerPointsNearby_WhenWithinRadius_ShouldReturnOnlyNearbyPoints() {
        // Tọa độ người dân cần cứu: 16.0610, 108.2230 (Đà Nẵng)
        double centerLat = 16.0610;
        double centerLng = 108.2230;
        double radiusMeters = 1000.0; // 1km

        // Điểm 1: Cách ~200m (Gần - Hợp lệ)
        DangerPoint nearPoint = DangerPoint.builder()
                .id("DP-NEAR-01")
                .name("Điểm ngập sâu ngã tư")
                .latitude(16.0620)
                .longitude(16.0620 != 0 ? 108.2240 : 108.2230)
                .depth(1.8)
                .build();

        // Điểm 2: Cách ~15km (Xa ngoài bán kính)
        DangerPoint farPoint = DangerPoint.builder()
                .id("DP-FAR-02")
                .name("Sạt lở đèo Hải Vân")
                .latitude(16.1500)
                .longitude(108.1200)
                .depth(3.0)
                .build();

        when(dangerPointRepository.findAll()).thenReturn(java.util.List.of(nearPoint, farPoint));

        var result = dangerPointService.getDangerPointsNearby(centerLat, centerLng, radiusMeters);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("DP-NEAR-01", result.get(0).getId());
    }

    @Test
    @DisplayName("KCPM-101: Không truyền tọa độ -> Trả về toàn bộ danh sách điểm nguy hiểm")
    void testGetDangerPointsNearby_WhenNoCoordsProvided_ShouldReturnAll() {
        DangerPoint p1 = DangerPoint.builder().id("DP-01").name("Điểm 1").build();
        DangerPoint p2 = DangerPoint.builder().id("DP-02").name("Điểm 2").build();
        when(dangerPointRepository.findAll()).thenReturn(java.util.List.of(p1, p2));

        var result = dangerPointService.getDangerPointsNearby(null, null, null);

        assertNotNull(result);
        assertEquals(2, result.size());
    }

    @Test
    @DisplayName("KCPM-101: BVA Bán kính <= 0 -> Ném BadRequestException (400)")
    void testGetDangerPointsNearby_WhenRadiusZeroOrNegative_ShouldThrowBadRequestException() {
        var exZero = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.getDangerPointsNearby(16.061, 108.223, 0.0);
        });
        assertTrue(exZero.getMessage().contains("Bán kính tìm kiếm (radius) phải lớn hơn 0"));

        var exNeg = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.getDangerPointsNearby(16.061, 108.223, -50.0);
        });
        assertTrue(exNeg.getMessage().contains("Bán kính tìm kiếm (radius) phải lớn hơn 0"));
    }

    @Test
    @DisplayName("KCPM-101: BVA Tọa độ GPS ngoài khoảng hợp lệ -> Ném BadRequestException (400)")
    void testGetDangerPointsNearby_WhenInvalidCoordinates_ShouldThrowBadRequestException() {
        // Vĩ độ ngoài [-90, 90]
        var exLat = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.getDangerPointsNearby(95.0, 108.223, 500.0);
        });
        assertTrue(exLat.getMessage().contains("Vĩ độ (lat) không hợp lệ"));

        // Kinh độ ngoài [-180, 180]
        var exLng = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.getDangerPointsNearby(16.061, 200.0, 500.0);
        });
        assertTrue(exLng.getMessage().contains("Kinh độ (lng) không hợp lệ"));
    }

    @Test
    @DisplayName("KCPM-101: Truyền thiếu 1 trong 3 tham số (lat, lng, radius) -> Ném BadRequestException (400)")
    void testGetDangerPointsNearby_WhenMissingParams_ShouldThrowBadRequestException() {
        var ex = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.getDangerPointsNearby(16.061, null, 500.0);
        });
        assertTrue(ex.getMessage().contains("Cần cung cấp đầy đủ tọa độ lat, lng và bán kính radius"));
    }

    // =========================================================================
    // KCPM-111: BỔ SUNG KIỂM THỬ BVA BÁN KÍNH QUÉT RADAR & MỰC NƯỚC NGUY HIỂM
    // =========================================================================

    @Test
    @DisplayName("KCPM-111: BVA Bán kính quét radiusInMeters = 50m (Biên dưới hợp lệ) -> Pass")
    void testGetDangerPointsNearby_WhenRadius50Meters_ShouldPass() {
        when(dangerPointRepository.findAll()).thenReturn(java.util.List.of());
        assertDoesNotThrow(() -> {
            dangerPointService.getDangerPointsNearby(16.061, 108.223, 50.0);
        });
    }

    @Test
    @DisplayName("KCPM-111: BVA Bán kính quét radiusInMeters = 49m (Dưới biên) -> Ném BadRequestException (400)")
    void testGetDangerPointsNearby_WhenRadius49Meters_ShouldThrowBadRequestException() {
        var ex = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.getDangerPointsNearby(16.061, 108.223, 49.0);
        });
        assertTrue(ex.getMessage().contains("Bán kính quét radar tối thiểu là 50m"));
    }

    @Test
    @DisplayName("KCPM-111: BVA Mực nước depth = 0.1m (10cm) và 5.0m (500cm) -> Pass")
    void testCreateDangerPoint_WhenDepthValid_ShouldPass() {
        DangerPoint dpMin = DangerPoint.builder().name("Điểm ngập min").depth(0.1).build();
        when(dangerPointRepository.save(any(DangerPoint.class))).thenAnswer(inv -> inv.getArgument(0));

        assertDoesNotThrow(() -> {
            dangerPointService.createDangerPoint(dpMin);
        });

        DangerPoint dpMax = DangerPoint.builder().name("Điểm ngập max").depth(5.0).build();
        assertDoesNotThrow(() -> {
            dangerPointService.createDangerPoint(dpMax);
        });
    }

    @Test
    @DisplayName("KCPM-111: BVA Mực nước depth <= 0m -> Ném BadRequestException (400)")
    void testCreateDangerPoint_WhenDepthZeroOrNegative_ShouldThrowBadRequestException() {
        DangerPoint dpZero = DangerPoint.builder().name("Điểm ngập 0").depth(0.0).build();
        var exZero = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.createDangerPoint(dpZero);
        });
        assertTrue(exZero.getMessage().contains("Mực nước nguy hiểm (depth) phải lớn hơn 0"));

        DangerPoint dpNeg = DangerPoint.builder().name("Điểm ngập âm").depth(-1.0).build();
        var exNeg = assertThrows(vn.rescue.core.presentation.exceptions.BadRequestException.class, () -> {
            dangerPointService.createDangerPoint(dpNeg);
        });
        assertTrue(exNeg.getMessage().contains("Mực nước nguy hiểm (depth) phải lớn hơn 0"));
    }
}
