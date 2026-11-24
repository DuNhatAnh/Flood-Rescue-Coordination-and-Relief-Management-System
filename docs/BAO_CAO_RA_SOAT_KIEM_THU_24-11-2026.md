# BÁO CÁO RÀ SOÁT KIỂM THỬ – 24/11/2026

> **Người rà soát:** Trưởng nhóm (Dư Nhật Anh)
> **Phạm vi:** 4 loại kiểm thử – Bruno API · QA Data-Driven · JUnit 5 + Mockito · CodeceptJS E2E
> **Môi trường:** backend chạy local `http://localhost:8080`, DB seed ngày 24/11/2026
> **Tài liệu liên quan:** [CO_SO_TINH_SO_TESTCASE.xlsx](CO_SO_TINH_SO_TESTCASE.xlsx) · [TEST_MATRIX.md](TEST_MATRIX.md)

---

## 1. Kết quả chạy thật

| Loại kiểm thử | Lệnh chạy | Kết quả | Ghi chú |
|:---|:---|:---:|:---|
| Bruno API | `bru run -r --env Local` (thư mục `bruno/`) | **190/190** | Đã sửa 4 request lỗi do ID cứng và 2 request phụ thuộc thứ tự chạy |
| QA Data-Driven | `python qa-testing/scripts/run_*.py` (11 script) | **197/198** | TC_CPW_13 chủ đích chuyển sang JUnit. **Chỉ 3/11 script gọi backend thật** (mục 3.1) |
| JUnit 5 + Mockito | `mvn test` (thư mục `backend/`) | **167/167** | Đủ `@DisplayName`; ~70 test chưa đúng quy chuẩn đặt tên (mục 3.3) |
| CodeceptJS E2E | `npx codeceptjs run` (thư mục `test-automation/`) | **50/50** | Đã chuẩn hóa tên 10 kịch bản Epic 02, 05 |

---

## 2. Đã sửa trong đợt rà soát

| # | Loại | Nội dung sửa | File |
|:---:|:---|:---|:---|
| 1 | Bruno | Bổ sung 46 request BVA mạnh 6n+1 cho KCPM-80, 109, 101, 113, 115; sửa 3 ca cũ về đúng biên (5 ký tự, lat 23.40, lng 102.13) | `bruno/EPIC-0*/...` |
| 2 | Bruno | 4 request KCPM-115, KCPM-116 dùng ID kho/vật tư cứng → trả 404 sau khi seed lại DB. Chuyển sang tự lấy ID thật ở `before-request` | `KCPM-115_Inventory_Stock/*`, `KCPM-116_Distribution_Export/POST -tao-phieu-xuat.yml` |
| 3 | Bruno | `TC_REQ_10`, `TC_REQ_12` dùng `completedRequestId` do `TC_REQ_13` (chạy sau) tạo → fail ở lần chạy đầu. Nay tự tạo đơn SOS `COMPLETED` trước khi chạy | `KCPM-05_Citizen_SOS_Request/POST -{id}-confirm-safety.yml`, `PUT -{id}-cancel-completed-invalid.yml` |
| 4 | Bruno – đồng bộ tên | Request mới đặt theo đúng quy ước `[KCPM-xx] TC_XXX_NN - Mô tả`; KCPM-109 đổi `BVA TCnn` → `TC_RES_nn` khớp mã testcase trong `citizen_rescue_request_data.csv` | 59 file |
| 5 | CodeceptJS – đồng bộ tên | 10 kịch bản Epic 02, 05 đặt tên kiểu `[Scenario 1]`, `[SCENARIO 1]` → chuẩn `[E2E-xx-yy] [TYPE] ... [METHOD /endpoint]` theo `GUIDE_CODECEPTJS.md` | `citizen_portal_test.js`, `warehouse_distribution_test.js` |
| 6 | Tài liệu | `qa-testing/README.md` lặp 3 dòng lệnh chạy Epic 01 → xóa dòng lặp | `qa-testing/README.md` |
| 7 | Tài liệu | `TEST_MATRIX.md`: cập nhật số liệu 24/11, đổi tham chiếu `Scenario n` → `E2E-02-0n`, `E2E-05-0n`; sửa ghi chú radar (đã có lọc bán kính từ commit `d305441`) | `docs/TEST_MATRIX.md` |

---

## 3. Vấn đề còn tồn tại – cần xử lý

### 3.1. QA Data-Driven: 8/11 script mô phỏng logic, không gọi backend (Mức độ: Cao)

Các script dưới đây có hàm `simulate()` viết lại luật nghiệp vụ bằng Python rồi so với chính CSV. Kết quả "PASS" chỉ chứng minh script khớp với CSV, **không chứng minh hệ thống chạy đúng**. Đã chạy thử trên backend thật 2 bộ nhập kho, phương tiện: phát hiện thêm 1 bug (BUG-02) mà bản mô phỏng che mất.

| Script | Số ca | Chủ Epic | Gọi backend thật? |
|:---|:---:|:---|:---:|
| `run_change_password.py`, `run_login.py`, `run_rbac.py` | 36 | 01 – Dư Nhật Anh | ✅ |
| `run_rescue_request.py`, `run_safety_report.py` | 53 | 02 – Lâm Khiêm | ❌ |
| `run_danger_point.py`, `run_coordination_dispatch.py` | 32 | 03 – Phạm Minh Dũng | ❌ |
| `run_vehicles.py`, `run_teams.py` | 50 | 04 – Nguyễn Bảo | ❌ |
| `run_inventory.py`, `run_distribution.py` | 27 | 05 – Phan Quốc Danh | ❌ |

**Cách sửa:** làm theo mẫu Epic 01 – thay `simulate()` bằng lời gọi `live_api.call(...)` (file `qa-testing/scripts/live_api.py` đã có sẵn đăng nhập Admin, tạo dữ liệu).

### 3.2. Bug backend chưa có trên Jira

Bản nháp ở mục 4, sẵn để tạo issue loại **Bug** trên Jira.

### 3.3. JUnit: test chưa theo quy chuẩn `GUIDE_JUNIT.md`

Quy chuẩn: tên method `test<ChứcNăng>_<ĐiềuKiện>_<KếtQuả>()`, `@DisplayName` bắt đầu bằng mã testcase (`TC_XXX_NN:`). Tất cả test đều đã có `@DisplayName`; phần lệch là thiếu mã TC hoặc tên method:

| Lớp test | Thiếu mã TC trong DisplayName | Sai mẫu tên method | Chủ Epic |
|:---|:---:|:---:|:---|
| `RoleServiceTest` | 4 | 4 | 01 |
| `UserAccountManagementTest` | 0 | 8 | 01 |
| `RbacAuthorizationTest` | 0 | 6 | 01 |
| `UserServiceTest` | 2 | 0 | 01 |
| `AccessDeniedStatusTest` | 1 | 3 | 01 |
| `RescueRequestValidationTest` | 6 | 0 | 02 |
| `RescueRequestFilterAndCancelTest` | 12 | 0 | 02 |
| `ReportAndSafetyReportValidationTest` | 17 | 17 | 02 |
| `FileUploadControllerTest` | 3 | 3 | 02 |
| `DangerPointServiceTest` | 4 | 0 | 03 |
| `VehiclesServiceValidationTest` | 2 | 7 | 04 |
| `NotificationControllerTest` | 4 | 4 | 06 (dùng chung) |

### 3.4. JUnit: thiếu ca so với công thức N = V(G) + C

(Công thức và cách tính ở sheet `JUnit5 + Mockito` của file Excel.)

| Hàm | Ca còn thiếu | Chủ Epic |
|:---|:---|:---|
| `UserService.changePassword` | mật khẩu cũ trống; mật khẩu mới trống; biên hợp lệ đúng 6 ký tự | 01 |
| `RescueRequestService.createRequest` | chưa có unit test nào cho biên lãnh thổ VN (lat 8.18/23.39, lng 102.14/109.46 và ngoài biên) | 02 |
| `RescueRequestDto` | biên hợp lệ lat = ±90, lng = ±180 | 02 |
| `DangerPointService.getDangerPointsNearby` | tách riêng lat/lng từng phía; biên hợp lệ ±90, ±180; radius = 1 | 03 |
| `VehiclesService.validateVehicleRequest` | biên Max+1 đúng 21 (hiện chỉ có 25) | 04 |
| `InventoryService.importStock` | request null; mã kho trống; số lượng null | 05 |

### 3.5. Lệch giữa thiết kế và code – cần chủ Epic chốt

| # | Điểm lệch | Đề xuất của trưởng nhóm | Chủ Epic |
|:---:|:---|:---|:---|
| 1 | `vehicles_management_data.csv` TC_VEH_10 yêu cầu bắt buộc `capacity`, backend để tùy chọn (frontend chưa gửi) | Giữ backend, sửa kỳ vọng TC_VEH_10 thành 201 | 04 |
| 2 | Radar: thiết kế KCPM-111 bán kính 50..5000 m, code chỉ chặn `radius <= 0` | Ghi bug BUG-03; Bruno hiện kiểm thử theo code (biên > 0) | 03 |
| 3 | `coordination_dispatch_data.csv` mô tả tự tính mức khẩn cấp, backend chỉ nhận mức gán tay | Viết lại bảng quyết định theo luồng gán tay | 03 |
| 4 | `citizen_safety_report_data.csv` TC_TRK_01–03 dùng mã `RES-2026-001`, backend dùng `customId` dạng `0001` | Sửa dữ liệu CSV theo định dạng thật | 02 |

---

## 4. Bản nháp bug để tạo trên Jira

> Đã tái hiện trên backend local ngày 24/11/2026 bằng request thật.

### BUG-01 — `POST /api/v1/rescue-reports` không kiểm tra biên `rescuedPeopleCount`
- **Mức độ:** High · **Epic:** 02 (Lâm Khiêm) · **Liên kết:** KCPM-109
- **Bước tái hiện:** đăng nhập Admin → `POST /api/v1/rescue-reports` với `rescuedPeopleCount` = `-1`, `51`, `9999`.
- **Kết quả thực tế:** cả 3 đều trả **200** và lưu vào DB.
- **Kết quả mong đợi:** **400 Bad Request** khi ngoài miền 0..50 (thiết kế TEST_MATRIX mục 2.6, KCPM-109).
- **Gợi ý sửa:** thêm `@Min(0)` `@Max(50)` cho `rescuedPeopleCount` trong DTO báo cáo cứu hộ + `@Valid` ở controller.

### BUG-02 — Nhập kho không chặn ngày nhập ở tương lai
- **Mức độ:** Medium · **Epic:** 05 (Phan Quốc Danh) · **Liên kết:** KCPM-115, TC_IMP_10
- **Bước tái hiện:** `POST /api/v1/inventory/import` với `importDate = 2099-12-31T00:00:00`, số lượng 100.
- **Kết quả thực tế:** **200 – Nhập kho thành công**; `StockInRequest` không có trường `importDate` nên giá trị bị bỏ qua.
- **Kết quả mong đợi:** **400** – "Ngày nhập kho không được lớn hơn ngày hiện tại" (theo `inventory_import_data.csv` TC_IMP_10).
- **Gợi ý sửa:** thêm `importDate` vào `StockInRequest`, kiểm tra `importDate <= now()` trong `InventoryService.importStock`.

### BUG-03 — Điểm ngập nhận mực nước âm/quá lớn; bán kính radar chưa có biên 50..5000 m
- **Mức độ:** Medium · **Epic:** 03 (Phạm Minh Dũng) · **Liên kết:** KCPM-111, KCPM-101
- **Bước tái hiện:** `POST /api/v1/danger-points` với `depth = -5` và `depth = 9999`; `GET /api/v1/danger-points?lat=16.05&lng=108.2&radius=1`.
- **Kết quả thực tế:** tạo điểm ngập thành công (**200**) với cả 2 mực nước; radius = 1 m được chấp nhận.
- **Kết quả mong đợi:** **400** khi mực nước ngoài 10..500 cm và khi bán kính ngoài 50..5000 m (thiết kế KCPM-111).
- **Gợi ý sửa:** validate `depth` khi tạo/cập nhật điểm ngập; thêm biên dưới 50, biên trên 5000 cho `radius` trong `DangerPointService`. **Lưu ý:** khi sửa, cập nhật lại các request Bruno `TC_DP_17`–`TC_DP_19` (đang theo biên hiện tại > 0).

---

## 5. Phân công xử lý

| Thành viên | Việc cần làm | Hạn đề xuất |
|:---|:---|:---|
| Dư Nhật Anh (Epic 01) | Tạo 3 bug trên Jira (mục 4); chuẩn hóa tên test 5 lớp Epic 01; bổ sung 3 unit test `changePassword` | 26/11/2026 |
| Lâm Khiêm (Epic 02) | Sửa BUG-01; chuyển `run_rescue_request.py`, `run_safety_report.py` sang gọi backend thật; chuẩn hóa tên 4 lớp test; bổ sung unit test biên lãnh thổ VN | 28/11/2026 |
| Phạm Minh Dũng (Epic 03) | Sửa BUG-03; chuyển 2 script QA sang backend thật; chốt điểm lệch 3.5 #2, #3 | 28/11/2026 |
| Nguyễn Bảo (Epic 04) | Chuyển `run_vehicles.py`, `run_teams.py` sang backend thật; chốt TC_VEH_10; bổ sung unit test capacity = 21 | 28/11/2026 |
| Phan Quốc Danh (Epic 05) | Sửa BUG-02; chuyển `run_inventory.py`, `run_distribution.py` sang backend thật; bổ sung 3 unit test `importStock` | 28/11/2026 |

**Lưu ý dữ liệu:** trong lúc tái hiện BUG-01 đã sinh 3 bản ghi báo cáo cứu hộ thử (`rescuedPeopleCount` = -1, 51, 9999) trên DB local; seed lại DB trước buổi demo nếu cần số liệu sạch.
