package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import vn.rescue.core.presentation.common.ApiResponse;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * KCPM-117: Unit Test cho API upload tập tin đa dụng POST /api/v1/files/upload (FileController).
 * FileController ghi file thật vào thư mục "uploads" (tương đối với thư mục chạy test),
 * nên mỗi test ghi nhận các file có sẵn trước khi chạy và xóa các file mới sinh ra sau khi chạy.
 */
@DisplayName("KCPM-117: Unit Test cho Upload tập tin đa dụng (FileController)")
class FileControllerTest {

    private static final Path UPLOAD_DIR = Paths.get("uploads");

    private FileController fileController;
    private Set<Path> filesBefore;

    @BeforeEach
    void setUp() throws IOException {
        fileController = new FileController();
        filesBefore = listUploads();
    }

    @AfterEach
    void cleanUp() throws IOException {
        for (Path p : listUploads()) {
            if (!filesBefore.contains(p)) {
                Files.deleteIfExists(p);
            }
        }
    }

    private static Set<Path> listUploads() throws IOException {
        Set<Path> result = new HashSet<>();
        if (Files.exists(UPLOAD_DIR)) {
            try (Stream<Path> s = Files.list(UPLOAD_DIR)) {
                s.forEach(result::add);
            }
        }
        return result;
    }

    private static Path storedPath(ApiResponse<String> body) {
        // data có dạng "/uploads/<tên-file>"
        return UPLOAD_DIR.resolve(body.getData().substring("/uploads/".length()));
    }

    @Test
    @DisplayName("TC_FILE_01: Upload khi không gửi file (null) -> HTTP 400 'File is empty'")
    void testUploadFile_NullFile_ShouldReturnBadRequest() {
        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getMessage()).isEqualTo("File is empty");
    }

    @Test
    @DisplayName("TC_FILE_02: Upload file rỗng 0 byte -> HTTP 400 'File is empty', không lưu file nào")
    void testUploadFile_EmptyFile_ShouldReturnBadRequest() throws IOException {
        MockMultipartFile empty = new MockMultipartFile("file", "empty.pdf", "application/pdf", new byte[0]);

        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(empty);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody().getMessage()).isEqualTo("File is empty");
        assertThat(listUploads()).isEqualTo(filesBefore);
    }

    @Test
    @DisplayName("TC_FILE_09: File báo không rỗng nhưng kích thước 0 byte (getSize = 0) -> HTTP 400 'File is empty'")
    void testUploadFile_ZeroSizeNotEmptyFlag_ShouldReturnBadRequest() {
        MultipartFile zeroSize = mock(MultipartFile.class);
        when(zeroSize.isEmpty()).thenReturn(false);
        when(zeroSize.getSize()).thenReturn(0L);

        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(zeroSize);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody().getMessage()).isEqualTo("File is empty");
    }

    @Test
    @DisplayName("TC_FILE_03: Upload tài liệu hợp lệ (.pdf) -> HTTP 200, lưu đúng nội dung, tên file mới giữ đuôi .pdf")
    void testUploadFile_ValidPdf_ShouldStoreFileAndReturnUrl() throws IOException {
        byte[] content = "Bien ban hien truong cuu ho".getBytes();
        MockMultipartFile pdf = new MockMultipartFile("file", "bien-ban.pdf", "application/pdf", content);

        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(pdf);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getMessage()).isEqualTo("File uploaded successfully");
        assertThat(response.getBody().getData()).startsWith("/uploads/").endsWith(".pdf");
        assertThat(response.getBody().getData()).doesNotContain("bien-ban");
        Path saved = storedPath(response.getBody());
        assertThat(saved).exists();
        assertThat(Files.readAllBytes(saved)).isEqualTo(content);
    }

    @Test
    @DisplayName("TC_FILE_04: Upload 2 lần cùng tên file -> sinh 2 tên khác nhau (UUID), không ghi đè")
    void testUploadFile_SameNameTwice_ShouldGenerateUniqueNames() {
        MockMultipartFile first = new MockMultipartFile("file", "anh.png", "image/png", new byte[]{1, 2, 3});
        MockMultipartFile second = new MockMultipartFile("file", "anh.png", "image/png", new byte[]{4, 5, 6});

        String url1 = fileController.uploadFile(first).getBody().getData();
        String url2 = fileController.uploadFile(second).getBody().getData();

        assertThat(url1).isNotEqualTo(url2);
        assertThat(url1).endsWith(".png");
        assertThat(url2).endsWith(".png");
    }

    @Test
    @DisplayName("TC_FILE_05: Upload file không có phần mở rộng -> HTTP 200, tên file lưu không có đuôi")
    void testUploadFile_NoExtension_ShouldStoreWithoutExtension() {
        MockMultipartFile noExt = new MockMultipartFile("file", "README", "text/plain", "noi dung".getBytes());

        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(noExt);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getData()).doesNotContain(".");
        assertThat(storedPath(response.getBody())).exists();
    }

    @Test
    @DisplayName("TC_FILE_06: Upload file không có tên gốc (originalFilename = null) -> HTTP 200, vẫn lưu được")
    void testUploadFile_NullOriginalName_ShouldStillStore() throws IOException {
        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getSize()).thenReturn(3L);
        when(file.getOriginalFilename()).thenReturn(null);
        when(file.getInputStream()).thenReturn(new java.io.ByteArrayInputStream(new byte[]{7, 8, 9}));

        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(file);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(storedPath(response.getBody())).exists();
    }

    @Test
    @DisplayName("TC_FILE_07: Lỗi đọc dữ liệu file khi lưu (IOException) -> HTTP 500 'Could not upload file'")
    void testUploadFile_IOException_ShouldReturnInternalServerError() throws IOException {
        MultipartFile broken = mock(MultipartFile.class);
        when(broken.isEmpty()).thenReturn(false);
        when(broken.getSize()).thenReturn(10L);
        when(broken.getOriginalFilename()).thenReturn("hong.jpg");
        when(broken.getInputStream()).thenThrow(new IOException("Disk read error"));

        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(broken);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody().getMessage()).startsWith("Could not upload file").contains("Disk read error");
    }

    @Test
    @DisplayName("TC_FILE_08: Thư mục uploads chưa tồn tại -> tự tạo thư mục rồi lưu file thành công")
    void testUploadFile_UploadDirMissing_ShouldCreateDirectory() throws IOException {
        // Chỉ chạy khi thư mục đang trống, để không xóa file thật của người khác
        assumeTrue(filesBefore.isEmpty(), "Bỏ qua: thư mục uploads đang có file");
        Files.deleteIfExists(UPLOAD_DIR);
        MockMultipartFile img = new MockMultipartFile("file", "hien-truong.jpg", "image/jpeg", new byte[]{1, 1, 2});

        ResponseEntity<ApiResponse<String>> response = fileController.uploadFile(img);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(UPLOAD_DIR).isDirectory();
        assertThat(storedPath(response.getBody())).exists();
    }
}
