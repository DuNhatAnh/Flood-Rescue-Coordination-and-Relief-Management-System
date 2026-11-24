# 📋 ĐẶC TẢ CHI TIẾT CÁC TASK JIRA BỔ SUNG (JIRA TASK SPECIFICATIONS)

> **Dự án:** `[KCPM] Kiểm chứng phần mềm - Cứu hộ lũ lụt` (Project Key: **`KCPM`**)  
> **Giai đoạn:** Sprint 5 — Hoàn thiện Độ phủ Kiểm thử (Test Coverage Completion)  
> **Mục tiêu:** Chuyển hóa toàn bộ 12 nhiệm vụ của kế hoạch bổ sung kiểm thử Sprint 5 thành các Task Jira chuẩn hóa, đồng nhất về thuộc tính (Properties), Nhãn (Labels), Phân quyền người nhận (Assignee) và Tiêu chuẩn nghiệm thu (Acceptance Criteria).
> - 📄 Kèm ma trận đối soát: [TEST_MATRIX.md](TEST_MATRIX.md)
> - 📄 Cẩm nang hướng dẫn: [GUIDE_BRUNO.md](guides/GUIDE_BRUNO.md) · [GUIDE_JUNIT.md](guides/GUIDE_JUNIT.md) · [GUIDE_CODECEPTJS.md](guides/GUIDE_CODECEPTJS.md)

---


## 📊 BẢNG TỔNG HỢP 12 TICKET ĐÃ KHỞI TẠO THÀNH CÔNG TRÊN JIRA

| STT | Jira Key | Tên Task (Summary) | Epic Link | Assignee | Priority | Trạng thái |
|:---:|:---|:---|:---:|:---:|:---:|:---:|
| 1 | [**KCPM-106**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-106) | [Sprint 5] [Unit Test] Bổ sung Unit Test Mockito cho Phân hệ Auth, Khóa tài khoản & RBAC | `KCPM-52` (EPIC-01) | Anh | High | `To Do` |
| 2 | [**KCPM-107**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-107) | [Sprint 5] [Unit Test] Viết mới Unit Test cho Module Cấu hình & Dashboard (AdminSystemTest) | `KCPM-52` (EPIC-01) | Anh | Medium | `To Do` |
| 3 | [**KCPM-108**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-108) | [Sprint 5] [E2E Test] Xây dựng Kịch bản CodeceptJS E2E cho Phân hệ Quản trị & Xác thực (auth_admin_test.js) | `KCPM-52` (EPIC-01) | Anh | High | `To Do` |
| 4 | [**KCPM-109**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-109) | [Sprint 5] [Unit Test] Bổ sung Unit Test BVA Biên số người, Ghi chú SOS & Báo cáo kết thúc ca | `KCPM-53` (EPIC-02) | Lâm Khiêm | High | `To Do` |
| 5 | [**KCPM-110**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-110) | [Sprint 5] [E2E Test] Xây dựng Kịch bản CodeceptJS E2E Cổng Người dân & Báo an toàn (citizen_portal_test.js) | `KCPM-53` (EPIC-02) | Lâm Khiêm | Medium | `To Do` |
| 6 | [**KCPM-111**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-111) | [Sprint 5] [Unit Test] Bổ sung Unit Test BVA Bán kính Radar, Mực nước ngập & File đính kèm | `KCPM-54` (EPIC-03) | Phạm Minh Dũng | High | `To Do` |
| 7 | [**KCPM-112**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-112) | [Sprint 5] [E2E Test] Mở rộng Kịch bản CodeceptJS E2E Điều phối: Xác minh, Khẩn cấp & Đổi xe | `KCPM-54` (EPIC-03) | Phạm Minh Dũng | Medium | `To Do` |
| 8 | [**KCPM-113**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-113) | [Sprint 5] [Unit Test] Bổ sung Unit Test BVA Sức chứa phương tiện & Lọc xe sẵn sàng | `KCPM-55` (EPIC-04) | Nguyễn Bảo | High | `To Do` |
| 9 | [**KCPM-114**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-114) | [Sprint 5] [E2E Test] Bổ sung Kịch bản CodeceptJS E2E Máy trạng thái Xe gặp sự cố (Maintenance State) | `KCPM-55` (EPIC-04) | Nguyễn Bảo | Medium | `To Do` |
| 10 | [**KCPM-115**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-115) | [Sprint 5] [Unit Test] Xây dựng bộ Unit Test mới cho Quản lý Nhập kho & Thẻ kho (InventoryServiceTest) | `KCPM-56` (EPIC-05) | Phan Quốc Danh | High | `To Do` |
| 11 | [**KCPM-116**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-116) | [Sprint 5] [E2E Test] Xây dựng Kịch bản CodeceptJS E2E Chuỗi Nhập kho, Xuất kho & Hoàn kho (warehouse_distribution_test.js) | `KCPM-56` (EPIC-05) | Phan Quốc Danh | High | `To Do` |
| 12 | [**KCPM-117**](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-117) | [Sprint 5] [Unit & E2E] Bổ sung kiểm thử FileUpload đa dụng và Báo cáo Xu hướng tồn kho | `KCPM-57` (EPIC-06) | Anh | Medium | `To Do` |

---

## 🛡️ PHÂN HỆ 01: QUẢN TRỊ & XÁC THỰC (EPIC-01: KCPM-52)
* **Assignee phụ trách:** **Dư Nhật Anh** (Lead phân hệ Auth & RBAC)

---

### Task 1.1: [KCPM-106](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-106) — [Sprint 5] [Unit Test] Bổ sung Unit Test Mockito cho Phân hệ Auth, Khóa tài khoản & RBAC
* **Jira Key:** [KCPM-106](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-106)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-52` ([EPIC-01] Phân hệ Quản trị & Xác thực)
* **Assignee:** **Anh** (`nhatanhdu@gmail.com`)
* **Priority:** `High`
* **Labels:** `sprint-5`, `unit-test`, `white-box`, `auth`, `rbac`, `mockito`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Áp dụng kiểm thử hộp trắng (White-box Unit Test với JUnit 5 & Mockito) để kiểm chứng tính toàn vẹn của logic xác thực và phân quyền RBAC.
  - Kiểm thử phân vùng tương đương (EP) trạng thái tài khoản và ma trận quyết định @PreAuthorize.

  📋 2. Chi tiết các Test Case cần bổ sung:
  - Bổ sung vào AuthServiceTest: Test chặn cấp JWT token khi tài khoản ở trạng thái INACTIVE (xác thực đóng triệt để bug KCPM-100).
  - Bổ sung vào UserServiceTest: 
    + testUpdateUserStatus_Success: Chuyển đổi trạng thái giữa ACTIVE và INACTIVE.
    + testUpdateUserRole_Success: Gán role mới cho tài khoản (ROLE_RESCUE_STAFF, ROLE_WAREHOUSE_MANAGER).
    + testUpdateUserRole_WhenRoleInvalid: Bắt lỗi khi gán role ngoài danh mục.
  - Viết mới RoleControllerTest: Kiểm tra kiểm soát truy cập @PreAuthorize("hasRole('ADMIN')").

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: Bộ test AuthServiceTest và UserServiceTest đạt 100% BUILD SUCCESS khi chạy qua `mvn test`.
  - AC 2: Có test case chặn hoàn toàn tài khoản INACTIVE đăng nhập.
  - AC 3: Đảm bảo không gọi repository.save() khi dữ liệu role/user không hợp lệ.

  📦 4. Sản phẩm bàn giao:
  - File mã nguồn: backend/src/test/java/.../services/UserServiceTest.java
  - File mã nguồn: backend/src/test/java/.../services/AuthServiceTest.java
  - File mã nguồn: backend/src/test/java/.../controllers/RoleControllerTest.java
  ```

---

### Task 1.2: [KCPM-107](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-107) — [Sprint 5] [Unit Test] Viết mới Unit Test cho Module Cấu hình & Dashboard (AdminSystemTest)
* **Jira Key:** [KCPM-107](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-107)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-52` ([EPIC-01] Phân hệ Quản trị & Xác thực)
* **Assignee:** **Anh** (`nhatanhdu@gmail.com`)
* **Priority:** `Medium`
* **Labels:** `sprint-5`, `unit-test`, `white-box`, `admin-system`, `junit5`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Viết mới bộ Unit Test độc lập cho AdminSystemController để xóa điểm mù (0 test) của module AdminSystem.
  - Kiểm thử xử lý ngoại lệ JSON sai định dạng (KCPM-38) và xác thực cấu hình.

  📋 2. Chi tiết các Test Case cần viết:
  - TC 1: GET /api/v1/admin/system/config -> Trả về cấu hình hệ thống hợp lệ (200 OK).
  - TC 2: PUT /api/v1/admin/system/config -> Cập nhật cấu hình thành công với payload hợp lệ.
  - TC 3: PUT /api/v1/admin/system/config -> Bắt lỗi BadRequestException (400) khi payload rỗng hoặc JSON sai định dạng.
  - TC 4: GET /api/v1/admin/system/dashboard/{warehouseId} -> Lấy số liệu dashboard tổng quan theo kho thành công.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: Tạo mới thành công file AdminSystemControllerTest.java trong backend/src/test/java/.
  - AC 2: Tối thiểu 4 test cases đạt pass 100% khi chạy `mvn test -Dtest=AdminSystemControllerTest`.

  📦 4. Sản phẩm bàn giao:
  - File mã nguồn: backend/src/test/java/.../controllers/AdminSystemControllerTest.java
  ```

---

### Task 1.3: [KCPM-108](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-108) — [Sprint 5] [E2E Test] Xây dựng Kịch bản CodeceptJS E2E cho Phân hệ Quản trị & Xác thực (auth_admin_test.js)
* **Jira Key:** [KCPM-108](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-108)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-52` ([EPIC-01] Phân hệ Quản trị & Xác thực)
* **Assignee:** **Anh** (`nhatanhdu@gmail.com`)
* **Priority:** `High`
* **Labels:** `sprint-5`, `e2e-test`, `codeceptjs`, `auth`, `rbac-matrix`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Xây dựng kịch bản kiểm thử tự động hóa End-to-End (E2E) bằng CodeceptJS cho luồng Quản trị nhân sự và Phân quyền chéo RBAC.

  📋 2. Chi tiết các Scenario cần viết:
  - Scenario 1 (Đổi mật khẩu): Đăng nhập -> Gửi request POST /change-password với mật khẩu mới hợp lệ -> Đổi thành công.
  - Scenario 2 (Vòng đời User): Admin tạo tài khoản nhân sự mới -> Lấy thông tin -> Đổi role thành ROLE_RESCUE_STAFF -> Khóa tài khoản (status = INACTIVE).
  - Scenario 3 (Chặn tài khoản bị khóa): Thử đăng nhập bằng tài khoản vừa bị khóa -> Kỳ vọng nhận lỗi 400/401.
  - Scenario 4 (Phân quyền chéo RBAC): Dùng Token của Citizen gọi API GET /api/v1/admin/users -> Kỳ vọng nhận đúng mã lỗi HTTP 403 Forbidden.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: Tạo mới file test-automation/auth_admin_test.js.
  - AC 2: Chạy lệnh `npm run test:api` đạt 100% Pass không có lỗi crash.
  - AC 3: Báo cáo HTML tự động sinh ra trong thư mục test-automation/output/.

  📦 4. Sản phẩm bàn giao:
  - Kịch bản test: test-automation/auth_admin_test.js
  ```

---

## 🆘 PHÂN HỆ 02: CỔNG NGƯỜI DÂN & TIẾP NHẬN SOS (EPIC-02: KCPM-53)
* **Assignee phụ trách:** **Lâm Khiêm** (Lead phân hệ Citizen & SOS)

---

### Task 2.1: [KCPM-109](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-109) — [Sprint 5] [Unit Test] Bổ sung Unit Test BVA Biên số người, Ghi chú SOS & Báo cáo kết thúc ca
* **Jira Key:** [KCPM-109](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-109)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-53` ([EPIC-02] Phân hệ Tiếp nhận SOS từ người dân)
* **Assignee:** **Lâm Khiêm**
* **Priority:** `High`
* **Labels:** `sprint-5`, `unit-test`, `white-box`, `bva`, `citizen-sos`, `validation`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Bổ sung Unit Test hộp trắng kiểm tra toàn diện các giá trị biên (BVA) cho DTO RescueRequest và Controller nộp biên bản kết thúc cứu hộ.

  📋 2. Chi tiết các Test Case cần viết:
  - Bổ sung vào RescueRequestValidationTest.java:
    + Test biên số người peopleCount = -1 và 0 -> Bị chặn với ConstraintViolation.
    + Test biên dưới hợp lệ peopleCount = 1 -> Hợp lệ.
    + Test biên trên hợp lệ peopleCount = 50 -> Hợp lệ.
    + Test vượt biên trên peopleCount = 51 -> Bị chặn lỗi.
    + Test biên độ dài ghi chú note = 1000 ký tự -> Hợp lệ; note = 1001 ký tự -> Bị chặn lỗi.
  - Bổ sung vào RescueReportControllerTest.java:
    + Test nộp biên bản cứu nạn với rescuedPeopleCount = 0 (ca chỉ tiếp tế nhu yếu phẩm) -> Trả về 200 OK.
    + Test nộp biên bản với rescuedPeopleCount = 50 (đạt tải trọng tối đa) -> Trả về 200 OK.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: File RescueRequestValidationTest tăng từ 6 lên ít nhất 12 test cases.
  - AC 2: Chạy `mvn test -Dtest=RescueRequestValidationTest,RescueReportControllerTest` pass 100%.

  📦 4. Sản phẩm bàn giao:
  - File mã nguồn: backend/src/test/java/.../dto/RescueRequestValidationTest.java
  - File mã nguồn: backend/src/test/java/.../controllers/RescueReportControllerTest.java
  ```

---

### Task 2.2: [KCPM-110](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-110) — [Sprint 5] [E2E Test] Xây dựng Kịch bản CodeceptJS E2E Cổng Người dân & Báo an toàn (citizen_portal_test.js)
* **Jira Key:** [KCPM-110](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-110)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-53` ([EPIC-02] Phân hệ Tiếp nhận SOS từ người dân)
* **Assignee:** **Lâm Khiêm**
* **Priority:** `Medium`
* **Labels:** `sprint-5`, `e2e-test`, `codeceptjs`, `citizen-sos`, `safety-report`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Tự động hóa kiểm thử luồng người dân kêu cứu và cập nhật trạng thái an toàn sau thiên tai bằng CodeceptJS.

  📋 2. Chi tiết các Scenario cần viết:
  - Scenario 1 (Tạo đơn & Tra cứu): Người dân gửi đơn SOS (POST /api/v1/rescue-requests) -> Nhận trackingId -> Gọi GET /track/{id} kiểm tra trạng thái ban đầu là PENDING.
  - Scenario 2 (Báo an toàn): Người dân gửi báo an toàn (POST /api/v1/safety-reports) với SĐT chuẩn 10 số VN -> Kiểm tra nhận phản hồi 200 OK.
  - Scenario 3 (Hủy đơn khẩn cấp): Người dân hủy yêu cầu cứu hộ khi còn PENDING (PUT /rescue-requests/{id}/cancel) -> Thành công; Thử gọi hủy đơn đã COMPLETED -> Kỳ vọng hệ thống chặn lỗi (400).

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: Tạo mới file test-automation/citizen_portal_test.js.
  - AC 2: Chạy `npm run test:api` tích hợp thành công, không phát sinh lỗi.

  📦 4. Sản phẩm bàn giao:
  - Kịch bản test: test-automation/citizen_portal_test.js
  ```

---

## 🚤 PHÂN HỆ 03: ĐIỀU PHỐI TÁC CHIẾN & BẢN ĐỒ NGUY HIỂM (EPIC-03: KCPM-54)
* **Assignee phụ trách:** **Phạm Minh Dũng** (Lead phân hệ Coordination & Danger)

---

### Task 3.1: [KCPM-111](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-111) — [Sprint 5] [Unit Test] Bổ sung Unit Test BVA Bán kính Radar, Mực nước ngập & File đính kèm
* **Jira Key:** [KCPM-111](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-111)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-54` ([EPIC-03] Phân hệ Điều phối và phân công cứu hộ)
* **Assignee:** **Phạm Minh Dũng**
* **Priority:** `High`
* **Labels:** `sprint-5`, `unit-test`, `white-box`, `bva`, `danger-point`, `attachment`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Kiểm thử hộp trắng các ràng buộc BVA bán kính cảnh báo điểm ngập, mực nước nguy hiểm và xử lý đính kèm hiện trường.

  📋 2. Chi tiết các Test Case cần viết:
  - Bổ sung vào DangerPointServiceTest.java:
    + BVA bán kính quét radiusInMeters = 50m (Biên dưới hợp lệ) -> Pass.
    + BVA bán kính quét radiusInMeters <= 0m hoặc 49m -> Ném BadRequestException (400).
    + BVA mực nước depthInCm = 10cm và 500cm -> Pass; depthInCm <= 0cm -> Ném BadRequestException.
    + Test logic lọc điểm nguy hiểm theo bán kính GPS Radius quanh tọa độ nạn nhân (nghiệm thu dứt điểm KCPM-101).
  - Viết mới AttachmentControllerTest.java:
    + Test upload tệp đính kèm hiện trường (POST /api/v1/attachments/upload).
    + Test lấy danh sách tệp đính kèm theo requestId (GET /api/v1/attachments/request/{requestId}).

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: DangerPointServiceTest bổ sung tối thiểu 5 test cases BVA.
  - AC 2: Tạo mới AttachmentControllerTest với tối thiểu 3 test cases.
  - AC 3: Chạy `mvn test` pass 100%.

  📦 4. Sản phẩm bàn giao:
  - File mã nguồn: backend/src/test/java/.../services/DangerPointServiceTest.java
  - File mã nguồn: backend/src/test/java/.../controllers/AttachmentControllerTest.java
  ```

---

### Task 3.2: [KCPM-112](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-112) — [Sprint 5] [E2E Test] Mở rộng Kịch bản CodeceptJS E2E Điều phối: Xác minh, Khẩn cấp & Đổi xe
* **Jira Key:** [KCPM-112](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-112)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-54` ([EPIC-03] Phân hệ Điều phối và phân công cứu hộ)
* **Assignee:** **Phạm Minh Dũng**
* **Priority:** `Medium`
* **Labels:** `sprint-5`, `e2e-test`, `codeceptjs`, `coordination`, `dispatch`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Mở rộng file test-automation/assignment_dispatch_test.js để bao quát toàn bộ chuỗi tác chiến điều phối liên hoàn.

  📋 2. Chi tiết các Scenario bổ sung:
  - Scenario thêm 1 (Cảnh báo nguy hiểm): Tạo điểm ngập mới POST /api/v1/danger-points -> Xác nhận điểm ngập hiển thị trên radar.
  - Scenario thêm 2 (Xác minh & Gán độ khẩn cấp): Điều phối viên gọi PUT /verify -> Gọi PUT /urgency gán mức độ CRITICAL dựa trên độ sâu nước và số lượng người kẹt.
  - Scenario thêm 3 (Đổi phương tiện nhiệm vụ): Gọi PUT /assignments/{id}/vehicle khi cano ban đầu gặp sự cố -> Xác nhận nhiệm vụ cập nhật xe mới thành công.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: File assignment_dispatch_test.js tăng từ 6 lên 9 scenarios.
  - AC 2: Chạy `npm run test:api` đạt 100% Pass.

  📦 4. Sản phẩm bàn giao:
  - File kịch bản: test-automation/assignment_dispatch_test.js
  ```

---

## 🚚 PHÂN HỆ 04: ĐỘI CƠ ĐỘNG & PHƯƠNG TIỆN CỨU HỘ (EPIC-04: KCPM-55)
* **Assignee phụ trách:** **Nguyễn Bảo** (Lead phân hệ Team & Vehicles)

---

### Task 4.1: [KCPM-113](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-113) — [Sprint 5] [Unit Test] Bổ sung Unit Test BVA Sức chứa phương tiện & Lọc xe sẵn sàng
* **Jira Key:** [KCPM-113](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-113)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-55` ([EPIC-04] Phân hệ Đội cơ động & Phương tiện cứu hộ)
* **Assignee:** **Nguyễn Bảo**
* **Priority:** `High`
* **Labels:** `sprint-5`, `unit-test`, `white-box`, `bva`, `vehicles`, `capacity`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Kiểm thử hộp trắng các giá trị biên của thuộc tính sức chứa phương tiện (capacity) và logic lọc xe khả dụng.

  📋 2. Chi tiết các Test Case cần viết:
  - Bổ sung vào Sprint2ModuleFixesTest.java (hoặc VehiclesServiceTest):
    + Test BVA capacity = 0 hoặc -1 -> Ném BadRequestException (Sức chứa phải lớn hơn hoặc bằng 1).
    + Test BVA capacity = 1 (Biên dưới) và capacity = 20 (Biên trên danh mục) -> Hợp lệ.
    + Test BVA capacity = 25 (Vượt tải trọng quy chuẩn) -> Ném BadRequestException.
    + Test kiểm tra chủng loại phương tiện ngoài enum (CANO, THUYEN, XE_LOI_NUOC) -> Ném lỗi 400.
    + Test hàm lọc phương tiện sẵn sàng GET /api/v1/vehicles/available -> Chỉ trả về các xe có status = AVAILABLE.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: Bổ sung ít nhất 5 test cases BVA cho phương tiện.
  - AC 2: `mvn test -Dtest=Sprint2ModuleFixesTest` pass 100%.

  📦 4. Sản phẩm bàn giao:
  - File mã nguồn: backend/src/test/java/.../services/Sprint2ModuleFixesTest.java
  ```

---

### Task 4.2: [KCPM-114](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-114) — [Sprint 5] [E2E Test] Bổ sung Kịch bản CodeceptJS E2E Máy trạng thái Xe gặp sự cố (Maintenance State)
* **Jira Key:** [KCPM-114](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-114)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-55` ([EPIC-04] Phân hệ Đội cơ động & Phương tiện cứu hộ)
* **Assignee:** **Nguyễn Bảo**
* **Priority:** `Medium`
* **Labels:** `sprint-5`, `e2e-test`, `codeceptjs`, `state-machine`, `vehicles`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Kiểm thử tự động hóa E2E luồng chuyển đổi trạng thái phương tiện theo mô hình State Transition Machine (STM).

  📋 2. Chi tiết các Scenario bổ sung vào team_vehicles_test.js:
  - Scenario 1 (Lọc xe khả dụng): Gọi GET /api/v1/vehicles/available -> Xác minh danh sách chỉ chứa xe AVAILABLE.
  - Scenario 2 (Vòng đời bảo trì xe): 
    + Điều động phương tiện sang BUSY.
    + Phương tiện gặp sự cố thủy lực giữa dòng lũ -> Gọi PUT /vehicles/{id} chuyển sang MAINTENANCE.
    + Thử lập lệnh điều phối xe này -> Xác nhận hệ thống chặn ném lỗi 400.
    + Hoàn tất sửa chữa nghiệm thu -> Chuyển về AVAILABLE thành công.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: File test-automation/team_vehicles_test.js tăng từ 11 lên 13 scenarios.
  - AC 2: Toàn bộ kịch bản chạy pass 100% trên môi trường test.

  📦 4. Sản phẩm bàn giao:
  - File kịch bản: test-automation/team_vehicles_test.js
  ```

---

## 📦 PHÂN HỆ 05: KHO BÃI & CỨU TRỢ HIỆN TRƯỜNG (EPIC-05: KCPM-56)
* **Assignee phụ trách:** **Phan Quốc Danh** (Lead phân hệ Warehouse & Relief)

---

### Task 5.1: [KCPM-115](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-115) — [Sprint 5] [Unit Test] Xây dựng bộ Unit Test mới cho Quản lý Nhập kho & Thẻ kho (InventoryServiceTest)
* **Jira Key:** [KCPM-115](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-115)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-56` ([EPIC-05] Phân hệ Quản lý Kho bãi & Hàng cứu trợ)
* **Assignee:** **Phan Quốc Danh**
* **Priority:** `High`
* **Labels:** `sprint-5`, `unit-test`, `white-box`, `bva`, `inventory`, `warehouse`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Xây dựng mới hoàn toàn bộ Unit Test kiểm thử hộp trắng cho InventoryService nhằm xóa điểm mù của nghiệp vụ Nhập kho nhu yếu phẩm.

  📋 2. Chi tiết các Test Case cần viết:
  - Tạo mới InventoryServiceTest.java:
    + Test BVA số lượng quantity <= 0 hoặc âm -> Ném BadRequestException (400).
    + Test BVA số lượng hợp lệ quantity = 1 (Biên Min) và 10000 (Biên Max) -> Nhập kho thành công, cộng dồn tồn kho.
    + Test BVA số lượng vượt ngưỡng quantity = 10001 -> Ném BadRequestException.
    + Test ràng buộc thời gian: expiryDate <= importDate -> Từ chối nhập hàng hết hạn.
    + Test tra cứu thẻ kho thực tế: GET /warehouse/{id} -> Tính đúng tồn khả dụng.
    + Test cảnh báo tồn kho cạn kiệt: GET /warehouse/{id}/low-stock -> Trả về danh sách mặt hàng dưới ngưỡng an toàn.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: Tạo mới thành công file backend/src/test/java/.../services/InventoryServiceTest.java.
  - AC 2: Tối thiểu 6 test cases đạt pass 100% khi chạy `mvn test -Dtest=InventoryServiceTest`.

  📦 4. Sản phẩm bàn giao:
  - File mã nguồn: backend/src/test/java/.../services/InventoryServiceTest.java
  ```

---

### Task 5.2: [KCPM-116](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-116) — [Sprint 5] [E2E Test] Xây dựng Kịch bản CodeceptJS E2E Chuỗi Nhập kho, Xuất kho & Hoàn kho (warehouse_distribution_test.js)
* **Jira Key:** [KCPM-116](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-116)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-56` ([EPIC-05] Phân hệ Quản lý Kho bãi & Hàng cứu trợ)
* **Assignee:** **Phan Quốc Danh**
* **Priority:** `High`
* **Labels:** `sprint-5`, `e2e-test`, `codeceptjs`, `inventory`, `distribution`, `rollback`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Tự động hóa kiểm thử End-to-End chuỗi cung ứng vật phẩm cứu trợ: Từ thành lập kho dã chiến -> Nhập hàng -> Xuất phát cứu trợ -> Chặn âm kho -> Hủy xuất hoàn kho tự động.

  📋 2. Chi tiết các Scenario cần viết trong warehouse_distribution_test.js:
  - Scenario 1: Tạo kho hàng dã chiến POST /api/v1/warehouses và Thêm mặt hàng nhu yếu phẩm POST /api/v1/relief-items.
  - Scenario 2: Nhập kho 500 thùng mì tôm POST /api/v1/inventory/import -> Kiểm tra thẻ kho hiển thị tồn khả dụng đúng 500.
  - Scenario 3 (Chặn âm kho): Thử xuất kho 600 thùng POST /api/v1/distributions -> Kỳ vọng hệ thống chặn lỗi 400 Bad Request.
  - Scenario 4: Xuất kho hợp lệ 200 thùng -> Tồn kho giảm còn 300 thùng.
  - Scenario 5 (Rollback hoàn kho): Hủy phiếu xuất vừa tạo POST /api/v1/distributions/{id}/cancel -> Kiểm tra số lượng tự động hoàn lại thành 500 thùng (Nghiệm thu bug KCPM-103).

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: Tạo mới file test-automation/warehouse_distribution_test.js với 5 scenarios.
  - AC 2: Chạy `npm run test:api` đạt 100% Pass.

  📦 4. Sản phẩm bàn giao:
  - Kịch bản test: test-automation/warehouse_distribution_test.js
  ```

---

## 📢 PHÂN HỆ DÙNG CHUNG: BÁO CÁO & TỰ ĐỘNG HÓA HẠ TẦNG (EPIC-06: KCPM-57)
* **Assignee phụ trách:** **Dư Nhật Anh** (Lead hạ tầng kiểm thử & CI/CD)

---

### Task 6.1: [KCPM-117](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-117) — [Sprint 5] [Unit & E2E] Bổ sung kiểm thử FileUpload đa dụng và Báo cáo Xu hướng tồn kho
* **Jira Key:** [KCPM-117](https://nhatanhdu-1764828342927.atlassian.net/browse/KCPM-117)
* **Status:** `To Do` (Đã khởi tạo trên Jira)
* **Issue Type:** `Task`
* **Epic Link:** `KCPM-57` ([EPIC-06] Hạ tầng Kiểm thử & Tự động hóa CI/CD)
* **Assignee:** **Anh** (`nhatanhdu@gmail.com`)
* **Priority:** `Medium`
* **Labels:** `sprint-5`, `unit-test`, `e2e-test`, `report`, `file-upload`
* **Mô tả chi tiết (Description):**
  ```markdown
  🎯 1. Mục tiêu & Kỹ thuật áp dụng:
  - Bổ sung Unit Test và kịch bản E2E cho các API hỗ trợ chung của hệ thống (FileController & ReportController).

  📋 2. Chi tiết các Test Case cần viết:
  - Viết mới FileControllerTest.java: Kiểm thử upload tập tin đa dụng POST /api/v1/files/upload, bắt lỗi file rỗng và lưu trữ thành công.
  - Mở rộng upload_notification_report_test.js trong test-automation/:
    + Scenario gọi API lấy báo cáo xu hướng kho GET /reports/warehouse-trend.
    + Scenario gọi API lấy danh mục hàng khả dụng GET /reports/available-items.

  ✅ 3. Tiêu chuẩn nghiệm thu (Acceptance Criteria):
  - AC 1: FileControllerTest pass 100% khi chạy `mvn test`.
  - AC 2: File upload_notification_report_test.js mở rộng pass 100%.

  📦 4. Sản phẩm bàn giao:
  - File mã nguồn: backend/src/test/java/.../controllers/FileControllerTest.java
  - File kịch bản: test-automation/upload_notification_report_test.js
  ```
