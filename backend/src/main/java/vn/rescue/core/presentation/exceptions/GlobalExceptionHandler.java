package vn.rescue.core.presentation.exceptions;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import vn.rescue.core.presentation.common.ApiResponse;

import java.util.stream.Collectors;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // ============================================================
    // 1. CÁC NGOẠI LỆ NGHIỆP VỤ & TÀI NGUYÊN (404, 409, 400)
    // ============================================================

    /**
     * Bắt lỗi không tìm thấy tài nguyên (Role, User, Team, DangerPoint, Vehicle...) -> HTTP 404
     */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleResourceNotFoundException(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(404, ex.getMessage()));
    }

    /**
     * Bắt lỗi trùng lặp tài nguyên (Tên Role, Email...) -> HTTP 409
     */
    @ExceptionHandler(DuplicateResourceException.class)
    public ResponseEntity<ApiResponse<Object>> handleDuplicateResourceException(DuplicateResourceException ex) {
        log.warn("Duplicate resource: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.error(409, ex.getMessage()));
    }

    /**
     * Bắt lỗi nghiệp vụ BadRequest (Biển số xe trùng, xe đang bận...) -> HTTP 400
     */
    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ApiResponse<Object>> handleBadRequest(BadRequestException ex) {
        log.warn("Bad request: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, ex.getMessage()));
    }

    /**
     * Bắt lỗi vi phạm quy tắc trạng thái nghiệp vụ (Đơn cứu hộ đã COMPLETED / CANCELLED...) -> HTTP 400
     */
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ApiResponse<Object>> handleIllegalStateException(IllegalStateException ex) {
        log.warn("Business rule violation: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, ex.getMessage()));
    }

    /**
     * Bắt lỗi đối số không hợp lệ (ID null, ID không hợp lệ...) -> HTTP 400
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Object>> handleIllegalArgument(IllegalArgumentException ex) {
        log.warn("Illegal argument: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Dữ liệu đầu vào không hợp lệ: " + ex.getMessage()));
    }

    // ============================================================
    // 2. CÁC NGOẠI LỆ ĐỊNH DẠNG REQUEST (400)
    // ============================================================

    /**
     * Bắt lỗi validate DTO (@NotNull, @NotBlank, @Pattern, @DecimalMin...)
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Object>> handleValidationExceptions(MethodArgumentNotValidException ex) {
        String errorMessage = ex.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining(", "));

        log.error("Validation error: {}", errorMessage);

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Dữ liệu không hợp lệ: " + errorMessage));
    }

    /**
     * Bắt lỗi Request body không đúng định dạng JSON
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Object>> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        log.warn("Malformed JSON request: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Request body không đúng định dạng JSON hoặc bị thiếu"));
    }

    /**
     * Bắt lỗi thiếu Query Param bắt buộc
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResponse<Object>> handleMissingParams(MissingServletRequestParameterException ex) {
        log.warn("Missing request parameter: {}", ex.getParameterName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Tham số '" + ex.getParameterName() + "' là bắt buộc nhưng bị thiếu"));
    }

    /**
     * Bắt lỗi Multipart / Upload file thiếu dữ liệu
     */
    @ExceptionHandler({MultipartException.class, MissingServletRequestPartException.class})
    public ResponseEntity<ApiResponse<Object>> handleMultipartException(Exception ex) {
        log.warn("Multipart upload error: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Yêu cầu tải lên không hợp lệ hoặc thiếu dữ liệu tệp (multipart/form-data): " + ex.getMessage()));
    }

    /**
     * Bắt lỗi dung lượng file upload vượt quá giới hạn
     */
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Object>> handleMaxSizeException(MaxUploadSizeExceededException ex) {
        log.warn("File size exceeded: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Kích thước tệp tải lên vượt quá giới hạn cho phép"));
    }

    /**
     * Bắt lỗi kiểu dữ liệu tham số không hợp lệ
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<Object>> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        log.warn("Type mismatch for param {}: {}", ex.getName(), ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(400, "Tham số không đúng định dạng: " + ex.getName()));
    }

    // ============================================================
    // 3. CÁC NGOẠI LỆ ĐIỀU HƯỚNG & BẢO MẬT (404, 401, 403, 500)
    // ============================================================

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleNoResourceFound(NoResourceFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(404, "Không tìm thấy đường dẫn (API Endpoint) tương ứng: " + ex.getResourcePath()));
    }

    @ExceptionHandler(org.springframework.security.access.AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Object>> handleAccessDeniedException(org.springframework.security.access.AccessDeniedException ex) {
        log.warn("Access denied: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error(403, "Bạn không có quyền truy cập tài nguyên này"));
    }

    @ExceptionHandler(org.springframework.security.core.AuthenticationException.class)
    public ResponseEntity<ApiResponse<Object>> handleAuthenticationException(org.springframework.security.core.AuthenticationException ex) {
        log.warn("Authentication failed: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error(401, "Sai tên đăng nhập hoặc mật khẩu"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Object>> handleGeneralException(Exception ex) {
        log.error("Unexpected error occurred: ", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(500, "Đã xảy ra lỗi hệ thống: " + ex.getMessage()));
    }
}
