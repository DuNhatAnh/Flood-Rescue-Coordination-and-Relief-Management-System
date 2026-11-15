# 📋 KẾ HOẠCH HÀNH ĐỘNG BỔ SUNG KIỂM THỬ TOÀN DIỆN (TEST ACTION PLAN)

> **Dự án:** Hệ thống Điều phối Cứu hộ Lũ lụt & Quản lý Cứu trợ (Flood Rescue System)  
> **Mục tiêu:** Bổ sung đầy đủ các phần còn thiếu (`⚠️ Thiếu White-box`, `❌ Chưa tích hợp CodeceptJS`) trong file [TEST_MATRIX.md](TEST_MATRIX.md) để đạt độ phủ 100% trên cả 4 trụ cột kiểm thử.  
> **Tài liệu đặc tả & hướng dẫn kỹ thuật chuẩn hóa đính kèm:**
> - 📋 [Đặc tả chi tiết các Task Jira đã khởi tạo](JIRA_TASKS_SPECIFICATION.md)
> - 📄 [Hướng dẫn viết Request Bruno API](GUIDE_BRUNO.md)
> - 📄 [Hướng dẫn viết White-box Unit Test JUnit 5](GUIDE_JUNIT.md)
> - 📄 [Hướng dẫn viết Kịch bản E2E CodeceptJS](GUIDE_CODECEPTJS.md)

---

## 🎯 DANH SÁCH 12 TASK HÀNH ĐỘNG THEO THÀNH VIÊN & EPIC

### 🛡️ EPIC 01 - DƯ NHẬT ANH: Xác thực, Phân quyền & Quản trị Hệ thống

| Mã Jira | Tên Task & Nội dung thực hiện | Hạng mục giải quyết trong Matrix | Sản phẩm bàn giao (Deliverables) |
|:---|:---|:---:|:---|
| [**KCPM-106**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-106) | **[White-box] Bổ sung Unit Test Mockito cho Phân hệ Auth, Khóa tài khoản & RBAC**<br>• Bổ sung test chặn login tài khoản `INACTIVE` (`AuthServiceTest`).<br>• Bổ sung test hàm `updateUserStatus` và `updateUserRole` (`UserServiceTest`).<br>• Bổ sung test kiểm tra annotation `@PreAuthorize` cho các Role. | `⚠️ 1.1`<br>`⚠️ 1.4`<br>`⚠️ 1.5`<br>`⚠️ 1.6` | • `AuthServiceTest.java`<br>• `UserServiceTest.java`<br>• `RoleControllerTest.java` |
| [**KCPM-107**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-107) | **[White-box] Viết mới Unit Test cho Module Cấu hình & Dashboard (AdminSystemTest)**<br>• Tạo mới `AdminSystemControllerTest.java`.<br>• Test `GET/PUT /api/v1/admin/system/config` và `GET /dashboard/{warehouseId}`. | `❌ 1.7` | • `backend/src/test/java/.../AdminSystemControllerTest.java` (≥ 4 TCs) |
| [**KCPM-108**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-108) | **[CodeceptJS] Xây dựng kịch bản E2E cho Phân hệ Quản trị & Xác thực**<br>• Tạo file `test-automation/auth_admin_test.js`.<br>• Viết các Scenario: Đổi mật khẩu, Vòng đời User (Tạo -> Đổi role -> Khóa), Chặn quyền CITIZEN (403 Forbidden). | `❌ 1.2`<br>`❌ 1.3`<br>`❌ 1.4`<br>`❌ 1.5`<br>`❌ 1.6` | • `test-automation/auth_admin_test.js` (≥ 4 Scenarios) |

---

### 🆘 EPIC 02 - LÂM KHIÊM: Cổng Người dân & Tiếp nhận Cứu nạn SOS

| Mã Jira | Tên Task & Nội dung thực hiện | Hạng mục giải quyết trong Matrix | Sản phẩm bàn giao (Deliverables) |
|:---|:---|:---:|:---|
| [**KCPM-109**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-109) | **[White-box] Bổ sung Unit Test BVA Biên số người, Ghi chú SOS & Báo cáo kết thúc**<br>• Bổ sung vào `RescueRequestValidationTest.java`: Biên số người (0, 1, 50, 51) và độ dài ghi chú (1000, 1001).<br>• Bổ sung method test nộp biên bản cứu nạn với `rescuedPeopleCount = 0` và `50`. | `⚠️ 2.1`<br>`⚠️ 2.6` | • `RescueRequestValidationTest.java`<br>• `RescueReportControllerTest.java` |
| [**KCPM-110**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-110) | **[CodeceptJS] Xây dựng kịch bản E2E Cổng Người dân & Báo an toàn**<br>• Tạo file `test-automation/citizen_portal_test.js`.<br>• Viết Scenario: Gửi SOS -> Tra cứu tiến độ (`GET /track/{id}`) -> Gửi Báo an toàn (`POST /safety-reports`) -> Hủy đơn cứu hộ (`PUT /cancel`). | `❌ 2.2`<br>`❌ 2.3`<br>`❌ 2.4`<br>`❌ 2.5` | • `test-automation/citizen_portal_test.js` (≥ 3 Scenarios) |

---

### 🚤 EPIC 03 - PHẠM MINH DŨNG: Điều phối Tác chiến & Bản đồ Nguy hiểm

| Mã Jira | Tên Task & Nội dung thực hiện | Hạng mục giải quyết trong Matrix | Sản phẩm bàn giao (Deliverables) |
|:---|:---|:---:|:---|
| [**KCPM-111**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-111) | **[White-box] Bổ sung Unit Test BVA Bán kính Radar, Mực nước ngập & File đính kèm**<br>• Bổ sung vào `DangerPointServiceTest.java`: BVA bán kính quét radar [50m..5000m] và mực nước [10cm..500cm].<br>• Viết Unit test cho hàm lọc bán kính GPS Radius quanh toạ độ nạn nhân (KCPM-101).<br>• Tạo mới `AttachmentControllerTest.java`: Test upload và lấy file theo requestId. | `⚠️ 3.1`<br>`❌ 3.6` | • `DangerPointServiceTest.java`<br>• `AttachmentControllerTest.java` |
| [**KCPM-112**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-112) | **[CodeceptJS] Mở rộng Kịch bản E2E Tác chiến Điều phối: Xác minh, Khẩn cấp & Đổi xe**<br>• Bổ sung vào `test-automation/assignment_dispatch_test.js`.<br>• Kịch bản tạo Điểm nguy hiểm (`POST /danger-points`) -> Xác minh đơn (`PUT /verify`) -> Gán độ khẩn cấp (`PUT /urgency`) -> Đổi ca-nô cho nhiệm vụ (`PUT /vehicle`). | `❌ 3.1`<br>`❌ 3.2`<br>`❌ 3.5`<br>`❌ 3.6` | • `test-automation/assignment_dispatch_test.js` (Mở rộng thêm 3 Scenarios) |

---

### 🚚 EPIC 04 - NGUYỄN BẢO: Đội cơ động & Phương tiện cứu hộ

| Mã Jira | Tên Task & Nội dung thực hiện | Hạng mục giải quyết trong Matrix | Sản phẩm bàn giao (Deliverables) |
|:---|:---|:---:|:---|
| [**KCPM-113**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-113) | **[White-box] Bổ sung Unit Test BVA Sức chứa phương tiện & Lọc xe sẵn sàng**<br>• Bổ sung vào `Sprint2ModuleFixesTest.java`: Test BVA sức chứa `capacity` [1..20], bắt lỗi capacity = 0 hoặc 25.<br>• Viết method test hàm lọc phương tiện sẵn sàng `GET /api/v1/vehicles/available`. | `⚠️ 4.2`<br>`⚠️ 4.4` | • `Sprint2ModuleFixesTest.java` |
| [**KCPM-114**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-114) | **[CodeceptJS] Mở rộng Kịch bản E2E Máy trạng thái Xe gặp sự cố (Maintenance State)**<br>• Bổ sung vào `test-automation/team_vehicles_test.js`.<br>• Kịch bản: Lọc xe `AVAILABLE` -> Điều động xe (`BUSY`) -> Báo hỏng chuyển `MAINTENANCE` -> Chặn điều phối xe hỏng -> Nghiệm thu sửa chữa về `AVAILABLE`. | `❌ 4.4` | • `test-automation/team_vehicles_test.js` (Mở rộng thêm 2 Scenarios) |

---

### 📦 EPIC 05 - PHAN QUỐC DANH: Quản lý Kho Hàng & Cứu trợ Hiện trường

| Mã Jira | Tên Task & Nội dung thực hiện | Hạng mục giải quyết trong Matrix | Sản phẩm bàn giao (Deliverables) |
|:---|:---|:---:|:---|
| [**KCPM-115**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-115) | **[White-box] Xây dựng bộ Unit Test mới cho Quản lý Nhập kho (InventoryServiceTest)**<br>• Tạo mới file `InventoryServiceTest.java`.<br>• Viết test BVA số lượng nhập kho (`quantity` 1..10000, bắt lỗi <= 0 hoặc > 10000).<br>• Viết test ràng buộc hạn dùng (`expiryDate <= importDate`).<br>• Viết test tra cứu thẻ kho và cảnh báo tồn cạn kiệt (`low-stock`). | `⚠️ 5.3`<br>`⚠️ 5.4` | • `backend/src/test/java/.../InventoryServiceTest.java` (≥ 6 TCs) |
| [**KCPM-116**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-116) | **[CodeceptJS] Xây dựng Kịch bản E2E Chuỗi Nhập kho, Xuất kho & Hoàn kho (Rollback)**<br>• Tạo file mới `test-automation/warehouse_distribution_test.js`.<br>• Viết chuỗi kịch bản: Tạo kho & Nhu yếu phẩm -> Nhập kho tăng tồn -> Xuất kho giảm tồn (chặn âm kho) -> Hủy phiếu xuất tự động hoàn trả tồn kho (KCPM-103). | `❌ 5.1`<br>`❌ 5.2`<br>`❌ 5.3`<br>`❌ 5.4`<br>`❌ 5.5`<br>`❌ 5.6` | • `test-automation/warehouse_distribution_test.js` (≥ 4 Scenarios) |

---

### 📢 PHÂN HỆ DÙNG CHUNG: Báo cáo & File Upload

| Mã Jira | Tên Task & Nội dung thực hiện | Hạng mục giải quyết trong Matrix | Sản phẩm bàn giao (Deliverables) |
|:---|:---|:---:|:---|
| [**KCPM-117**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-117) | **[White-box & CodeceptJS] Bổ sung kiểm thử FileUpload chung và Báo cáo Xu hướng kho**<br>• Viết `FileControllerTest.java` test upload file đa dụng.<br>• Bổ sung vào `test-automation/upload_notification_report_test.js` kịch bản gọi báo cáo xu hướng tồn kho (`GET /reports/warehouse-trend`) và danh mục khả dụng (`GET /reports/available-items`). | `⚠️ 6.4`<br>`❌ 6.3` | • `FileControllerTest.java`<br>• `upload_notification_report_test.js` |

---

## 📅 LỘ TRÌNH THỰC HIỆN ĐỀ XUẤT (ROADMAP)

```
Tuần 1: Hoàn thiện White-box Unit Test (TASK-01-A, 01-B, 02-A, 03-A, 04-A, 05-A, 06-A)
  └── Đảm bảo `mvn test` pass 100% (Số test tăng từ 88 lên ~120 test cases).

Tuần 2: Hoàn thiện Kịch bản CodeceptJS E2E (TASK-01-C, 02-B, 03-B, 04-B, 05-B)
  └── Đảm bảo `npm run test:api` pass 100% (Số scenarios tăng từ 26 lên ~45 scenarios).

Tuần 3: Chạy toàn diện CI/CD Pipeline & Cập nhật nghiệm thu lên Jira
  └── Chuyển toàn bộ các dòng `⚠️` và `❌` trong TEST_MATRIX.md sang `✅` Đạt.
```
