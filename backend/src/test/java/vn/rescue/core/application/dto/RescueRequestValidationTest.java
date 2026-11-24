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

    @Test
    @DisplayName("BVA: Số người (numberOfPeople) = -1 -> Bị chặn với ConstraintViolation")
    void testInvalidNumberOfPeople_NegativeOne_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setNumberOfPeople(-1);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Số người -1 phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("numberOfPeople")));
    }

    @Test
    @DisplayName("BVA: Số người (numberOfPeople) = 0 -> Bị chặn với ConstraintViolation")
    void testInvalidNumberOfPeople_Zero_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setNumberOfPeople(0);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Số người 0 phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("numberOfPeople")));
    }

    @Test
    @DisplayName("BVA: Số người (numberOfPeople) = 1 (biên dưới hợp lệ) -> Hợp lệ không có lỗi")
    void testValidNumberOfPeople_LowerBoundaryOne_ShouldPass() {
        RescueRequestDto dto = createValidDto();
        dto.setNumberOfPeople(1);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertTrue(violations.isEmpty(), "Số người 1 là biên dưới hợp lệ, không được có lỗi validation");
    }

    @Test
    @DisplayName("BVA: Số người (numberOfPeople) = 50 (biên trên hợp lệ) -> Hợp lệ không có lỗi")
    void testValidNumberOfPeople_UpperBoundaryFifty_ShouldPass() {
        RescueRequestDto dto = createValidDto();
        dto.setNumberOfPeople(50);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertTrue(violations.isEmpty(), "Số người 50 là biên trên hợp lệ, không được có lỗi validation");
    }

    @Test
    @DisplayName("BVA: Số người (numberOfPeople) = 51 (vượt biên trên) -> Bị chặn với lỗi vi phạm")
    void testInvalidNumberOfPeople_FiftyOne_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setNumberOfPeople(51);

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Số người 51 vượt biên trên phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("numberOfPeople")));
    }

    @Test
    @DisplayName("BVA: Độ dài ghi chú/mô tả (description) = 1000 ký tự (biên trên hợp lệ) -> Hợp lệ không có lỗi")
    void testValidDescription_Length1000_ShouldPass() {
        RescueRequestDto dto = createValidDto();
        dto.setDescription("A".repeat(1000));

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertTrue(violations.isEmpty(), "Ghi chú 1000 ký tự là biên trên hợp lệ, không được có lỗi validation");
    }

    @Test
    @DisplayName("BVA: Độ dài ghi chú/mô tả (description) = 1001 ký tự (vượt biên trên) -> Bị chặn với lỗi vi phạm")
    void testInvalidDescription_Length1001_ShouldFail() {
        RescueRequestDto dto = createValidDto();
        dto.setDescription("A".repeat(1001));

        Set<ConstraintViolation<RescueRequestDto>> violations = validator.validate(dto);
        assertFalse(violations.isEmpty(), "Ghi chú 1001 ký tự vượt quá biên trên phải bị vi phạm validation");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("description")));
    }

    @Test
    @DisplayName("BVA: Vĩ độ (Latitude) = -90.0 (biên dưới hợp lệ) -> Không có lỗi")
    void testValidLatitude_LowerBoundaryMinus90_ShouldPass() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLat(-90.0);
        assertTrue(validator.validate(dto).isEmpty(), "Vĩ độ -90.0 là biên dưới hợp lệ");
    }

    @Test
    @DisplayName("BVA: Vĩ độ (Latitude) = 90.0 (biên trên hợp lệ) -> Không có lỗi")
    void testValidLatitude_UpperBoundary90_ShouldPass() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLat(90.0);
        assertTrue(validator.validate(dto).isEmpty(), "Vĩ độ 90.0 là biên trên hợp lệ");
    }

    @Test
    @DisplayName("BVA: Kinh độ (Longitude) = -180.0 (biên dưới hợp lệ) -> Không có lỗi")
    void testValidLongitude_LowerBoundaryMinus180_ShouldPass() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLng(-180.0);
        assertTrue(validator.validate(dto).isEmpty(), "Kinh độ -180.0 là biên dưới hợp lệ");
    }

    @Test
    @DisplayName("BVA: Kinh độ (Longitude) = 180.0 (biên trên hợp lệ) -> Không có lỗi")
    void testValidLongitude_UpperBoundary180_ShouldPass() {
        RescueRequestDto dto = createValidDto();
        dto.setLocationLng(180.0);
        assertTrue(validator.validate(dto).isEmpty(), "Kinh độ 180.0 là biên trên hợp lệ");
    }
}
