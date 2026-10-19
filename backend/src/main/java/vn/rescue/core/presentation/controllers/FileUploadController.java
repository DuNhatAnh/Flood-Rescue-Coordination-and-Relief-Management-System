package vn.rescue.core.presentation.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.rescue.core.application.services.FileStorageService;
import vn.rescue.core.presentation.common.ApiResponse;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/upload")
public class FileUploadController {

    private final FileStorageService fileStorageService;

    public FileUploadController(FileStorageService fileStorageService) {
        this.fileStorageService = fileStorageService;
    }

    private static final List<String> ALLOWED_IMAGE_EXTENSIONS = List.of(
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg"
    );

    @PostMapping("/image")
    public ResponseEntity<?> uploadImage(@RequestParam(value = "file", required = false) MultipartFile file) {
        // Kiểm tra file rỗng hoặc không được truyền
        if (file == null || file.isEmpty() || file.getSize() == 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(400, "File tải lên bị rỗng. Vui lòng chọn tệp hợp lệ."));
        }

        // Kiểm tra phần mở rộng file (extension)
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !originalFilename.contains(".")) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(400, "Tên file không hợp lệ hoặc thiếu phần mở rộng định dạng."));
        }

        String extension = originalFilename.substring(originalFilename.lastIndexOf(".")).toLowerCase();
        if (!ALLOWED_IMAGE_EXTENSIONS.contains(extension)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(400, "Định dạng file không hợp lệ. Chỉ chấp nhận các định dạng ảnh: "
                            + String.join(", ", ALLOWED_IMAGE_EXTENSIONS)));
        }

        // Kiểm tra MIME type
        String contentType = file.getContentType();
        if (contentType != null && !contentType.isBlank()
                && !contentType.toLowerCase().startsWith("image/")
                && !contentType.equalsIgnoreCase("application/octet-stream")) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(400, "MIME type không hợp lệ: " + contentType + ". Chỉ chấp nhận file hình ảnh."));
        }

        String path = fileStorageService.save(file);
        // Trả về JSON chứa URL tương thích với cả Map và ApiResponse
        return ResponseEntity.ok(Map.of(
                "url", path,
                "success", true,
                "code", 200,
                "message", "Tải lên ảnh thành công"
        ));
    }
}
