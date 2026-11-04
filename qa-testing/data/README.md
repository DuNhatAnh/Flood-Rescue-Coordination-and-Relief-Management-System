# 📂 data/ — File Dữ Liệu Kiểm Thử (CSV Test Data)

Thư mục này chứa các file CSV làm nguồn dữ liệu đầu vào cho bộ kiểm thử.  
Mỗi dòng trong CSV tương ứng với **1 ca kiểm thử (Test Case)** trong file Plan.

---

## Danh sách file CSV hiện có

| File | Chức năng | Số Test Cases | Kỹ thuật |
|:---|:---|:---:|:---|
| `auth_change_password_data.csv` | Đổi mật khẩu | 14 | BVA (Min=6, Max=32) + 5 Tiêu chí |
| `auth_login_data.csv` | Đăng nhập | 10 | EP + Decision Table (3 Roles) |
| `auth_rbac_data.csv` | Phân quyền | _(sẽ bổ sung)_ | Decision Table (Role × API Matrix) |

---

## Chuẩn Format File CSV (Bắt buộc tuân thủ)

### Quy tắc 1: Header dòng đầu tiên (Bắt buộc có)

Dòng đầu tiên phải là tên cột. Script Python dùng `numLinesToSkip = 1` để bỏ qua dòng này.

### Quy tắc 2: Cột bắt buộc phải có trong mọi file CSV

| Cột | Tên Cột | Kiểu Giá Trị | Ví dụ |
|:---:|:---|:---|:---|
| 1 | `testCaseId` | Chuỗi định danh | `TC_CPW_01`, `TC_LOG_03` |
| ... | _(Cột input nghiệp vụ)_ | Tùy chức năng | `oldPassword`, `email`... |
| n-2 | `expectedStatus` | `PASS` hoặc `FAIL` | `PASS` |
| n-1 | `expectedException` | Tên class Exception hoặc `NONE` | `BadRequestException` |
| n | `expectedMessage` | Chuỗi thông báo lỗi hoặc `SUCCESS` | `Mật khẩu mới phải có tối thiểu 6 ký tự` |

### Quy tắc 3: Giá trị đặc biệt chuẩn hóa

| Giá trị trong CSV | Ý nghĩa | Script xử lý như thế nào |
|:---|:---|:---|
| `NULL_VAL` | Truyền `null` vào tham số | `simulate()` nhận biết và ném exception tương ứng |
| _(chuỗi rỗng)_ | Truyền chuỗi rỗng `""` | Script đọc là empty string `""` |
| `USER-NOT-FOUND` | userId không tồn tại trong DB | `simulate()` ném `ResourceNotFoundException` |
| `locked_user@rescue.vn` | Email tài khoản bị khóa | `simulate()` trả về HTTP 403 |

---

## Ví dụ cụ thể từng file

### `auth_change_password_data.csv`
```
testCaseId,userId,oldPassword,newPassword,expectedStatus,expectedException,expectedMessage
TC_CPW_01,USER-001,password123,12345,FAIL,BadRequestException,Mật khẩu mới phải có tối thiểu 6 ký tự
TC_CPW_02,USER-001,password123,123456,PASS,NONE,SUCCESS
```

### `auth_login_data.csv`
```
testCaseId,email,password,expectedRole,expectedStatus,expectedHttpCode,expectedMessage
TC_LOG_01,admin@rescue.vn,password123,ROLE_ADMIN,PASS,200,SUCCESS
TC_LOG_04,admin@rescue.vn,wrongPass999,NONE,FAIL,401,Thông tin đăng nhập không chính xác
```

---

## Lưu ý quan trọng

> [!CAUTION]
> **Không bao giờ lưu file CSV bằng Excel mặc định trên Windows** (Excel thường lưu về dạng ANSI hoặc thêm BOM vào UTF-8). Thay vào đó:
> - Dùng **VS Code** để tạo và chỉnh sửa file CSV.
> - Hoặc trong Excel, chọn `Save As → CSV UTF-8 (Comma delimited) (*.csv)`.

> [!IMPORTANT]
> Số lượng Test Case trong file CSV phải **khớp chính xác** với số dòng trong Sheet 2 của file Plan Excel tương ứng. Script báo cáo sẽ bị sai nếu 2 file lệch nhau.

> [!NOTE]
> File CSV không chứa dữ liệu nhạy cảm thật (mật khẩu thật, email thật). Đây là **dữ liệu kiểm thử mẫu** (test fixtures) được thiết kế riêng để đánh giá logic nghiệp vụ.

