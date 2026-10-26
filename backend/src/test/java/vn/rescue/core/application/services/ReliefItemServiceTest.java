package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.application.dto.ReliefItemRequest;
import vn.rescue.core.domain.entities.ReliefItem;
import vn.rescue.core.domain.repositories.ReliefItemRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-28 [KCPM-47]: Unit Test cho Danh mục Hàng cứu trợ (ReliefItemService)")
class ReliefItemServiceTest {

    @Mock
    private ReliefItemRepository reliefItemRepository;

    @InjectMocks
    private ReliefItemService reliefItemService;

    @Test
    @DisplayName("KCPM-28 [Subtask 2]: Tạo mặt hàng thiếu tên -> Chặn ném 400 BadRequestException")
    void testCreateReliefItem_WhenNameIsBlank_ShouldThrowBadRequestException() {
        ReliefItemRequest request = new ReliefItemRequest();
        request.setItemName("   ");
        request.setUnit("Hộp");

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            reliefItemService.createReliefItem(request);
        });

        assertTrue(exception.getMessage().contains("Tên mặt hàng cứu trợ không được để trống"));
        verify(reliefItemRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28 [Subtask 2]: Tạo mặt hàng thiếu đơn vị tính -> Chặn ném 400 BadRequestException")
    void testCreateReliefItem_WhenUnitIsBlank_ShouldThrowBadRequestException() {
        ReliefItemRequest request = new ReliefItemRequest();
        request.setItemName("Lương khô quân đội");
        request.setUnit("");

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            reliefItemService.createReliefItem(request);
        });

        assertTrue(exception.getMessage().contains("Đơn vị tính không được để trống"));
        verify(reliefItemRepository, never()).save(any());
    }

    @Test
    @DisplayName("KCPM-28: Xóa mặt hàng với ID không tồn tại -> Chặn ném 404 ResourceNotFoundException")
    void testDeleteReliefItem_WhenIdNotExists_ShouldThrowResourceNotFoundException() {
        String nonExistId = "ITEM-NOT-EXIST";
        when(reliefItemRepository.existsById(nonExistId)).thenReturn(false);

        ResourceNotFoundException exception = assertThrows(ResourceNotFoundException.class, () -> {
            reliefItemService.deleteReliefItem(nonExistId);
        });

        assertTrue(exception.getMessage().contains("Không tìm thấy mặt hàng cứu trợ với ID: " + nonExistId));
        verify(reliefItemRepository, never()).deleteById(anyString());
    }

    @Test
    @DisplayName("KCPM-28: Tạo mặt hàng cứu trợ hợp lệ -> Lưu thành công vào DB")
    void testCreateReliefItem_Success() {
        ReliefItemRequest request = new ReliefItemRequest();
        request.setItemName("Thuốc sát trùng Povidine");
        request.setUnit("Chai");
        request.setDescription("Dùng sơ cứu vết thương mùa lũ");

        when(reliefItemRepository.save(any(ReliefItem.class))).thenAnswer(invocation -> {
            ReliefItem item = invocation.getArgument(0);
            item.setId("ITEM-POVIDINE-01");
            return item;
        });

        ReliefItem created = reliefItemService.createReliefItem(request);

        assertNotNull(created);
        assertEquals("ITEM-POVIDINE-01", created.getId());
        assertEquals("Thuốc sát trùng Povidine", created.getItemName());
        assertEquals("Chai", created.getUnit());
        verify(reliefItemRepository, times(1)).save(any(ReliefItem.class));
    }
}
