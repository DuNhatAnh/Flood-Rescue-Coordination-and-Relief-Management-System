# MA TRẬN ĐỐI SOÁT KIỂM THỬ (TEST MATRIX)

> **Dự án:** Hệ thống Điều phối Cứu hộ Lũ lụt & Quản lý Cứu trợ (Flood Rescue System)  
> **4 Trụ cột kiểm thử:** White-box (JUnit 5) · Bruno API · Black-box QA Data-Driven · CodeceptJS (E2E)  
> **Ký hiệu:** ✅ Đã kiểm thử & Pass · ⚠️ Có một phần / Đang bổ sung · ❌ Chưa kiểm thử
> **Đối soát lần cuối:** 24/11/2026 — JUnit **175/175** · CodeceptJS **50/50** · Bruno **197/197** · QA **197/198** (TC_CPW_13 chỉ kiểm thử ở JUnit) — chạy trên **backend thật**; riêng QA chỉ 3/11 script (Epic 01) gọi backend thật, 8 script còn lại vẫn mô phỏng bằng Python (xem mục E)

---

## 1. EPIC 01 - DƯ NHẬT ANH: Xác thực, Phân quyền & Quản trị Hệ thống

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 1.1 | Đăng nhập hệ thống & Cấp JWT Token | `POST /api/auth/login` | ✅ `AuthControllerTest` (4 TCs - KCPM-100) | ✅ `TC_AUTH_01` + KCPM-100 (tự tạo & khóa tài khoản) | ✅ `auth_login_data.csv` (10 TCs - gọi backend thật) | ✅ E2E-01-01, 01-02 | **Đạt** |
| 1.2 | Đổi mật khẩu (BVA độ dài Min 6, Max 32) | `POST /api/v1/auth/change-password` | ✅ `UserServiceTest` (6 TCs) | ✅ `TC_AUTH_08` → `TC_AUTH_11` | ✅ `auth_change_password_data.csv` (14 TCs - gọi backend thật, TC_CPW_13 chỉ ở JUnit) | ✅ E2E-01-03, 01-04 | **Đạt** |
| 1.3 | Quản lý người dùng (Danh sách, Chi tiết, Tạo mới) | `/api/v1/admin/users` | ⚠️ Chưa có test riêng cho CRUD | ✅ `TC_USER_01` → `TC_USER_06`, `TC_USER_09`, `TC_USER_10` | ✅ `auth_rbac_data.csv` | ✅ E2E-01-05 | **Đạt** |
| 1.4 | Khóa / Mở khóa tài khoản (`ACTIVE`/`INACTIVE`/`LOCKED`) | `PUT /api/v1/admin/users/{id}/status` | ✅ `UserAccountManagementTest` (4 TCs) + `RbacAuthorizationTest` TC_RBAC_UT_04 | ✅ `TC_USER_07`, `TC_USER_08` (trạng thái sai → 400) | ✅ `auth_login_data.csv` TC_LOG_10 | ✅ E2E-01-05, 01-06 | **Đạt** |
| 1.5 | Gán / Đổi vai trò (Role) tài khoản | `PUT /api/v1/admin/users/{id}/role` | ✅ `UserAccountManagementTest` (4 TCs) | ✅ `TC_USER_06` | ✅ `auth_rbac_data.csv` | ✅ E2E-01-05 | **Đạt** |
| 1.6 | Quản lý vai trò & Ma trận phân quyền chéo (RBAC) | `/api/v1/admin/roles` | ✅ `RoleServiceTest` (4) + `RbacAuthorizationTest` (7) + `AccessDeniedStatusTest` (3 - phân biệt 401/403) | ✅ `TC_ROLE_01` → `TC_ROLE_13` (CRUD + RBAC 401/403) | ✅ `auth_rbac_data.csv` (12 TCs - gọi backend thật, token hết hạn ký thật) | ✅ E2E-01-07 | **Đạt** |
| 1.7 | Cấu hình & Dashboard hệ thống quản trị | `/api/v1/admin/system/*` | ✅ `AdminSystemControllerTest` (11 TCs) | ✅ `TC_SYS_01` → `TC_SYS_08` | ✅ `KCPM-107_AdminSystem_Test_Report.xlsx` (19 TCs) | ❌ Chưa tích hợp | **Đạt** |

---

## 2. EPIC 02 - LÂM KHIÊM: Cổng Người dân & Tiếp nhận Cứu nạn SOS

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 2.1 | Gửi yêu cầu cứu nạn SOS (BVA người 1..50, ghi chú, GPS) | `POST /api/v1/rescue-requests` | ✅ `RescueRequestValidationTest` (13 TCs) | ✅ 13 requests BVA riêng | ✅ `citizen_rescue_request_data.csv` (31 TCs) | ✅ E2E-02-01, E2E-02-04 | **Đạt** |
| 2.2 | Tra cứu tiến độ cứu hộ công dân qua mã Tracking | `GET /api/v1/rescue-requests/track/{id}` | ✅ `RescueRequestFilterAndCancelTest` | ✅ `GET -track-{id}.yml` | ✅ `citizen_safety_report_data.csv` | ✅ E2E-02-01 | **Đạt** |
| 2.3 | Lọc danh sách cứu nạn theo quận/huyện & trạng thái | `GET /api/v1/rescue-requests` | ✅ `RescueRequestFilterAndCancelTest` (12 TCs) | ✅ 4 requests lọc | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 2.4 | Hủy đơn cứu nạn (Chặn hủy khi đã `COMPLETED`) | `PUT /api/v1/rescue-requests/{id}/cancel` | ✅ `RescueRequestFilterAndCancelTest` | ✅ `PUT -{id}-cancel-*.yml` | ❌ Chưa có test riêng | ✅ E2E-02-03 | **Đạt** |
| 2.5 | Báo an toàn công dân (EP SĐT 10 số nhà mạng VN) | `POST /api/v1/safety-reports` | ✅ `ReportAndSafetyReportValidationTest` (17 TCs) | ✅ 3 requests BVA Phone | ✅ `citizen_safety_report_data.csv` (22 TCs) | ✅ E2E-02-02, E2E-02-05 | **Đạt** |
| 2.6 | Nộp báo cáo cứu nạn hiện trường (BVA số người cứu 0..50) | `POST /api/v1/rescue-reports` | ✅ `RescueReportControllerTest` (2 TCs) | ✅ 4 requests BVA count | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 2.7 | Upload ảnh hiện trường cứu hộ (Chặn file lỗi/sai đuôi) | `POST /api/upload/image` | ✅ `FileUploadControllerTest` (3 TCs) | ✅ `POST -image.yml` | ❌ Chưa có test riêng | ✅ `upload_notification_report_test.js` | **Đạt** |

---

## 3. EPIC 03 - PHẠM MINH DŨNG: Điều phối Tác chiến & Bản đồ Nguy hiểm

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 3.1 | Quản lý điểm ngập trên radar (CRUD, bắt 404) | `/api/v1/danger-points` | ✅ `DangerPointServiceTest` (4 TCs - chỉ 404 sửa/xóa) | ✅ 4 requests CRUD | ⚠️ `danger_point_radar_data.csv` (20 TCs - BVA bán kính, backend chưa có tính năng này) | ✅ E2E-03-07, 03-08 | **Đạt** |
| 3.2 | Xác minh & Gán độ khẩn cấp (Decision Table) | `/api/v1/rescue-requests/{id}/urgency` | ✅ `RescueCoordinationServiceTest` | ✅ `PUT -{id}-urgency.yml` | ✅ `coordination_dispatch_data.csv` (12 TCs) | ✅ E2E-03-09 | **Đạt** |
| 3.3 | Lập lệnh phân công nhiệm vụ cho Đội cơ động | `POST /api/v1/assignments` | ✅ `RescueCoordinationServiceTest` (14 TCs) | ✅ `POST -.yml` | ✅ `coordination_dispatch_data.csv` | ✅ E2E-03-01 → 03-03 | **Đạt** |
| 3.4 | Cập nhật trạng thái nhiệm vụ (`ASSIGNED` → `COMPLETED`) | `PUT /api/v1/assignments/{id}/status` | ✅ `RescueCoordinationServiceTest` | ✅ `PUT -{id}-status.yml` | ❌ Chưa có test riêng | ✅ E2E-03-06 | **Đạt** |
| 3.5 | Thay đổi phương tiện cano/xe cứu hộ cho nhiệm vụ | `PUT /api/v1/assignments/{id}/vehicle` | ✅ `RescueCoordinationServiceTest` | ✅ `PUT -{id}-vehicle.yml` | ❌ Chưa có test riêng | ✅ E2E-03-05 (bắt bug 500 → đã sửa 400) | **Đạt** |
| 3.6 | Đính kèm tệp / video hiện trường vào đơn cứu nạn | `/api/v1/attachments/*` | ❌ Chưa có unit test | ✅ 2 requests upload/get | ❌ Chưa có test riêng | ❌ Chưa tích hợp | ⚠️ Cần bổ sung |

---

## 4. EPIC 04 - NGUYỄN BẢO: Đội cơ động & Phương tiện cứu hộ

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 4.1 | Quản lý Đội cứu nạn (CRUD, bắt lỗi 404 đội không tồn tại) | `/api/v1/teams/*` | ✅ `Sprint2ModuleFixesTest` (BUG-TEAM-01) | ✅ 3 requests CRUD | ✅ `teams_availability_data.csv` | ✅ E2E-04-01 → 04-04 | **Đạt** |
| 4.2 | Đăng ký phương tiện cứu hộ (BVA sức chứa 1..20, trùng biển) | `POST /api/v1/vehicles` | ✅ `Sprint2ModuleFixesTest` (BUG-VEHICLE-01) + `VehiclesServiceValidationTest` (7 - POST/PUT/danh sách) | ✅ `POST -.yml`, `PUT -{id}.yml` | ✅ `vehicles_management_data.csv` (26 TCs) | ✅ E2E-04-06, 04-07, 04-10 | **Đạt** |
| 4.3 | Máy trạng thái xe & đội (`AVAILABLE` ↔ `BUSY`) — ⚠️ chưa có API chuyển `MAINTENANCE` | `POST /api/v1/assignments/dispatch` | ✅ `Sprint2ModuleFixesTest` (BUG-ASSIGNMENT-01 chặn xe bận) | ✅ `PUT -{id}.yml` | ✅ `teams_availability_data.csv` (24 TCs) | ✅ E2E-04-11, 04-12 | **Đạt** |
| 4.4 | Lọc phương tiện sẵn sàng xuất kích (`AVAILABLE`) | `GET /api/v1/vehicles/available` | ⚠️ `Sprint2ModuleFixesTest` BVA-06 (chỉ kiểm tra lại dữ liệu mock) | ✅ `GET -available.yml` | ✅ `vehicles_management_data.csv` | ✅ E2E-04-09 | **Đạt** |
| 4.5 | Lệnh xuất kích phối hợp (Gán cùng lúc Đội + Phương tiện) | `POST /api/v1/assignments/dispatch` | ✅ `RescueCoordinationServiceTest` | ✅ `POST -dispatch.yml` | ❌ Chưa có test riêng | ✅ E2E-03-04 | **Đạt** |

---

## 5. EPIC 05 - PHAN QUỐC DANH: Quản lý Kho Hàng & Cứu trợ Hiện trường

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 5.1 | Quản lý danh mục Kho hàng & Giải thể kho (Bắt 404) | `/api/v1/warehouses/*` | ✅ `WarehouseServiceTest` (5 TCs) | ✅ 6 requests CRUD | ❌ Chưa có test riêng | ✅ E2E-05-01 | **Đạt** |
| 5.2 | Danh mục nhu yếu phẩm cứu trợ (Validate bắt buộc tên/đơn vị) | `/api/v1/relief-items/*` | ✅ `ReliefItemServiceTest` (4 TCs) | ✅ 4 requests CRUD | ❌ Chưa có test riêng | ✅ E2E-05-01 | **Đạt** |
| 5.3 | Nhập kho nhu yếu phẩm (BVA số lượng 1..10000, chặn ngày âm) | `POST /api/v1/inventory/import` | ✅ `InventoryServiceTest` (12 TCs) | ✅ `POST -import.yml` | ✅ `inventory_import_data.csv` (14 TCs) | ✅ E2E-05-02 | **Đạt** |
| 5.4 | Tra cứu thẻ kho & Cảnh báo tồn kho cạn kiệt (Low stock) | `/api/v1/inventory/warehouse/*` | ✅ `InventoryServiceTest` | ✅ 2 requests stock/low-stock | ❌ Chưa có test riêng | ✅ E2E-05-02, E2E-05-04, E2E-05-05 (đối soát thẻ kho) | **Đạt** |
| 5.5 | Xuất kho cứu trợ theo nhiệm vụ (Decision Table chặn âm kho) | `POST /api/v1/distributions` | ✅ `DistributionServiceTest` (8 TCs - BUG-DIST-01) | ✅ `POST -.yml` | ✅ `distribution_export_data.csv` (13 TCs) | ✅ E2E-05-03, E2E-05-04 | **Đạt** |
| 5.6 | Hủy phiếu xuất và tự động hoàn kho (Rollback Inventory) | `POST /api/v1/distributions/{id}/cancel` | ✅ `DistributionServiceTest` (4 TCs KCPM-103 - logic hoàn kho) + `DistributionControllerTest` (2 TCs) | ✅ `POST -complete-transfer.yml` | ❌ Chưa có test riêng | ✅ E2E-05-05 (500 → 300 → 500) | **Đạt** |

---

## 6. PHÂN HỆ DÙNG CHUNG: Báo cáo & Thông báo

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 6.1 | Gửi thông báo khẩn cấp (Validate thiếu title/user) | `POST /api/v1/notifications` | ✅ `NotificationControllerTest` (4 TCs) | ✅ `POST -.yml` | ❌ Chưa có test riêng | ✅ E2E-06-02, 06-03, 06-05 | **Đạt** |
| 6.2 | Đọc và quản lý danh sách thông báo người dùng | `/api/v1/notifications/*` | ✅ `NotificationControllerTest` | ✅ 5 requests read/unread | ❌ Chưa có test riêng | ✅ E2E-06-04, 06-05 | **Đạt** |
| 6.3 | Báo cáo thống kê phân tích KPI & Xu hướng kho | `/api/v1/reports/*` | ✅ `ReportAndSafetyReportValidationTest` | ✅ 9 requests reports/trends | ❌ Chưa có test riêng | ✅ E2E-06-06 → 06-11 | **Đạt** |
| 6.4 | Upload tập tin hệ thống chung | `POST /api/v1/files/upload` | ❌ Chưa có unit test | ✅ `POST -upload.yml` | ❌ Chưa có test riêng | ❌ Chưa tích hợp | ⚠️ Cần bổ sung |

---

## 7. CÁC CHỨC NĂNG CHƯA KIỂM THỬ

Dưới đây là danh sách toàn bộ các tính năng chưa có bất kỳ kịch bản kiểm thử nào (0 Bruno, 0 JUnit, 0 QA Data-Driven, 0 CodeceptJS):

### A. API Backend chưa kiểm thử:
1. Gia hạn JWT Token (`POST /api/auth/refresh` - lỗi 404 do thiếu controller)
2. Xem nhật ký hệ thống (`GET /api/v1/admin/system/logs`) - *(Đã kiểm thử hoàn tất tại KCPM-107)*
3. Báo cáo phân tích hệ thống chuyên sâu (`GET /api/v1/admin/system/analytics`) - *(Đã kiểm thử hoàn tất tại KCPM-107)*
4. Báo cáo tổng hợp Admin (`GET /api/v1/admin/system/reports/general`) - *(Đã kiểm thử hoàn tất tại KCPM-107)*
5. ~~Lọc danh sách đội cứu hộ sẵn sàng (`GET /api/v1/teams/available`)~~ - *(Đã có E2E-04-02)*
6. Endpoint tổng hợp báo cáo gốc (`GET /api/v1/reports`)

### B. Màn hình Giao diện Flutter Frontend chưa có UI Test (25 màn hình):
1. `HomeScreen` (Màn hình chính công dân)
2. `RescueRequestScreen` (Màn hình gửi yêu cầu SOS)
3. `TrackRescueRequestScreen` (Màn hình theo dõi tiến độ SOS)
4. `SafetyReportScreen` (Màn hình báo an toàn công dân)
5. `StaffMainScreen` (Màn hình chính nhân viên cứu hộ)
6. `TeamTasksScreen` (Màn hình danh sách nhiệm vụ đội)
7. `StaffVehicleManagementScreen` (Màn hình quản lý xe đội)
8. `StaffManagedWarehouseScreen` (Màn hình kho phụ trách)
9. `WarehouseInventoryScreen` (Màn hình chi tiết thẻ kho)
10. `DistributionExportScreen` (Màn hình xuất kho phát cứu trợ)
11. `DistributionHistoryScreen` (Màn hình lịch sử cấp phát hàng)
12. `RescueReportScreen` (Màn hình nộp biên bản cứu nạn)
13. `CoordinatorMainScreen` (Màn hình chính điều phối viên)
14. `AssignmentScreen` (Màn hình phân công nhiệm vụ)
15. `TrackingScreen` (Màn hình theo dõi bản đồ cứu hộ)
16. `RequestHistoryScreen` (Màn hình lịch sử điều phối)
17. `AnalyticsScreen` (Màn hình phân tích hiệu suất)
18. `SystemDashboardScreen` (Màn hình dashboard quản trị)
19. `UserManagementScreen` (Màn hình quản lý người dùng)
20. `RoleManagementScreen` (Màn hình quản trị vai trò)
21. `DangerPointManagementScreen` (Màn hình quản lý điểm ngập lụt)
22. `VehicleManagementScreen` (Màn hình quản lý phương tiện)
23. `WarehouseManagementScreen` (Màn hình quản lý kho bãi)
24. `NotificationManagementScreen` (Màn hình quản trị thông báo)
25. `SystemSettingsScreen` (Màn hình cài đặt tham số hệ thống)

### C. Kết quả đối soát chéo 5 bộ kiểm thử (18/11/2026)

**Đã sửa (chưa có task Jira):**
1. `GET /api/v1/vehicles` ẩn xe có `warehouseId = null` → không lọc kho khi không truyền `warehouseId`.
2. `PUT /api/v1/vehicles/{id}` với ID không tồn tại trả **500** → nay **404**; PUT bổ sung validate biển số rỗng/trùng, sức chứa 1..20 (TC_VEH_20, 22, 23, 24).
3. `PUT /assignments/{id}/vehicle` sai kiểu dữ liệu trả **500** → nay **400** (E2E-03-05).
4. Đổi mật khẩu thiếu luật **Max 32 ký tự** theo thiết kế KCPM-88 → đã bổ sung.
5. Đăng nhập không kiểm tra định dạng email / rỗng (thiết kế KCPM-89 yêu cầu 400) → đã bổ sung.
6. Gọi API quản trị khi chưa xác thực (không token / hết hạn / giả mạo) trả **403** → nay **401** theo thiết kế KCPM-90; đã đăng nhập nhưng thiếu quyền vẫn **403**.
7. KCPM-100: thông báo tiếng Việt "Tài khoản đã bị vô hiệu hóa…" không bao giờ trả ra (Spring Security chặn trước) → đã sửa; unit test cũ mock `authenticate()` nên không phát hiện.
8. `PUT /admin/users/{id}/status` nhận mọi chuỗi trạng thái → chỉ nhận `ACTIVE` / `INACTIVE` / `LOCKED`.
9. Bruno: folder AdminUser đổi tên admin thật và **khóa tài khoản mẫu `staff@rescue.vn`** mỗi lần chạy; folder AdminSystem chạy trước Auth nên dùng token cũ; 13 request dùng ID cứng đã hết hạn → đã viết lại tự tạo dữ liệu.
10. QA Epic 01 (`run_login.py`, `run_change_password.py`, `run_rbac.py`) trước đây **mô phỏng logic bằng Python** → nay gọi backend thật qua `qa-testing/scripts/live_api.py`.

**Đã có task Jira — không sửa trong đợt này:**
| Điểm lệch | Task Jira | Ghi chú |
|:---|:---|:---|
| `POST /api/auth/refresh` vẫn 404 | KCPM-92 (Done) | Code chưa có controller dù task đã Done |
| Radar lọc theo bán kính (`danger_point_radar_data.csv` BVA 50m..5000m) | KCPM-101 (Done), KCPM-111 (In Progress) | Đã có lọc bán kính (commit `d305441`), nhưng code chỉ chặn `radius <= 0`, chưa có biên 50..5000 m như thiết kế |
| Chuyển xe sang `MAINTENANCE` (`teams_availability_data.csv`) | KCPM-114 (Done) | Chưa có API đổi trạng thái xe |
| Upload file đa dụng | KCPM-117 (To Do) | Bruno chỉ kiểm thử nhánh thiếu file (400) |

**Còn lệch, cần chủ Epic quyết định (QA vẫn mô phỏng bằng Python, chưa gọi backend thật):**
1. `citizen_safety_report_data.csv` TC_TRK_01–03 dùng mã `RES-2026-001`, backend dùng `customId` dạng `0001` — Epic 02.
2. `inventory_import_data.csv` TC_IMP_10 kiểm tra "ngày nhập ở tương lai" nhưng `StockInRequest` không có trường `importDate` — Epic 05.
3. `vehicles_management_data.csv` TC_VEH_10 yêu cầu bắt buộc sức chứa, nhưng frontend chưa gửi `capacity` nên backend giữ là tùy chọn — Epic 04.
4. `coordination_dispatch_data.csv` mô tả bảng quyết định tự tính mức khẩn cấp, backend chỉ nhận mức khẩn cấp do điều phối viên gán tay — Epic 03.

### D. Kiểm thử Phi chức năng chưa thực hiện:
1. Kiểm thử tải và độ chịu đựng bão lũ (Load & Stress Testing với JMeter / k6)
2. Kiểm thử xâm nhập bảo mật (Security Penetration Testing với OWASP ZAP)
