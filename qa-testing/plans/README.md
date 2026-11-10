# 📊 plans/ — File Kế Hoạch Kiểm Thử (Test Plan Excel)

Thư mục này chứa các file Excel thiết kế kế hoạch kiểm thử theo chuẩn học thuật môn KCPM.

---

## Danh sách file hiện có

| File | Chức năng | Kỹ thuật | Subtask Jira |
|:---|:---|:---|:---|
| `PLAN_AUTH_CHANGE_PASSWORD_V2.xlsx` | Đổi mật khẩu | BVA (Biên dưới Min=6, Biên trên Max=32) + 5 Tiêu chí | KCPM-88 |
| `PLAN_AUTH_LOGIN.xlsx` | Đăng nhập | Phân vùng tương đương (EP) + Bảng quyết định (Decision Table) | KCPM-89 |
| `PLAN_AUTH_RBAC.xlsx` | Phân quyền | Bảng quyết định (Decision Table) — Ma trận Role vs API | KCPM-90 |
| `PLAN_DANGER_POINT_RADAR.xlsx` | Quét radar điểm nguy hiểm | BVA (Bán kính Min=50m, Max=5000m, Mực nước) | KCPM-93 |
| `PLAN_COORDINATION_DISPATCH.xlsx` | Điều phối đơn cứu nạn | Bảng quyết định (Decision Table) | KCPM-95 |
| `PLAN_VEHICLES_MANAGEMENT.xlsx` | Đăng ký & Sức chứa Phương tiện | EP, BVA & Bảng quyết định (Decision Table R1-R8) | KCPM-96 |

---

## Chuẩn Format File Plan Excel (Bắt buộc theo đúng mẫu)

Mỗi file Plan **phải có đúng 2 Sheet** với thứ tự như sau:

### Sheet 1: `Phân Tích BVA & EP` (Trang thiết kế lý thuyết)

```
Dòng 1  : Tiêu đề lớn (font to đậm màu xanh 1F497D)
Dòng 2  : Mô tả dự án + tên hàm kiểm thử (font nhỏ nghiêng xám)
Dòng 4  : Tiêu đề bảng 1 — "ĐẶC TẢ NGHIỆP VỤ & MIỀN GIÁ TRỊ"
Dòng 5  : Header hàng (nền xanh navy, chữ trắng đậm)
Dòng 6+ : Nội dung phân tích tham số

Dòng 12 : Tiêu đề bảng 2 — "BẢNG TÍNH TOÁN GIÁ TRỊ BIÊN (BVA)"
Dòng 13 : Header hàng (nền xanh navy, chữ trắng đậm)
Dòng 14+: Cột "Điểm Biên", "Công Thức", "Giá Trị L", "Đánh Giá", "Dữ Liệu Mẫu", "Kỳ Vọng"
```

> **Yêu cầu BVA tối thiểu phải có:**
> - Min - 1 (Dưới biên — kết quả FAIL)
> - Min     (Tại biên dưới — kết quả PASS)
> - Min + 1 (Trên biên dưới — kết quả PASS)
> - Nominal (Giá trị danh định giữa miền — kết quả PASS)
> - Max - 1 (Dưới biên trên — kết quả PASS)
> - Max     (Tại biên trên — kết quả PASS)
> - Max + 1 (Vượt biên trên — kết quả FAIL)

### Sheet 2: `Ma Trận Test Case` (Bảng test cases cụ thể)

Các cột **bắt buộc phải có** (theo thứ tự):

| Cột | Tên Cột | Ý Nghĩa |
|:---:|:---|:---|
| 1 | `Mã Test Case` | Định danh duy nhất, dạng `TC_<FEATURE>_<STT>` |
| 2 | `Tên Kịch Bản` | Mô tả rõ ràng bằng tiếng Việt |
| 3 | `Kỹ Thuật Kiểm Thử` | BVA / EP / Nghiệp vụ / Validation / Bảo mật |
| 4 | `Phân Loại Chi Tiết` | Min-1 / Min / Min+1 / Nominal / Sai định dạng... |
| 5 | `Input (Đầu vào)` | Dữ liệu thực tế truyền vào |
| 6 | `Kết Quả Mong Đợi` | **PASS** (nền xanh) hoặc **FAIL** (nền cam đỏ) |
| 7 | `Exception Kỳ Vọng` | Tên class Exception Java hoặc `NONE` |
| 8 | `Thông Báo / Output` | Chuỗi thông báo lỗi hoặc `SUCCESS` |
| 9 | `Xác Minh Hậu Điều Kiện` | Mô tả post-condition cần verify |

---

## Lưu ý khi chỉnh sửa file Plan

> [!WARNING]
> Khi chỉnh sửa nội dung bảng Plan, **cập nhật đồng thời** file CSV tương ứng trong thư mục `data/`. Nếu CSV và Plan bị lệch nhau, kết quả báo cáo sẽ không phản ánh đúng kế hoạch thiết kế.

> [!TIP]
> Nên thiết kế xong bảng Plan trong Excel trước → Xuất CSV sau. Không làm ngược lại!

