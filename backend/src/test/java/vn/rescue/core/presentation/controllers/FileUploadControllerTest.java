package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import vn.rescue.core.application.services.FileStorageService;
import vn.rescue.core.presentation.common.ApiResponse;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class FileUploadControllerTest {

    private FileUploadController fileUploadController;

    static class StubFileStorageService extends FileStorageService {
        @Override
        public String save(MultipartFile file) {
            if (file == null || file.isEmpty()) {
                throw new IllegalArgumentException("File tải lên không được để rỗng");
            }
            return "/uploads/test_image.png";
        }
    }

    @BeforeEach
    void setUp() {
        fileUploadController = new FileUploadController(new StubFileStorageService());
    }

    @Test
    @DisplayName("Upload file null hoặc rỗng phải trả về HTTP 400 Bad Request")
    void uploadEmptyFile_shouldReturnBadRequest() {
        MockMultipartFile emptyFile = new MockMultipartFile("file", "empty.png", "image/png", new byte[0]);
        ResponseEntity<?> response = fileUploadController.uploadImage(emptyFile);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isInstanceOf(ApiResponse.class);
        ApiResponse<?> apiResponse = (ApiResponse<?>) response.getBody();
        assertThat(apiResponse.getMessage()).contains("rỗng");

        // Test with null
        ResponseEntity<?> nullResponse = fileUploadController.uploadImage(null);
        assertThat(nullResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    @DisplayName("Upload file sai định dạng (không phải ảnh: .txt, .exe) phải trả về HTTP 400 Bad Request")
    void uploadInvalidFormatFile_shouldReturnBadRequest() {
        MockMultipartFile txtFile = new MockMultipartFile("file", "document.txt", "text/plain", "hello world".getBytes());
        ResponseEntity<?> response = fileUploadController.uploadImage(txtFile);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isInstanceOf(ApiResponse.class);
        ApiResponse<?> apiResponse = (ApiResponse<?>) response.getBody();
        assertThat(apiResponse.getMessage()).contains("Định dạng file không hợp lệ");

        MockMultipartFile exeFile = new MockMultipartFile("file", "program.exe", "application/octet-stream", "dummy bytes".getBytes());
        ResponseEntity<?> exeResponse = fileUploadController.uploadImage(exeFile);
        assertThat(exeResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    @DisplayName("Upload file hình ảnh hợp lệ (.png, .jpg) phải trả về HTTP 200 OK")
    void uploadValidImage_shouldReturnOk() {
        MockMultipartFile validImage = new MockMultipartFile(
                "file",
                "photo.png",
                "image/png",
                new byte[]{1, 2, 3, 4}
        );

        ResponseEntity<?> response = fileUploadController.uploadImage(validImage);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isInstanceOf(Map.class);
        @SuppressWarnings("unchecked")
        Map<String, Object> body = (Map<String, Object>) response.getBody();
        assertThat(body.get("url")).isEqualTo("/uploads/test_image.png");
        assertThat(body.get("success")).isEqualTo(true);
    }
}
