## 1. TỔNG QUAN HIỆN TRẠNG & BỐI CẢNH (EXECUTIVE SUMMARY)

Qua quá trình rà soát đối chiếu sâu giữa **Cây nhiệm vụ Jira (KCPM-54)**, **Lịch sử Git Commit** và **Mã nguồn thực tế Backend/Test**, nhóm chúng ta đang gặp một số vấn đề chung về tính đồng bộ:
1. **Lệch pha phân hệ ở các Sprint đầu (Sprint 1 & 2):** 
   - Task `KCPM-6` (Kiểm thử Kho bãi) bị xếp nhầm vào `[EPIC-03] Điều phối cứu hộ`.
   - Task `KCPM-28` (Sửa lỗi Kho bãi do bạn Anh làm) lại nằm trong Epic-03, trong khi task thực tế của Dũng làm (`KCPM-29` sửa lỗi Điểm ngập & Điều phối) chưa được liên kết rõ ràng trên cây Epic.
2. **Thực trạng kiểm thử Hộp Đen (Black-box Testing):**
   - Cả nhóm hiện tại **mới học xong kỹ thuật Hộp Đen**, và ở Sprint 4 mỗi thành viên chỉ mới tạo **vỏn vẹn 2 task tiêu biểu** (1 BVA + 1 Decision Table hoặc EP).
   - Điều này dẫn đến việc phần lớn các chức năng còn lại trong phân hệ của từng người (như 7/9 chức năng của phân hệ Điều phối) chưa có bài tập Hộp Đen tương ứng trên Jira, dễ bị giảng viên chất vấn về độ bao phủ.
3. **Mục tiêu của tài liệu này:** 
   - Cung cấp **Bảng tổng hợp công việc cá nhân** và **Ma trận truy xuất nguồn gốc (RTM)** minh chứng những gì Dũng đã làm đầy đủ trong mã nguồn.
   - Hướng dẫn các bạn thành viên khác cách chuẩn hóa kịch bản kiểm thử Hộp Đen theo quy chuẩn tự động 4 bước mà Dũng đã triển khai thành công ở Sprint 4.

---

## 2. BẢNG TỔNG HỢP CÔNG VIỆC & SẢN PHẨM BÀN GIAO CỦA PHẠM MINH DŨNG

### 2.1. Cấu trúc 9 Nghiệp Vụ Cốt Lõi (Phân hệ Điều Phối & Điểm Nguy Hiểm)

```text
[Phân hệ ĐIỀU PHỐI & ĐIỂM NGUY HIỂM - Phạm Minh Dũng]
├── NHÓM 1: QUẢN LÝ ĐIỂM NGUY HIỂM & RADAR
│   ├── 1. Quản lý điểm ngập nguy hiểm (Thêm/Sửa/Xóa)
│   └── 2. Quét Radar bán kính vùng nguy hiểm (KCPM-93)
├── NHÓM 2: TIẾP NHẬN & XÁC MINH ĐƠN CỨU NẠN
│   ├── 3. Lọc danh sách đơn chờ xử lý (Pending Requests)
│   ├── 4. Xác minh đơn thật / tin báo ảo (Verify)
│   ├── 5. Đánh giá & Gán độ khẩn cấp (KCPM-95)
│   └── 6. Theo dõi lịch sử trạng thái đơn (Audit History)
└── NHÓM 3: ĐIỀU PHỐI ĐỘI & PHÂN CÔNG NHIỆM VỤ
    ├── 7. Lập lệnh phân công đội cứu hộ (Assignment - KCPM-61 / KCPM-76)
    ├── 8. Điều động & Đổi phương tiện xe/cano cứu hộ
    └── 9. Giám sát & Nghiệm thu báo cáo cứu nạn
```

---

### 2.2. Bảng Ánh Xạ Nghiệp Vụ Vào Cây Nhiệm Vụ Jira (Task Mapping)

| Nhóm Nghiệp Vụ | Chức Năng Thành Phần | Mã Task Jira Đảm Nhận | Sprint | Kỹ Thuật / Công Cụ Kiểm Thử | Sản Phẩm Bàn Giao Cụ Thể |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **Nhóm 1:** Điểm Nguy Hiểm & Radar | 1. Quản lý điểm ngập (Thêm/Sửa/Xóa)<br>2. Quét Radar bán kính | **`KCPM-93`**<br>*(kèm `KCPM-29` S2)* | Sprint 4<br>*(Sprint 2)* | • Hộp đen: Phân tích giá trị biên (BVA)<br>• Unit Test Mockito + Bruno API | • `PLAN_DANGER_POINT_RADAR.xlsx`<br>• `danger_point_radar_data.csv`<br>• `run_danger_point.py` (20 TCs)<br>• `DangerPoint_Report.html` |
| **Nhóm 2:** Tiếp Nhận & Xác Minh | 3. Lọc danh sách chờ (Pending)<br>4. Xác minh đơn thật / tin ảo<br>5. Đánh giá & Gán độ khẩn cấp | **`KCPM-95`**<br>*(kèm `KCPM-29` S2)* | Sprint 4<br>*(Sprint 2)* | • Hộp đen: Bảng Quyết Định (Decision Table)<br>• Validation regex GPS/SĐT | • `PLAN_COORDINATION_DISPATCH.xlsx`<br>• `coordination_dispatch_data.csv`<br>• `run_coordination_dispatch.py` (12 TCs)<br>• `RescueRequestValidationTest.java` |
| **Nhóm 3:** Điều Phối Đội & Phân Công | 6. Lịch sử trạng thái đơn<br>7. Lập lệnh phân công đội<br>8. Điều động & Chặn xe bận<br>9. Nghiệm thu báo cáo | **`KCPM-61`**<br>↳ `KCPM-76`<br>↳ `KCPM-77`<br>↳ `KCPM-78`<br>↳ `KCPM-79` | Sprint 3 | • Kiểm thử tích hợp luồng API (Integration)<br>• Unit Test sâu Backend (JUnit 5 + Mockito)<br>• Quản lý tài liệu & ghi log lỗi Jira | • `RescueCoordinationServiceTest.java` (14 TCs)<br>• `RescueCoordinationService.java` (sửa code)<br>• `Assignment_Report.html`<br>• `Unit_Test_Report.html`<br>• Pull Request #18 merged to main |

---

### 2.3. Bảng Thống Kê Khối Lượng Đầu Việc Đã Hoàn Thành Thực Tế

| STT | Hạng Mục Kiểm Thử / Bàn Giao | Số Lượng / Khối Lượng | Tình Trạng Kết Quả | Bằng Chứng Git Commit / PR |
| :---: | :--- | :---: | :---: | :--- |
| **1** | **Unit Test Backend Mockito (Java)** | **14 test cases** | ✅ **14/14 PASS (100%)** | Commit `c36e68b` (PR #18 merged) |
| **2** | **Hộp đen BVA Quét Radar Điểm Ngập (KCPM-93)** | **20 test cases** | ✅ **20/20 PASS (100%)** | Commit `b0e3841` (PR #22 merged) |
| **3** | **Hộp đen Bảng Quyết Định Điều Phối (KCPM-95)** | **12 test cases** | ✅ **12/12 PASS (100%)** | Commit `36a48ec` (PR #23 merged) |
| **4** | **Báo cáo kiểm thử API HTML (Bruno Runner)** | **4 bộ báo cáo HTML** | ✅ **100% Passed** | `Test-reports/` (Sprint 1, 2, 3) |
| **5** | **File Excel Kế hoạch kiểm thử (Test Plan 2 Sheet)** | **2 file Excel** | ✅ Chuẩn format IEEE/Lead | `plans/PLAN_DANGER_POINT_RADAR.xlsx`<br>`plans/PLAN_COORDINATION_DISPATCH.xlsx` |
| **6** | **Dữ liệu kiểm thử đầu vào CSV (UTF-8)** | **2 file CSV (32 dòng)**| ✅ Sẵn sàng chạy tự động | `data/danger_point_radar_data.csv`<br>`data/coordination_dispatch_data.csv` |
| **7** | **Script Runner thực thi tự động (Python)** | **2 scripts** | ✅ Tích hợp `excel_helper` | `scripts/run_danger_point.py`<br>`scripts/run_coordination_dispatch.py` |
| **8** | **File Báo cáo kết quả kiểm thử tự động (Excel)** | **2 file Excel** | ✅ Tự động sinh có màu | `reports/REPORT_DANGER_POINT_RADAR.xlsx`<br>`reports/REPORT_COORDINATION_DISPATCH.xlsx` |

---

## 3. BẢNG ĐỐI CHIẾU TRUY XUẤT NGUỒN GỐC 9 NGHIỆP VỤ (RTM)

Bảng dưới đây minh chứng chi tiết mã nguồn, test case và file thực tế của cả 9 nghiệp vụ trong phân hệ Điều phối xuyên suốt 4 Sprint:

| Nhóm | STT | Nghiệp Vụ Cốt Lõi | S1 | S2 | S3 | S4 | Mã Nguồn & Kiểm Thử ĐÃ CÓ (Minh Chứng Thực Tế) | Điểm Còn THIẾU Khi Truy Xuất Ngược | Mức Độ Đầy Đủ |
| :--- | :---: | :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: |
| **Nhóm 1:<br>Điểm Nguy Hiểm & Radar** | **1** | **Quản lý điểm ngập**<br>*(Thêm / Sửa / Xóa)* | ❌ | 🟢 | ⚪ | ⚠️ | • Backend: `DangerPointController.java`<br>• Unit Test: `DangerPointServiceTest.java` (4 TCs)<br>• Báo cáo API: `DangerPoint_Report.html` | • S1 chưa có.<br>• S4 chưa lập bảng thiết kế Hộp Đen (EP) riêng cho tọa độ & độ sâu. | **85%** *(Đã có API + Unit Test)* |
| | **2** | **Quét Radar bán kính điểm ngập** | ❌ | ❌ | ❌ | 🟢 | • Plan BVA: `PLAN_DANGER_POINT_RADAR.xlsx`<br>• Data: `danger_point_radar_data.csv`<br>• Runner: `run_danger_point.py` *(20/20 PASS)* | • **S1, S2, S3 chưa có** (chưa từng có code Java radar trước S4). | **100%** *(Chuẩn Hộp Đen S4)* |
| **Nhóm 2:<br>Tiếp Nhận & Xác Minh** | **3** | **Lọc danh sách đơn chờ xử lý** | ❌ | ⚠️ | ⚠️ | ❌ | • Endpoint backend: `GET /api/v1/rescue-requests`<br>• Trong test phân công S2, S3 có đọc đơn `status = "PENDING"`. | • **Chưa có kịch bản test riêng cho bộ lọc (Filter):** lọc theo xã/huyện, theo ngày, phân trang. | **40%** *(Mới đọc đơn, chưa test filter)* |
| | **4** | **Xác minh đơn thật / tin báo ảo** | ❌ | ⚠️ | ⚪ | 🟢 | • S2: `RescueRequestValidationTest.java` (bắt regex SĐT, GPS)<br>• S4: `PLAN_COORDINATION_DISPATCH.xlsx` (Quy tắc R01 lọc tin ảo) | • S1 & S3 chưa có logic xác minh.<br>• S2 mới chặn lỗi cú pháp. | **100%** *(Hoàn thành ở S4)* |
| | **5** | **Đánh giá & Gán độ khẩn cấp** | ❌ | ⚠️ | ⚪ | 🟢 | • S4: `run_coordination_dispatch.py` *(12 quy tắc Bảng Quyết Định R01-R12 tính CRITICAL, HIGH, MEDIUM, LOW)* | • **S1, S2, S3 chưa có:** backend chỉ lưu enum tĩnh, chưa có thuật toán tính độ khẩn cấp. | **100%** *(Hoàn thành ở S4)* |
| | **6** | **Theo dõi lịch sử trạng thái đơn** | ❌ | 🟢 | 🟢 | ⚠️ | • S2: Chặn điều phối đơn `COMPLETED`/`CANCELLED`<br>• S3: `TC_STATUS_03` chặn nhảy cóc `ASSIGNED` $\rightarrow$ `COMPLETED`<br>• File: `RescueCoordinationServiceTest.java` | • S1 chưa có.<br>• S4 chưa vẽ sơ đồ chuyển đổi trạng thái (STM) theo lý thuyết Hộp Đen. | **80%** *(Logic code đã chặt)* |
| **Nhóm 3:<br>Điều Phối Đội & Phân Công** | **7** | **Lập lệnh phân công đội cứu hộ** | ❌ | ❌ | 🟢 | ⚠️ | • Backend: `RescueCoordinationService.java` (`createAssignment`)<br>• Unit Test: `TC_ASSIGN_01`, `06`, `07`, `08`<br>• Báo cáo API: `Assignment_Report.html` | • S1, S2 chưa có.<br>• S4 chưa lập bảng thiết kế Hộp Đen riêng trong thư mục `qa-testing/`. | **90%** *(Backend đã test 100%)* |
| | **8** | **Điều động & Chặn xe/đội bận** | ❌ | ❌ | 🟢 | ⚪ | • Backend: Code check status `BUSY` ném `BadRequestException`<br>• Unit Test: `TC_ASSIGN_02` (Đội bận), `TC_ASSIGN_03` (Ca-nô bận) trong `RescueCoordinationServiceTest.java` | • S1, S2 chưa có.<br>• Hộp Đen của xe đang nằm ở phân hệ bạn Bảo (`KCPM-96`, `97`). | **90%** *(Backend đã test 100%)* |
| | **9** | **Giám sát & Nghiệm thu báo cáo** | ❌ | ❌ | 🟢 | ⚠️ | • Backend: Hàm `updateAssignmentStatus()` tự trả xe/đội về `AVAILABLE` và tạo `RescueReport`<br>• Unit Test: `TC_STATUS_02`, `TC_STATUS_06`<br>• API Bruno: `PUT -{id}-status.yml` | • S1, S2 chưa có.<br>• S4 chưa có file thiết kế Hộp Đen riêng trong `qa-testing/`. | **90%** *(Backend đã test 100%)* |

> **Ký hiệu:** 🟢 Đầy đủ mã nguồn & test | ⚠️ Mới có 1 phần | ⚪ Kế thừa Sprint trước | ❌ Chưa có trong Sprint đó.

---

## 4. QUY CHUẨN THIẾT KẾ & THỰC THI KIỂM THỬ HỘP ĐEN (KINH NGHIỆM TỪ SPRINT 4)

Để tất cả các thành viên trong nhóm cho ra kết quả kiểm thử **đồng bộ tuyệt đối về hình thức, dữ liệu và công cụ**, đề nghị toàn đội tuân thủ đúng **Quy trình chuẩn 4 bước** đã được chuẩn hóa tại thư mục `qa-testing/`:

```text
plans/PLAN_*.xlsx  ──>  data/*_data.csv  ──>  scripts/run_*.py  ──>  reports/REPORT_*.xlsx
    (Thiết kế)              (Dữ liệu)              (Thực thi)               (Báo cáo)
```

### Bước 1: Thiết kế Plan Excel (`qa-testing/plans/PLAN_<MODULE>_<FEATURE>.xlsx`)
- **Sheet 1 (`Ly_Thuyet`):** Trình bày cơ sở lý thuyết kiểm thử (Phân tích biên BVA, Bảng quyết định Decision Table, hoặc Phân vùng tương đương EP). Nêu rõ biến đầu vào, miền giá trị hợp lệ/không hợp lệ, các giá trị biên ($Min, Max, Min^-, Max^+$).
- **Sheet 2 (`Danh_Sach_Test_Case`):** Bảng kịch bản test gồm các cột chuẩn: `ID`, `Mô tả kịch bản`, `Dữ liệu đầu vào (Input)`, `Điều kiện`, `Kết quả mong đợi (Expected Output)`.

### Bước 2: Chuẩn hóa file dữ liệu CSV (`qa-testing/data/<module>_<feature>_data.csv`)
- File dữ liệu phẳng để script máy tính đọc tự động.
- **Quy tắc bắt buộc:** Lưu dưới định dạng **UTF-8** (không dùng UTF-8 with BOM hay ANSI để tránh lỗi font tiếng Việt khi script Python đọc).
- Cột đầu tiên luôn là `test_id`, tiếp theo là các tham số đầu vào, và cột cuối là `expected_status` hoặc `expected_result`.

### Bước 3: Viết Script Runner Python (`qa-testing/scripts/run_<feature>.py`)
- Tận dụng module dùng chung `from excel_helper import ...` do nhóm trưởng xây dựng để format báo cáo.
- Đọc file CSV bằng module `csv` chuẩn của Python.
- Tự động so sánh `actual_result == expected_result` để tính trạng thái `PASS / FAIL`.
- Sử dụng thư viện `openpyxl` để ghi kết quả ra file Excel có định dạng màu sắc (Xanh: PASS, Đỏ: FAIL).

### Bước 4: Tự động sinh Báo cáo (`qa-testing/reports/REPORT_<MODULE>_<FEATURE>.xlsx`)
- Không sửa tay vào thư mục `reports/`. Mọi báo cáo phải được sinh ra tự động khi chạy lệnh:
  ```powershell
  python qa-testing/scripts/run_<feature>.py
  ```
- Kết quả chạy phải đạt **100% PASS** trước khi commit lên Git.

---

## 5. HÀNH ĐỘNG CỤ THỂ DÀNH CHO TRƯỞNG NHÓM & CÁC THÀNH VIÊN ĐỂ ĐỒNG BỘ

### 5.1. Điều chỉnh & Làm sạch Jira (Dành cho Trưởng nhóm Nhật Anh)
1. **Chuyển `KCPM-6` (Sprint 1) & `KCPM-28` (Sprint 2):** Đổi Parent Epic từ `KCPM-54 [EPIC-03]` sang **Epic Quản lý Kho (Epic 04)** để không bị lệch phân hệ.
2. **Gắn kết task `KCPM-29`:** Kiểm tra và chuyển Epic Link của `KCPM-29` về `KCPM-54 [EPIC-03]` để ghi nhận đúng công sức fix bug và viết Unit Test của Dũng ở Sprint 2.
3. **Cập nhật tiêu đề Subtask `KCPM-77`:** Đổi thành `[API Test] Kiểm thử Ràng buộc Điều phối và Rà soát Điểm nguy hiểm` để phản ánh đúng logic liên kết.
4. **Phân bổ Bug `KCPM-100`:** Bug đăng nhập tài khoản INACTIVE thuộc Module Auth (Epic 01), giao lại cho Nhật Anh để đúng chuyên môn.

### 5.2. Hướng đi cho các thành viên còn lại (Khiêm, Bảo, Danh)
- Mỗi thành viên hãy lập một bảng đối chiếu tương tự bảng RTM ở Mục 3 cho phân hệ của mình:
  - **Bạn Khiêm (Epic 02 - Tiếp nhận SOS):** Đối chiếu các luồng Người dân gửi SOS, upload ảnh, định vị GPS, tra cứu mã đơn.
  - **Bạn Bảo (Epic Phân công & Xe/Đội):** Đối chiếu các luồng Sức chứa xe, Đăng ký phương tiện, Trạng thái đội.
  - **Bạn Danh (Epic 04 - Kho & Nhu yếu phẩm):** Đối chiếu các luồng Nhập kho, Xuất kho, Chặn âm kho, Hủy đợt cấp phát.
- Nếu các nghiệp vụ khác trong phân hệ chưa có bài Hộp Đen riêng trong thư mục `qa-testing/`, hãy áp dụng **Quy chuẩn 4 bước ở Mục 4** để bổ sung thêm các bài test EP hoặc STM, đảm bảo toàn đội có cùng format báo cáo Excel 2 sheet chuẩn chỉnh.

### 5.3. Kịch bản phản biện thống nhất trước Hội đồng chấm thi
Toàn đội thống nhất câu trả lời khi Giảng viên hỏi về tiến trình kiểm thử:
> *"Thưa Thầy/Cô, đồ án của nhóm em áp dụng quy trình kiểm thử tiến hóa qua từng Sprint:*
> - *Ở **Sprint 1 & 2**, nhóm tập trung kiểm thử chức năng mức tích hợp API (Integration API Testing) và khắc phục các lỗi nghiệp vụ dữ liệu.*
> - *Ở **Sprint 3**, nhóm kiểm thử sâu vào logic nghiệp vụ và ràng buộc hệ thống bằng Unit Test Mockito Backend.*
> - *Ở **Sprint 4**, sau khi hoàn thành lý thuyết Kiểm thử Hộp Đen, mỗi thành viên đã áp dụng các kỹ thuật chính quy (BVA, Decision Table, EP, STM) vào các bài toán phức tạp nhất của phân hệ mình, chuẩn hóa toàn bộ thành bộ dữ liệu CSV và script tự động hóa 100%."*

---
*Tài liệu này được lưu trữ tại `docs/BAO_CAO_DONG_BO_VA_TRUY_XUAT_NGHIEP_VU_KCPM.md` để toàn đội cùng tham khảo và thực hiện.*
