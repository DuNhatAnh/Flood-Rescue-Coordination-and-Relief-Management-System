package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import vn.rescue.core.application.services.FileStorageService;
import vn.rescue.core.application.services.RescueRequestService;
import vn.rescue.core.domain.entities.Attachment;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.AttachmentRepository;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-111: Kiểm thử Controller tệp đính kèm: AttachmentController")
class AttachmentControllerTest {

    @Mock
    private FileStorageService fileStorageService;

    @Mock
    private AttachmentRepository attachmentRepository;

    @Mock
    private RescueRequestService rescueRequestService;

    @InjectMocks
    private AttachmentController attachmentController;

    private RescueRequest sampleRequest;

    @BeforeEach
    void setUp() {
        sampleRequest = new RescueRequest();
        sampleRequest.setId("REQ-001");
        sampleRequest.setCitizenName("Nguyễn Văn A");
    }

    @Test
    @DisplayName("TC_ATT_01: Tải lên tệp đính kèm hiện trường thành công -> Trả về HTTP 200 và URL tệp")
    void testUploadFile_WhenValid_ShouldReturnSuccess() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "hien_truong.jpg", "image/jpeg", "fake-image-bytes".getBytes()
        );

        when(rescueRequestService.getById("REQ-001")).thenReturn(sampleRequest);
        when(fileStorageService.save(file)).thenReturn("/uploads/hien_truong.jpg");
        when(attachmentRepository.save(any(Attachment.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ResponseEntity<ApiResponse<String>> response = attachmentController.uploadFile(file, "REQ-001");

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("/uploads/hien_truong.jpg", response.getBody().getData());
        assertEquals("Tải lên thành công", response.getBody().getMessage());

        verify(rescueRequestService, times(1)).getById("REQ-001");
        verify(fileStorageService, times(1)).save(file);
        verify(attachmentRepository, times(1)).save(any(Attachment.class));
    }

    @Test
    @DisplayName("TC_ATT_02: Tải lên tệp đính kèm với đơn cứu hộ không tồn tại -> Ném ResourceNotFoundException (404)")
    void testUploadFile_WhenRequestNotFound_ShouldThrowException() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "hien_truong.jpg", "image/jpeg", "fake-image-bytes".getBytes()
        );

        when(rescueRequestService.getById("REQ-999"))
                .thenThrow(new ResourceNotFoundException("Không tìm thấy yêu cầu cứu hộ"));

        assertThrows(ResourceNotFoundException.class, () -> {
            attachmentController.uploadFile(file, "REQ-999");
        });

        verify(rescueRequestService, times(1)).getById("REQ-999");
        verify(fileStorageService, never()).save(any());
        verify(attachmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_ATT_03: Lấy danh sách tệp đính kèm theo requestId hợp lệ -> Trả về danh sách tệp và HTTP 200")
    void testGetAttachmentsByRequestId_WhenExists_ShouldReturnList() {
        Attachment att1 = new Attachment();
        att1.setId("ATT-01");
        att1.setRequestId("REQ-001");
        att1.setFileUrl("/uploads/anh1.jpg");

        Attachment att2 = new Attachment();
        att2.setId("ATT-02");
        att2.setRequestId("REQ-001");
        att2.setFileUrl("/uploads/anh2.jpg");

        when(attachmentRepository.findByRequestId("REQ-001")).thenReturn(List.of(att1, att2));

        ResponseEntity<ApiResponse<List<Attachment>>> response = attachmentController.getAttachmentsByRequestId("REQ-001");

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(2, response.getBody().getData().size());
        assertEquals("Lấy danh sách tệp đính kèm thành công", response.getBody().getMessage());

        verify(attachmentRepository, times(1)).findByRequestId("REQ-001");
    }

    @Test
    @DisplayName("TC_ATT_04: Lấy danh sách tệp đính kèm khi đơn chưa có tệp -> Trả về danh sách rỗng và HTTP 200")
    void testGetAttachmentsByRequestId_WhenNoAttachments_ShouldReturnEmptyList() {
        when(attachmentRepository.findByRequestId("REQ-EMPTY")).thenReturn(List.of());

        ResponseEntity<ApiResponse<List<Attachment>>> response = attachmentController.getAttachmentsByRequestId("REQ-EMPTY");

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertTrue(response.getBody().getData().isEmpty());

        verify(attachmentRepository, times(1)).findByRequestId("REQ-EMPTY");
    }
}
