# MA TRẬN ĐỐI SOÁT KIỂM THỬ (TEST MATRIX)

> **Dự án:** Hệ thống Điều phối Cứu hộ Lũ lụt & Quản lý Cứu trợ (Flood Rescue System)  
> **4 Trụ cột kiểm thử:** White-box (JUnit 5) · Bruno API · Black-box QA Data-Driven · CodeceptJS (E2E)  
> **Ký hiệu:** ✅ Đã kiểm thử & Pass · ⚠️ Có một phần / Đang bổ sung · ❌ Chưa kiểm thử

---

## 1. EPIC 01 - DƯ NHẬT ANH: Xác thực, Phân quyền & Quản trị Hệ thống

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 1.1 | Đăng nhập hệ thống & Cấp JWT Token | `POST /login` | ⚠️ `AuthServiceTest` | ✅ `POST -login.yml` | ✅ `auth_login_data.csv` (10 TCs) | ✅ Auto Login Token | **Đạt** |
| 1.2 | Đổi mật khẩu (BVA độ dài Min 6, Max 32) | `POST /change-password` | ✅ `UserServiceTest` (6 TCs) | ✅ `POST -change-password-*.yml` | ✅ `auth_change_password_data.csv` (14 TCs) | ❌ Chưa tích hợp | **Đạt** |
| 1.3 | Quản lý người dùng (Danh sách, Chi tiết, Tạo mới) | `/api/v1/admin/users` | ✅ `UserServiceTest` | ✅ 4 requests CRUD | ✅ `auth_rbac_data.csv` | ❌ Chưa tích hợp | **Đạt** |
| 1.4 | Khóa / Mở khóa tài khoản (`ACTIVE`/`INACTIVE`) | `PUT /api/v1/admin/users/{id}/status` | ⚠️ Service logic | ✅ `PUT -{id}-status.yml` | ✅ `auth_login_data.csv` (Chặn khóa) | ❌ Chưa tích hợp | **Đạt** |
| 1.5 | Gán / Đổi vai trò (Role) tài khoản | `PUT /api/v1/admin/users/{id}/role` | ⚠️ Service logic | ✅ `PUT -{id}-role.yml` | ✅ `auth_rbac_data.csv` | ❌ Chưa tích hợp | **Đạt** |
| 1.6 | Ma trận phân quyền truy cập chéo (RBAC Matrix) | `/api/v1/admin/roles` | ⚠️ Security Test | ✅ 5 requests Role CRUD | ✅ `auth_rbac_data.csv` (12 TCs) | ❌ Chưa tích hợp | **Đạt** |
| 1.7 | Cấu hình & Dashboard hệ thống quản trị | `/api/v1/admin/system/*` | ❌ Chưa có unit test | ✅ 4 requests config/dash | ❌ Chưa có test riêng | ❌ Chưa tích hợp | ⚠️ Cần bổ sung |

---

## 2. EPIC 02 - LÂM KHIÊM: Cổng Người dân & Tiếp nhận Cứu nạn SOS

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 2.1 | Gửi yêu cầu cứu nạn SOS (BVA người 1..50, ghi chú, GPS) | `POST /api/v1/rescue-requests` | ✅ `RescueRequestValidationTest` (6 TCs) | ✅ 13 requests BVA riêng | ✅ `citizen_rescue_request_data.csv` (31 TCs) | ✅ Kịch bản tạo đơn REQ | **Đạt** |
| 2.2 | Tra cứu tiến độ cứu hộ công dân qua mã Tracking | `GET /api/v1/rescue-requests/track/{id}` | ✅ `RescueRequestFilterAndCancelTest` | ✅ `GET -track-{id}.yml` | ✅ `citizen_safety_report_data.csv` | ❌ Chưa tích hợp | **Đạt** |
| 2.3 | Lọc danh sách cứu nạn theo quận/huyện & trạng thái | `GET /api/v1/rescue-requests` | ✅ `RescueRequestFilterAndCancelTest` (12 TCs) | ✅ 4 requests lọc | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 2.4 | Hủy đơn cứu nạn (Chặn hủy khi đã `COMPLETED`) | `PUT /api/v1/rescue-requests/{id}/cancel` | ✅ `RescueRequestFilterAndCancelTest` | ✅ `PUT -{id}-cancel-*.yml` | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 2.5 | Báo an toàn công dân (EP SĐT 10 số nhà mạng VN) | `POST /api/v1/safety-reports` | ✅ `ReportAndSafetyReportValidationTest` (17 TCs) | ✅ 3 requests BVA Phone | ✅ `citizen_safety_report_data.csv` (22 TCs) | ❌ Chưa tích hợp | **Đạt** |
| 2.6 | Nộp báo cáo cứu nạn hiện trường (BVA số người cứu 0..50) | `POST /api/v1/rescue-reports` | ⚠️ Controller test | ✅ 4 requests BVA count | ❌ Chưa có test riêng | ✅ `upload_notification_report_test.js` | **Đạt** |
| 2.7 | Upload ảnh hiện trường cứu hộ (Chặn file lỗi/sai đuôi) | `POST /api/upload/image` | ✅ `FileUploadControllerTest` (3 TCs) | ✅ `POST -image.yml` | ❌ Chưa có test riêng | ✅ `upload_notification_report_test.js` | **Đạt** |

---

## 3. EPIC 03 - PHẠM MINH DŨNG: Điều phối Tác chiến & Bản đồ Nguy hiểm

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 3.1 | Quét radar điểm ngập (BVA bán kính 50m..5000m & độ sâu) | `POST & GET /api/v1/danger-points` | ✅ `DangerPointServiceTest` (4 TCs) | ✅ 4 requests CRUD | ✅ `danger_point_radar_data.csv` (20 TCs) | ❌ Chưa tích hợp | **Đạt** |
| 3.2 | Xác minh & Gán độ khẩn cấp (Decision Table) | `/api/v1/rescue-requests/{id}/urgency` | ✅ `RescueCoordinationServiceTest` | ✅ `PUT -{id}-urgency.yml` | ✅ `coordination_dispatch_data.csv` (12 TCs) | ❌ Chưa tích hợp | **Đạt** |
| 3.3 | Lập lệnh phân công nhiệm vụ cho Đội cơ động | `POST /api/v1/assignments` | ✅ `RescueCoordinationServiceTest` (14 TCs) | ✅ `POST -.yml` | ✅ `coordination_dispatch_data.csv` | ✅ `assignment_dispatch_test.js` (6 scenarios) | **Đạt** |
| 3.4 | Cập nhật trạng thái nhiệm vụ (`ASSIGNED` → `COMPLETED`) | `PUT /api/v1/assignments/{id}/status` | ✅ `RescueCoordinationServiceTest` | ✅ `PUT -{id}-status.yml` | ❌ Chưa có test riêng | ✅ `assignment_dispatch_test.js` | **Đạt** |
| 3.5 | Thay đổi phương tiện cano/xe cứu hộ cho nhiệm vụ | `PUT /api/v1/assignments/{id}/vehicle` | ✅ `RescueCoordinationServiceTest` | ✅ `PUT -{id}-vehicle.yml` | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 3.6 | Đính kèm tệp / video hiện trường vào đơn cứu nạn | `/api/v1/attachments/*` | ❌ Chưa có unit test | ✅ 2 requests upload/get | ❌ Chưa có test riêng | ❌ Chưa tích hợp | ⚠️ Cần bổ sung |

---

## 4. EPIC 04 - NGUYỄN BẢO: Đội cơ động & Phương tiện cứu hộ

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 4.1 | Quản lý Đội cứu nạn (CRUD, bắt lỗi 404 đội không tồn tại) | `/api/v1/teams/*` | ✅ `Sprint2ModuleFixesTest` (BUG-TEAM-01) | ✅ 3 requests CRUD | ✅ `teams_availability_data.csv` | ✅ `team_vehicles_test.js` (11 scenarios) | **Đạt** |
| 4.2 | Đăng ký phương tiện cứu hộ (BVA sức chứa 1..20, trùng biển) | `POST /api/v1/vehicles` | ✅ `Sprint2ModuleFixesTest` (BUG-VEHICLE-01) | ✅ `POST -.yml` | ✅ `vehicles_management_data.csv` (26 TCs) | ✅ `team_vehicles_test.js` | **Đạt** |
| 4.3 | Máy trạng thái xe & đội (`AVAILABLE` ↔ `BUSY` ↔ `MAINTENANCE`) | `PUT /api/v1/vehicles/{id}` | ✅ `RescueCoordinationServiceTest` (Chặn xe bận) | ✅ `PUT -{id}.yml` | ✅ `teams_availability_data.csv` (24 TCs) | ✅ `team_vehicles_test.js` | **Đạt** |
| 4.4 | Lọc phương tiện sẵn sàng xuất kích (`AVAILABLE`) | `GET /api/v1/vehicles/available` | ⚠️ Service logic | ✅ `GET -available.yml` | ✅ `vehicles_management_data.csv` | ❌ Chưa tích hợp | **Đạt** |
| 4.5 | Lệnh xuất kích phối hợp (Gán cùng lúc Đội + Phương tiện) | `POST /api/v1/assignments/dispatch` | ✅ `RescueCoordinationServiceTest` | ✅ `POST -dispatch.yml` | ❌ Chưa có test riêng | ✅ `assignment_dispatch_test.js` | **Đạt** |

---

## 5. EPIC 05 - PHAN QUỐC DANH: Quản lý Kho Hàng & Cứu trợ Hiện trường

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 5.1 | Quản lý danh mục Kho hàng & Giải thể kho (Bắt 404) | `/api/v1/warehouses/*` | ✅ `WarehouseServiceTest` (5 TCs) | ✅ 6 requests CRUD | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 5.2 | Danh mục nhu yếu phẩm cứu trợ (Validate bắt buộc tên/đơn vị) | `/api/v1/relief-items/*` | ✅ `ReliefItemServiceTest` (4 TCs) | ✅ 4 requests CRUD | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 5.3 | Nhập kho nhu yếu phẩm (BVA số lượng 1..10000, chặn ngày âm) | `POST /api/v1/inventory/import` | ✅ `InventoryServiceTest` (12 TCs) | ✅ `POST -import.yml` | ✅ `inventory_import_data.csv` (14 TCs) | ✅ `warehouse_distribution_test.js` | **Đạt** |
| 5.4 | Tra cứu thẻ kho & Cảnh báo tồn kho cạn kiệt (Low stock) | `/api/v1/inventory/warehouse/*` | ✅ `InventoryServiceTest` | ✅ 2 requests stock/low-stock | ❌ Chưa có test riêng | ✅ `warehouse_distribution_test.js` | **Đạt** |
| 5.5 | Xuất kho cứu trợ theo nhiệm vụ (Decision Table chặn âm kho) | `POST /api/v1/distributions` | ✅ `DistributionServiceTest` (8 TCs - BUG-DIST-01) | ✅ `POST -.yml` | ✅ `distribution_export_data.csv` (13 TCs) | ❌ Chưa tích hợp | **Đạt** |
| 5.6 | Hủy phiếu xuất và tự động hoàn kho (Rollback Inventory) | `POST /api/v1/distributions/{id}/cancel` | ✅ `DistributionControllerTest` (2 TCs) | ✅ `POST -complete-transfer.yml` | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |

---

## 6. PHÂN HỆ DÙNG CHUNG: Báo cáo & Thông báo

| STT | Chức năng nghiệp vụ | Endpoint API | White-box (JUnit 5) | Bruno API | QA Data-Driven | CodeceptJS (E2E) | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|:---:|
| 6.1 | Gửi thông báo khẩn cấp (Validate thiếu title/user) | `POST /api/v1/notifications` | ✅ `NotificationControllerTest` (4 TCs) | ✅ `POST -.yml` | ❌ Chưa có test riêng | ✅ `upload_notification_report_test.js` (9 scenarios) | **Đạt** |
| 6.2 | Đọc và quản lý danh sách thông báo người dùng | `/api/v1/notifications/*` | ✅ `NotificationControllerTest` | ✅ 5 requests read/unread | ❌ Chưa có test riêng | ✅ `upload_notification_report_test.js` | **Đạt** |
| 6.3 | Báo cáo thống kê phân tích KPI & Xu hướng kho | `/api/v1/reports/*` | ✅ `ReportAndSafetyReportValidationTest` | ✅ 9 requests reports/trends | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |
| 6.4 | Upload tập tin hệ thống chung | `POST /api/v1/files/upload` | ⚠️ Service logic | ✅ `POST -upload.yml` | ❌ Chưa có test riêng | ❌ Chưa tích hợp | **Đạt** |

---

## 7. CÁC CHỨC NĂNG CHƯA KIỂM THỬ

Dưới đây là danh sách toàn bộ các tính năng chưa có bất kỳ kịch bản kiểm thử nào (0 Bruno, 0 JUnit, 0 QA Data-Driven, 0 CodeceptJS):

### A. API Backend chưa kiểm thử:
1. Gia hạn JWT Token (`POST /api/auth/refresh` - lỗi 404 do thiếu controller)
2. Xem nhật ký hệ thống (`GET /api/v1/admin/system/logs`)
3. Báo cáo phân tích hệ thống chuyên sâu (`GET /api/v1/admin/system/analytics`)
4. Báo cáo tổng hợp Admin (`GET /api/v1/admin/system/reports/general`)
5. Lọc danh sách đội cứu hộ sẵn sàng (`GET /api/v1/teams/available`)
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

### C. Kiểm thử Phi chức năng chưa thực hiện:
1. Kiểm thử tải và độ chịu đựng bão lũ (Load & Stress Testing với JMeter / k6)
2. Kiểm thử xâm nhập bảo mật (Security Penetration Testing với OWASP ZAP)
