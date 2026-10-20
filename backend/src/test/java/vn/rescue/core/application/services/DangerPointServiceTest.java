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
}
