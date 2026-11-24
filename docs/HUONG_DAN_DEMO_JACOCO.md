# HƯỚNG DẪN DEMO ĐỘ PHỦ CÂU LỆNH (STATEMENT COVERAGE) BẰNG JACOCO

## 1. JaCoCo là gì?

**JaCoCo** (Java Code Coverage) là công cụ đo **bộ test đã chạy qua những dòng code nào**. Khi chạy `mvn test`, JaCoCo ghi lại từng câu lệnh, từng nhánh `if` mà unit test đi qua, rồi xuất ra một trang web báo cáo.

| Chỉ số trong báo cáo | Ý nghĩa |
|:---|:---|
| **Lines** (Statement coverage – C0) | Tỷ lệ câu lệnh đã được test chạy qua |
| **Branches** (Branch coverage – C1) | Tỷ lệ nhánh đúng/sai của các `if`, `&&`, `\|\|`, `?:` đã được chạy |

Màu trong trang code của báo cáo:

| Màu | Ý nghĩa |
|:---|:---|
| 🟩 Xanh lá | Dòng đã được test chạy qua |
| 🟥 Đỏ | Dòng **chưa** có test nào chạy qua → cần bổ sung test |
| 🟨 Vàng | Dòng có `if` mới chạy 1 nhánh (ví dụ chỉ nhánh sai, chưa nhánh đúng) |

---

## 2. Chuẩn bị (làm 1 lần trước buổi demo)

1. Mở **PowerShell**.
2. Khai báo Java (máy chưa có `JAVA_HOME`):
   ```powershell
   $env:JAVA_HOME = "C:\Users\nhata\.antigravity-ide\extensions\redhat.java-1.58.0-win32-x64\jre\25.0.4.1-win32-x86_64"
   ```
> `mvnw.cmd` (Maven Wrapper) chỉ có trên máy trưởng nhóm vì repo đang bỏ qua file này trong `.gitignore`. Máy đã cài Maven thì dùng `mvn test` thay cho `.\mvnw.cmd test`, kết quả như nhau.

3. Chạy thử 1 lần để máy tải Maven và thư viện (lần đầu mất vài phút, các lần sau ~30 giây):
   ```powershell
   cd C:\Users\nhata\Flood-Rescue-Coordination-and-Relief-Management-System\backend
   .\mvnw.cmd test
   ```

---

## 3. Các bước thao tác khi demo

| Bước | Thao tác | Nói với thầy |
|:---:|:---|:---|
| 1 | Mở `docs/CO_SO_TINH_SO_TESTCASE.xlsx`, sheet **Ly thuyet**, chỉ 2 dòng cuối | "Độ phủ câu lệnh C0 = số câu lệnh đã chạy / tổng câu lệnh. Nhóm đo bằng JaCoCo." |
| 2 | Sheet **Pham vi & Statement** | "Mỗi thành viên phụ trách 1 phân hệ, chọn 4 chức năng cốt lõi. Đây là độ phủ đo thật của từng chức năng." |
| 3 | Chạy trong PowerShell: `.\mvnw.cmd test` | "Chạy toàn bộ 167 unit test, JaCoCo đo độ phủ cùng lúc." |
| 4 | Chờ dòng `Tests run: 167, Failures: 0` và `BUILD SUCCESS` | "167/167 test pass." |
| 5 | Mở báo cáo: `start target\site\jacoco\index.html` | Trang tổng hợp độ phủ theo package |
| 6 | Bấm `vn.rescue.core.application.services` → `UserService` | Bảng độ phủ theo từng hàm, cột **Lines** và **Branches** |
| 7 | Bấm hàm `changePassword(...)` | Mở code: dòng xanh đã test; dòng đỏ 170, 173 chưa test |
| 8 | Quay lại Excel, chỉ cột **Dòng chưa chạy** | "Nhóm biết chính xác dòng nào thiếu test: dòng 170 là mật khẩu cũ để trống, dòng 173 là mật khẩu mới để trống. Thêm 2 unit test cho 2 trường hợp này là đạt 100%." |

**Mẹo:** chọn 1 hàm đã đạt 100% để thầy thấy toàn bộ màu xanh, ví dụ `VehiclesService.validateVehicleRequest` hoặc `UserService.updateUserStatus`, rồi so với 1 hàm còn dòng đỏ.

---

## 4. Câu hỏi thầy có thể hỏi

**Hỏi: "1/4 là thiếu 3 chức năng à?"**
Không phải thiếu chức năng. "1/4" là **1 trong 4 chức năng đã phủ đúng 100%**; 3 chức năng còn lại vẫn có test nhưng còn vài dòng chưa chạy qua. Ví dụ phân hệ Xác thực: `login` 90,3%, `changePassword` 90,0%, `updateUserRole` 96,4% – mỗi hàm chỉ thiếu 1–3 dòng.

**Hỏi: "Sao có người chỉ khoảng 50–60%?"**
Có 2 lý do:
1. **Phần trăm tính theo tổng số câu lệnh, nên hàm dài kéo cả nhóm xuống.** Ví dụ `assignVehicleToRequest` (Nguyễn Bảo) có 51 câu lệnh, unit test mới chạy 13 câu (chỉ nhánh báo lỗi "xe đang bận"), nên dù 3 hàm còn lại đạt 100%, tổng chỉ còn 53,7%. Tương tự `createRequest` (Lâm Khiêm) chưa có unit test nào nên kéo xuống 63,3%.
2. **JaCoCo chỉ đo unit test.** Các hàm đó vẫn được kiểm thử qua Bruno và CodeceptJS (gọi API thật), nhưng 2 loại test này chạy trên server riêng nên JaCoCo không ghi nhận. Statement coverage là chỉ số của kiểm thử hộp trắng.

**Hỏi: "Statement coverage với branch coverage khác nhau gì?"**
Statement chỉ cần mỗi dòng chạy ít nhất 1 lần. Branch đòi mỗi `if` phải chạy cả nhánh đúng và nhánh sai. Đạt 100% branch thì chắc chắn đạt 100% statement, nhưng ngược lại thì không.

---

## 5. Số liệu ngày 24/11/2026 (20 chức năng, 5 thành viên)

| Thành viên | Chức năng đạt 100% | Statement coverage |
|:---|:---:|:---:|
| Dư Nhật Anh | 1/4 | 93,1% |
| Lâm Khiêm | 2/4 | 63,3% |
| Phạm Minh Dũng | 3/4 | 72,1% |
| Nguyễn Bảo | 3/4 | 53,7% |
| Phan Quốc Danh | 0/4 | 87,0% |
| **Toàn nhóm** | **9/20** | **75,0%** |

Chi tiết từng hàm và dòng còn thiếu: sheet **Pham vi & Statement** trong `docs/CO_SO_TINH_SO_TESTCASE.xlsx`.
