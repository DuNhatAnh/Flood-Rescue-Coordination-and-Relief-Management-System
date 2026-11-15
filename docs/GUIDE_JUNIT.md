# 📗 HƯỚNG DẪN CHUẨN HÓA VIẾT WHITE-BOX UNIT TEST (JUNIT 5 + MOCKITO)

> **Mục tiêu:** Hướng dẫn các thành viên viết Unit Test kiểm thử hộp trắng cho tầng Service và Presentation/Validation trong Backend Spring Boot theo đúng tiêu chuẩn thiết kế hướng kiểm thử.

---

## 1. QUY TẮC ĐẶT TÊN & VỊ TRÍ FILE

* **Vị trí lưu file:**
  * Kiểm thử nghiệp vụ Service: `backend/src/test/java/vn/rescue/core/application/services/<Tên>ServiceTest.java`
  * Kiểm thử Validation / Controller: `backend/src/test/java/vn/rescue/core/presentation/controllers/<Tên>ControllerTest.java`
* **Quy tắc đặt tên Class:** `<Tên_Đối_Tượng>Test.java` (Ví dụ: `InventoryServiceTest.java`, `UserServiceTest.java`).
* **Quy tắc đặt tên Method test:** `test<Chức_Năng>_<Điều_Kiện>_<Kết_Quả_Kỳ_Vọng>()`
  * *Ví dụ hợp lệ:* `testImportGoods_WhenQuantityNegative_ShouldThrowBadRequestException()`
  * *Ví dụ hợp lệ:* `testChangePassword_WhenNewPasswordValid_ShouldSuccess()`

---

## 2. TEMPLATE CHUẨN CHO TẦNG SERVICE (COPY & PASTE ĐỂ DÙNG)

Dưới đây là khung mẫu chuẩn sử dụng Mockito để cô lập Database:

```java
package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import vn.rescue.core.domain.repositories.InventoryRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM: Unit Test cho Quản lý Nhập kho (InventoryService)")
class InventoryServiceTest {

    @Mock
    private InventoryRepository inventoryRepository;

    @InjectMocks
    private InventoryService inventoryService;

    @Test
    @DisplayName("TC_IMP_01: Nhập kho thất bại khi số lượng <= 0 -> Ném 400 BadRequestException")
    void testImportGoods_WhenQuantityLessThanOrEqualZero_ShouldThrowBadRequestException() {
        // GIVEN: Chuẩn bị dữ liệu đầu vào vi phạm biên dưới
        int invalidQuantity = 0;

        // WHEN & THEN: Gọi hàm và kỳ vọng ném Exception chính xác
        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            inventoryService.importGoods("WH-01", "ITEM-01", invalidQuantity);
        });

        // ASSERT: Kiểm tra thông điệp lỗi và đảm bảo KHÔNG gọi lưu DB
        assertTrue(exception.getMessage().contains("Số lượng nhập kho phải lớn hơn 0"));
        verify(inventoryRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_IMP_02: Nhập kho thành công khi số lượng hợp lệ (Biên Min = 1)")
    void testImportGoods_WhenQuantityValid_ShouldSuccess() {
        // GIVEN: Mock dữ liệu hợp lệ
        when(inventoryRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        // WHEN: Thực thi hàm nghiệp vụ
        assertDoesNotThrow(() -> {
            inventoryService.importGoods("WH-01", "ITEM-01", 1);
        });

        // THEN: Đảm bảo có gọi save đúng 1 lần
        verify(inventoryRepository, times(1)).save(any());
    }
}
```

---

## 3. CÁC CÂU LỆNH KIỂM CHỨNG (ASSERTION) CẦN NHỚ

| Mục đích kiểm tra | Cú pháp JUnit 5 / Mockito |
|:---|:---|
| Kỳ vọng ném ngoại lệ | `assertThrows(BadRequestException.class, () -> service.call());` |
| Kỳ vọng chạy trơn tru | `assertDoesNotThrow(() -> service.call());` |
| So sánh giá trị bằng nhau | `assertEquals(expected, actual);` |
| Kiểm tra điều kiện đúng | `assertTrue(result.isValid());` |
| Đảm bảo DB không bị gọi ghi | `verify(repository, never()).save(any());` |
| Đảm bảo gọi hàm đúng n lần | `verify(repository, times(1)).findById(id);` |

---

## 4. LỆNH CHẠY KIỂM THỬ TRONG TERMINAL

* Chạy riêng một class test:
  ```bash
  cd backend && mvn test -Dtest=InventoryServiceTest
  ```
* Chạy toàn bộ test của backend để kiểm tra độ tương thích:
  ```bash
  cd backend && mvn test
  ```
