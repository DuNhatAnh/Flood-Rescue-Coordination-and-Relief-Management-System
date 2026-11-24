# BÁO CÁO KIỂM THỬ VÀ QUY TRÌNH TEST CÁC API CỨU HỘ & BÁO CÁO
**Dự án:** Hệ thống Điều phối Cứu nạn & Cứu trợ Lũ lụt (Flood Rescue Coordination and Relief Management System)  
**Mã nghiệp vụ liên quan:** KCPM-64 (Parent Ticket) | Subtasks: KCPM-84 -> KCPM-89  
**Ngày thực hiện:** 01/11/2026 - 02/11/2026  
**Người thực hiện:** Đội ngũ QA / Tester  
**Trạng thái:** HOÀN THÀNH (100% Passed)

---

## I. MỤC TIÊU VÀ PHẠM VI KIỂM THỬ

Tài liệu này chuẩn hóa quy trình kiểm thử từ khâu thiết kế test case (phân hoạch tương đương, phân tích biên), quản lý subtask kiểm thử trên **Excel**, quy chuẩn log lỗi trên **Jira**, đến việc tự động hóa test bằng **Bruno API Client** và tổng hợp **Test Report** cho 4 nhóm API trọng yếu:

1. **API Lọc yêu cầu cứu nạn:** `GET /api/v1/rescue-requests`
2. **API Hủy yêu cầu cứu nạn:** `PUT /api/v1/rescue-requests/{id}/cancel`
3. **API Gửi báo an toàn:** `POST /api/v1/safety-reports`
4. **API Nộp báo cáo tổng kết cứu hộ:** `POST /api/v1/reports` (hoặc `POST /api/v1/rescue-reports`)
5. **Quản lý Task trên Excel & Quy chuẩn Log Bug Jira khi phát hiện lỗi**
6. **Lưu trữ, đóng gói Test Report vào thư mục Test-reports**

---

## II. THIẾT KẾ KIỂM THỬ DỰA TRÊN ĐẶC TẢ (EP & BVA)

### 1. Phân hoạch lớp tương đương (Equivalence Partitioning - EP)

| Nghiệp vụ / Trường dữ liệu | Miền giá trị / Điều kiện | Lớp hợp lệ | Tag | Lớp không hợp lệ | Tag |
|---|---|---|---|---|---|
| **Lọc Request Status** | Trạng thái vòng đời cứu hộ | `PENDING`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED` | **V1** | Giá trị ngoài enum: `INVALID_STATUS`, chuỗi rác | **X1** |
| **Lọc Quận/Huyện** | Chuỗi ký tự địa danh | Tồn tại trong dữ liệu địa chỉ (ví dụ: `Hải Châu`, `Thanh Khê`) | **V2** | Không có kết quả hoặc ký tự đặc biệt nguy hiểm | **X2** |
| **Hủy yêu cầu cứu hộ** | Trạng thái hiện tại của Request | `PENDING`, `IN_PROGRESS` (được phép hủy) | **V3** | (a) `COMPLETED` (đã xong, cấm hủy)<br>(b) `CANCELLED` (đã hủy trước đó) | **X3**<br>**X4** |
| **Lý do hủy yêu cầu** | Chuỗi văn bản lý do | Nhập chuỗi hợp lệ (<= 500 ký tự) hoặc để null (lấy mặc định) | **V4** | Chuỗi vượt quá độ dài tối đa (> 500 ký tự) | **X5** |
| **Số ĐT người báo an toàn** | Định dạng số điện thoại liên lạc | Chuỗi số ĐT hợp lệ (10 số, đầu số VN) | **V5** | (a) Để trống / null<br>(b) Chuỗi sai định dạng ký tự | **X6**<br>**X7** |
| **Số người cứu được** | Số nguyên dương $\geq 0$ | $rescuedPeopleCount \geq 0$ | **V6** | $rescuedPeopleCount < 0$ | **X8** |
| **Số lượng hàng cấp phát** | Số nguyên dương trong mảng vật phẩm | $quantity > 0$ cho từng item | **V7** | $quantity \leq 0$ hoặc mảng null | **X9** |

---

### 2. Phân tích giá trị biên (Boundary Value Analysis - BVA)

| Tham số / Trường dữ liệu | min- | min | min+ | nominal | max- | max | max+ | Ghi chú & Tag biên |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| **Số người cứu được** (`rescuedPeopleCount`) | -1 (X8) | 0 | 1 | 5 | 999 | 1000 | 1001 (X8) | **B1** (0), **B2** (1), **B3** (5), **B4** (999), **B5** (1000) |
| **Số lượng hàng hóa phát** (`quantity`) | 0 (X9) | 1 | 2 | 10 | 9999 | 10000 | 10001 (X9) | **B6** (1), **B7** (2), **B8** (10), **B9** (9999), **B10** (10000) |
| **Độ dài số điện thoại** | 9 số (X7) | 10 số | 11 số | 10 số | 11 số | 11 số | 12 số (X7) | Chuẩn viễn thông VN: 10 chữ số |

---

## III. MA TRẬN TEST CASE CHI TIẾT (TEST CASES MATRIX)

| Mã TC | Nhóm API & Tên Test Case | Phương thức & URL | Dữ liệu đầu vào (Params / Body) | Kết quả mong đợi (Expected Result) | Tag bao phủ | Trạng thái thực tế |
|---|---|---|---|---|---|:---:|
| **TC_RES_01** | Lọc yêu cầu theo trạng thái PENDING | `GET /api/v1/rescue-requests?status=PENDING` | Params: `status=PENDING` | **200 OK**, danh sách trả về 100% có status = `PENDING` | `V1` | **PASS** |
| **TC_RES_02** | Lọc yêu cầu theo trạng thái IN_PROGRESS | `GET /api/v1/rescue-requests?status=IN_PROGRESS` | Params: `status=IN_PROGRESS` | **200 OK**, danh sách trả về 100% có status = `IN_PROGRESS` | `V1` | **PASS** |
| **TC_RES_03** | Lọc yêu cầu theo quận/huyện hợp lệ | `GET /api/v1/rescue-requests?district=Hải Châu` | Params: `district=Hải Châu` | **200 OK**, `addressText` chứa từ khóa "Hải Châu" | `V2` | **PASS** |
| **TC_RES_04** | Lọc yêu cầu với trạng thái không hợp lệ | `GET /api/v1/rescue-requests?status=INVALID_STATUS` | Params: `status=INVALID_STATUS` | **400 Bad Request**, ném ngoại lệ thông báo trạng thái không hợp lệ | `X1` | **PASS** |
| **TC_RES_05** | Người dân tự hủy khi nước đã rút | `PUT /api/v1/rescue-requests/req-01/cancel` | Status hiện tại: `PENDING`. Body: `{"reason": "Nước đã rút, gia đình đã an toàn"}` | **200 OK**, status chuyển thành `CANCELLED`, ghi log lịch sử hủy | `V3, V4` | **PASS** |
| **TC_RES_06** | Hủy yêu cầu không truyền lý do (null body) | `PUT /api/v1/rescue-requests/req-01/cancel` | Status: `PENDING`. Body: `{}` hoặc null | **200 OK**, status chuyển `CANCELLED`, ghi nhận lý do mặc định | `V3, V4` | **PASS** |
| **TC_RES_07** | Cố tình hủy khi yêu cầu đã COMPLETED | `PUT /api/v1/rescue-requests/req-03/cancel` | Status hiện tại: `COMPLETED`. Body: `{"reason": "Nước rút"}` | **400 Bad Request**, thông báo lỗi "Không thể hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED!" | `X3` | **PASS** |
| **TC_RES_08** | Cố tình hủy khi yêu cầu đã CANCELLED | `PUT /api/v1/rescue-requests/req-04/cancel` | Status hiện tại: `CANCELLED`. Body: `{"reason": "Hủy lần 2"}` | **400 Bad Request**, chặn lỗi "Yêu cầu này đã ở trạng thái CANCELLED trước đó!" | `X4` | **PASS** |
| **TC_RES_09** | Người dân gửi báo an toàn sau lũ thành công | `POST /api/v1/safety-reports` | Body: `{"citizenName": "Nguyễn Văn Dân", "citizenPhone": "0905123456", "note": "An toàn"}` | **200 OK** (hoặc 201), tạo bản ghi báo an toàn thành công | `V5` | **PASS** |
| **TC_RES_10** | Gửi báo an toàn thiếu số điện thoại | `POST /api/v1/safety-reports` | Body: `{"citizenName": "Nguyễn Văn Dân", "note": "Không có số ĐT"}` | **400 Bad Request**, báo lỗi "Số điện thoại người báo không được để trống" | `X6` | **PASS** |
| **TC_RES_11** | Đội cứu hộ nộp báo cáo tổng kết hợp lệ | `POST /api/v1/rescue-reports` (hoặc `/api/v1/reports`) | Body: `{"assignmentId": "as-01", "rescuedPeopleCount": 5, "actualDistributedItems": [{"itemName": "Mì tôm", "quantity": 3}]}` | **200 OK**, lưu báo cáo tổng kết, cập nhật nhiệm vụ thành công | `V6, V7, B3, B7` | **PASS** |
| **TC_RES_12** | Nộp báo cáo tổng kết với số người cứu âm | `POST /api/v1/rescue-reports` (hoặc `/api/v1/reports`) | Body: `{"rescuedPeopleCount": -1, ...}` | **400 Bad Request**, chặn dữ liệu âm tại biên $min- = -1$ | `X8, B1` | **PASS** |

---

## IV. NỘI DUNG CHI TIẾT CÁC SUBTASK TRÊN JIRA (JIRA SUBTASKS BREAKDOWN)

Dưới đây là chi tiết nội dung 6 Subtask trực thuộc Jira Task KCPM-64:

### 1. Subtask 1 (KCPM-84): Kiểm thử API Lọc cứu nạn (GET /api/v1/rescue-requests)
- **Issue Type:** Sub-task
- **Key:** `KCPM-84`
- **Summary:** `Subtask 1: [API Test] Kiểm thử API Lọc yêu cầu cứu nạn (GET /api/v1/rescue-requests)`
- **Mô tả chi tiết:**
  - Thực hiện kiểm thử chức năng lọc danh sách cứu nạn theo trạng thái (status: `PENDING`, `IN_PROGRESS`) và lọc theo địa bàn (district: `Hải Châu`).
  - Kiểm thử cơ chế bảo vệ tham số khi người dùng truyền giá trị rác hoặc trạng thái ngoài Enum (`status=INVALID_STATUS`).
- **Test Cases ánh xạ:** TC_RES_01, TC_RES_02, TC_RES_03, TC_RES_04.
- **Tiêu chuẩn nghiệm thu (Acceptance Criteria):**
  - Trả về HTTP 200 OK và danh sách chính xác với tham số hợp lệ.
  - Trả về HTTP 400 Bad Request khi truyền tham số trạng thái sai.
  - Script test tự động trên Bruno (`usebruno v4.2.1`) chạy PASS 100%.

### 2. Subtask 2 (KCPM-85): Kiểm thử API Hủy yêu cầu cứu nạn (PUT /api/v1/rescue-requests/{id}/cancel)
- **Issue Type:** Sub-task
- **Key:** `KCPM-85`
- **Summary:** `Subtask 2: [API Test] Kiểm thử API Hủy yêu cầu cứu nạn (PUT /api/v1/rescue-requests/{id}/cancel)`
- **Mô tả chi tiết:**
  - Kiểm thử tính năng người dân tự hủy yêu cầu cứu hộ khi nước rút (`PENDING -> CANCELLED`).
  - Kiểm thử trường hợp gửi request không có body lý do (hệ thống tự điền lý do mặc định).
  - Kiểm thử chặn lỗi khi cố tình hủy yêu cầu đã hoàn tất (`COMPLETED`) hoặc đã hủy trước đó (`CANCELLED`).
- **Test Cases ánh xạ:** TC_RES_05, TC_RES_06, TC_RES_07, TC_RES_08.
- **Tiêu chuẩn nghiệm thu (Acceptance Criteria):**
  - Chuyển trạng thái yêu cầu sang `CANCELLED`, ghi log người hủy `CITIZEN`.
  - Bắt buộc trả về HTTP 400 Bad Request nếu yêu cầu đã ở trạng thái `COMPLETED` hoặc `CANCELLED`.

### 3. Subtask 3 (KCPM-86): Kiểm thử API Gửi báo an toàn (POST /api/v1/safety-reports)
- **Issue Type:** Sub-task
- **Key:** `KCPM-86`
- **Summary:** `Subtask 3: [API Test] Kiểm thử API Gửi báo an toàn (POST /api/v1/safety-reports)`
- **Mô tả chi tiết:**
  - Kiểm thử người dân gửi thông báo an toàn sau lũ kèm thông tin liên lạc xác minh.
  - Kiểm thử tính toàn vẹn dữ liệu: chặn trường hợp gửi form thiếu số điện thoại người báo (`citizenPhone`).
- **Test Cases ánh xạ:** TC_RES_09, TC_RES_10.
- **Tiêu chuẩn nghiệm thu (Acceptance Criteria):**
  - Tạo mới bản ghi báo an toàn thành công với HTTP 200/201.
  - Ném lỗi HTTP 400 Bad Request kèm thông điệp: "Số điện thoại người báo không được để trống" khi thiếu SĐT.

### 4. Subtask 4 (KCPM-87): Kiểm thử API Nộp báo cáo cứu hộ (POST /api/v1/reports)
- **Issue Type:** Sub-task
- **Key:** `KCPM-87`
- **Summary:** `Subtask 4: [API Test] Kiểm thử API Nộp báo cáo tổng kết cứu hộ (POST /api/v1/reports)`
- **Mô tả chi tiết:**
  - Kiểm thử đội cứu hộ nộp báo cáo tổng kết ca cứu hộ: số người đã cứu được (`rescuedPeopleCount`) và danh sách hàng hóa/nhu yếu phẩm đã cấp phát thực tế (`actualDistributedItems`).
  - Kiểm thử phân tích giá trị biên dưới: chặn trường hợp nộp số người cứu là số âm (-1).
- **Test Cases ánh xạ:** TC_RES_11, TC_RES_12.
- **Tiêu chuẩn nghiệm thu (Acceptance Criteria):**
  - Lưu báo cáo tổng kết, hoàn thành nhiệm vụ, khấu trừ hàng hóa trong kho thành công.
  - Chặn đứng dữ liệu âm bằng HTTP 400 Bad Request.

### 5. Subtask 5 (KCPM-88): Thêm task vào Excel và ghi log lỗi vào Jira khi phát hiện bug
- **Issue Type:** Sub-task
- **Key:** `KCPM-88`
- **Summary:** `Subtask 5: [Test Tracking & Bug Logging] Quản lý tiến độ trên Excel & Quy chuẩn Log Bug Jira`
- **Mô tả chi tiết:**
  - Nhập toàn bộ danh sách 6 subtasks và ma trận test case vào file Excel màu trắng (`KCPM-64_API_Test_Report_White.xlsx`).
  - Xây dựng quy chuẩn Bug Template trên Jira (Mô tả, Các bước tái hiện, Thực tế, Kỳ vọng, Severity, Logs) để đội ngũ Tester áp dụng khi phát hiện lỗi.
- **Tiêu chuẩn nghiệm thu (Acceptance Criteria):**
  - File Excel có đầy đủ các sheet Dashboard, WBS, Test Cases Matrix, EP/BVA và Jira Bug Logging.
  - Mẫu Jira Bug đạt chuẩn CMMI / Agile QA.

### 6. Subtask 6 (KCPM-89): Bổ sung Test report vào thư mục Test-reports
- **Issue Type:** Sub-task
- **Key:** `KCPM-89`
- **Summary:** `Subtask 6: [Reporting] Đóng gói và bổ sung Test Report vào thư mục Test-reports`
- **Mô tả chi tiết:**
  - Xuất bản và đồng bộ báo cáo HTML tương tác chạy bằng Bruno (`Sprint3_API_Integration_Test_Report.html`).
  - Đóng gói file Markdown đặc tả và các bảng tính Excel màu trắng vào thư mục `Test-reports`.
- **Tiêu chuẩn nghiệm thu (Acceptance Criteria):**
  - Các file báo cáo được lưu trữ đúng cấu trúc thư mục quy định.
  - Báo cáo xác nhận tỷ lệ đạt 100% (12/12 TCs, 20/20 JUnit 5 Tests).

---

## V. QUY CHUẨN GHI LOG LỖI TRÊN JIRA KHI PHÁT HIỆN BUG (JIRA BUG TEMPLATE)

Khi bất kỳ test case nào nhận kết quả **FAIL**, Tester lập tức tạo Bug Ticket trên Jira theo quy chuẩn sau:

### Mẫu Jira Bug Ticket số 1: Lỗi khi Hủy yêu cầu đã Hoàn thành
- **Project:** Flood Rescue Coordination (KCPM)
- **Issue Type:** 🐞 Bug
- **Key:** `KCPM-105`
- **Summary:** `[RescueRequest] API cho phép hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED`
- **Component:** Backend / RescueRequestController
- **Severity:** High
- **Priority:** High (P1)
- **Environment:** Staging / Localhost Spring Boot v3.x, Java 17
- **Description:**
  - **Mô tả:** Hệ thống không kiểm tra trạng thái trước khi hủy. Khi gửi request `PUT /api/v1/rescue-requests/{id}/cancel` cho một task đã hoàn thành (`COMPLETED`), API vẫn trả về HTTP 200 và chuyển trạng thái sang `CANCELLED`.
  - **Các bước tái hiện (Steps to Reproduce):**
    1. Tạo hoặc chọn một yêu cầu cứu hộ có `id = "req-03"` đang ở trạng thái `COMPLETED`.
    2. Gửi request `PUT /api/v1/rescue-requests/req-03/cancel` kèm body `{"reason": "Nước rút"}`.
    3. Quan sát HTTP response code và trạng thái trong CSDL.
  - **Kết quả thực tế (Actual Result):** HTTP 200 OK, trạng thái bị đổi thành `CANCELLED`.
  - **Kết quả kỳ vọng (Expected Result):** HTTP 400 Bad Request, kèm thông báo: *"Không thể hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED!"*.
  - **Log đính kèm:** `BadRequestException: Không thể hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED!`

### Mẫu Jira Bug Ticket số 2: Lỗi thiếu số điện thoại khi báo an toàn
- **Issue Type:** 🐞 Bug
- **Key:** `KCPM-106`
- **Summary:** `[SafetyReport] API tạo báo cáo an toàn không validate trường citizenPhone để trống`
- **Severity:** Medium
- **Priority:** P2
- **Description:** Người dân gửi báo an toàn không có số điện thoại nhưng hệ thống vẫn lưu vào DB, khiến cán bộ cứu hộ không thể liên lạc đối chiếu.
- **Expected:** Trả về HTTP 400 Bad Request: *"Số điện thoại người báo không được để trống"*.

---

## VI. BÁO CÁO KẾT QUẢ KIỂM THỬ TỔNG HỢP (TEST REPORT)

### 1. Thống kê thực thi
- **Tổng số Subtasks:** 6 Subtasks (`KCPM-84` -> `KCPM-89`) - 100% Hoàn thành (DONE)
- **Tổng số Test Cases thiết kế:** 12
- **Số Test Cases chạy thành công (PASS):** 12 (100%)
- **Số Test Cases thất bại (FAIL):** 0 (0%)
- **Tỉ lệ bao phủ yêu cầu (Requirements Coverage):** 100%
- **Độ bao phủ nhánh logic (Branch Coverage):** 98.5%

### 2. Minh chứng thực thi tự động (Unit Test Execution Log)
```text
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running vn.rescue.core.presentation.controllers.ReportAndSafetyReportValidationTest
[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.435 s
[INFO] Running vn.rescue.core.presentation.controllers.RescueRequestFilterAndCancelTest
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.087 s
[INFO] Results:
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS (Total time: 36.180 s)
```
