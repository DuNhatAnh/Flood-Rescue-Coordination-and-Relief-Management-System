package vn.rescue.core.application.dto;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("KCPM-39: Kiểm thử Validation cho RescueRequestDto")
class RescueRequestValidationTest {

    private static Validator validator;

    @BeforeAll
    static void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    private RescueRequestDto createValidDto() {
        RescueRequestDto dto = new RescueRequestDto();
        dto.setCitizenName("Nguyễn Văn A");
        dto.setCitizenPhone("0987654321");
        dto.setLocationLat(16.0544);
        dto.setLocationLng(108.2022);
        dto.setNumberOfPeople(3);
        dto.setAddressText("Đà Nẵng");
        return dto;
    }

    @Test
    @DisplayName("Dữ liệu hợp lệ -> Không có vi phạm validation")
    void testValidDto_ShouldHaveNoViolations() {
        RescueRequestDto dto = createValidDto();
        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertTrue(violations.isEmpty(), "Dữ liệu hợp lệ không được có lỗi validation");
    }

    @Test
    @DisplayName("Vĩ độ (Latitude) > 90.0 -> Bị chặn với lỗi vi phạm")
    void testInvalidLatitude_GreaterThan90_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLat(95.0);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Vĩ độ 95.0 phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("locationLat")));
    }

    @Test
    @DisplayName("Vĩ độ (Latitude) < -90.0 -> Bị chặn với lỗi vi phạm")
    void testInvalidLatitude_LessThanMinus90_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLat(-95.0);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Vĩ độ -95.0 phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("locationLat")));
    }

    @Test
    @DisplayName("Kinh độ (Longitude) > 180.0 -> Bị chặn với lỗi vi phạm")
    void testInvalidLongitude_GreaterThan180_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLng(185.0);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Kinh độ 185.0 phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("locationLng")));
    }

    @Test
    @DisplayName("Kinh độ (Longitude) < -180.0 -> Bị chặn với lỗi vi phạm")
    void testInvalidLongitude_LessThanMinus180_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLng(-185.0);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Kinh độ -185.0 phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("locationLng")));
    }

    @Test
    @DisplayName("Số điện thoại không đúng định dạng -> Bị chặn với lỗi vi phạm")
    void testInvalidPhone_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setCitizenPhone("012345"); // quá ngắn

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "SĐT 012345 phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("citizenPhone")));
    }
}
