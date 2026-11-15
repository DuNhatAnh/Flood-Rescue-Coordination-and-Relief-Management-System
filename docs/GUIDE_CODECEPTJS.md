# 📕 QUY CHUẨN ĐỒNG BỘ KIỂM THỬ TỰ ĐỘNG HÓA E2E CODECEPTJS (AUTOMATION STANDARD)

> **Dự án:** `[KCPM] Kiểm chứng phần mềm - Hệ thống Cứu hộ Lũ lụt`  
> **Framework:** CodeceptJS (REST API Helper) + Mochawesome HTML Reporter  
> **Mục tiêu:** Đồng bộ 100% cách đặt tên, phương pháp viết kiểm thử, cấu trúc kịch bản và giao diện Báo cáo HTML xuất ra cho cả 5 thành viên.

---

## 📁 1. MA TRẬN PHÂN CÔNG FILE E2E THEO THÀNH VIÊN & EPIC

Toàn bộ kịch bản kiểm thử E2E được lưu tại thư mục `test-automation/`. Mỗi thành viên phụ trách đúng file tương ứng với Epic của mình:

| Epic Link | Thành viên phụ trách | Thư mục & File kịch bản | Tên Feature hiển thị trên Báo cáo HTML |
|:---:|:---|:---|:---|
| **EPIC-01** | **Dư Nhật Anh** | `epic-01-auth/auth_admin_test.js` | `[EPIC-01] [Dư Nhật Anh] Quản Trị & Xác Thực (Auth, Users & RBAC Matrix)` |
| **EPIC-02** | **Lâm Khiêm** | `epic-02-citizen/citizen_portal_test.js` | `[EPIC-02] [Lâm Khiêm] Cổng Người Dân & Tiếp Nhận SOS (Rescue Requests & Safety Reports)` |
| **EPIC-03** | **Phạm Minh Dũng** | `epic-03-coordination/assignment_dispatch_test.js` | `[EPIC-03] [Phạm Minh Dũng] Điều Phối Tác Chiến & Bản Đồ Nguy Hiểm (Coordination & Radar)` |
| **EPIC-04** | **Nguyễn Bảo** | `epic-04-vehicles/team_vehicles_test.js` | `[EPIC-04] [Nguyễn Bảo] Đội Cơ Động & Phương Tiện Cứu Hộ (Teams, Vehicles & Maintenance)` |
| **EPIC-05** | **Phan Quốc Danh** | `epic-05-warehouse/warehouse_distribution_test.js` | `[EPIC-05] [Phan Quốc Danh] Quản Lý Kho Bãi & Cứu Trợ Hiện Trường (Warehouse & Inventory)` |
| **EPIC-06** | **Dư Nhật Anh** | `epic-06-reports/upload_notification_report_test.js` | `[EPIC-06] [Dư Nhật Anh] Báo Cáo Phân Tích & Hạ Tầng Chung (Reports & Files)` |

---

## 🏷️ 2. QUY CHUẨN ĐẶT TÊN ĐỒNG BỘ (NAMING CONVENTION)

### 2.1. Cấu trúc Block thông tin đầu file (File Header):
Mỗi file `.js` bắt buộc phải có phần header đồng bộ sau:
```javascript
/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-XX] <TÊN PHÂN HỆ>
 * THÀNH VIÊN PHỤ TRÁCH: <HỌ VÀ TÊN> (<Vai trò phụ trách>)
 * JIRA TICKETS: <Danh sách mã Jira Task / Bug liên quan>
 * ==============================================================================
 */
Feature('[EPIC-XX] [<Tên Thành Viên>] <Tên Phân Hệ Nghiệp Vụ>');
```

### 2.2. Cấu trúc tên Scenario (Test Case):
```
Scenario('[<MÃ_JIRA>] [E2E-<EPIC>-<STT>] [<TYPE>] <Hành động kiểm thử> [<HTTP_METHOD> <ENDPOINT>]', async ({ I }) => { ... });
```
* **`<MÃ_JIRA>`**: Mã Task Jira thực hiện (Ví dụ: `KCPM-108`, `KCPM-110`, `KCPM-112`, `KCPM-114`, `KCPM-116`, `KCPM-117`).
* **`<EPIC>`**: Mã phân hệ 2 chữ số (`01`, `02`, `03`, `04`, `05`, `06`).
* **`<STT>`**: Số thứ tự test case 2 chữ số (`01`, `02`, `03`...).
* **`<TYPE>`**: Phân loại tính chất kiểm thử:
  * `[POSITIVE]`: Luồng thành công bình thường (HTTP 200, 201).
  * `[NEGATIVE]`: Luồng kiểm tra bắt lỗi, bảo vệ biên BVA/EP (HTTP 400, 401, 403, 404).
  * `[WORKFLOW]`: Luồng liên hoàn chuyển trạng thái (Ví dụ: Tạo đơn -> Xác minh -> Điều phối -> Hoàn thành).
* **`[<HTTP_METHOD> <ENDPOINT>]`**: Phương thức và đường dẫn API (Ví dụ: `[POST /api/v1/rescue-requests]`).

* **Ví dụ mẫu chuẩn hiển thị trên Báo cáo HTML:**
  * `Scenario('[KCPM-108] [E2E-01-01] [POSITIVE] Đăng nhập Admin và cấp mã xác thực JWT Token [POST /login]', ...)`
  * `Scenario('[KCPM-108] [E2E-01-04] [NEGATIVE] Chặn đổi mật khẩu khi độ dài dưới 6 ký tự (BVA Min=6) [POST /change-password]', ...)`
  * `Scenario('[KCPM-116] [E2E-05-05] [WORKFLOW] Hủy phiếu xuất cứu trợ và tự động hoàn trả tồn kho (Rollback) [POST /api/v1/distributions/{id}/cancel]', ...)`

---

## 🎯 3. PHƯƠNG PHÁP & CÁCH VIẾT TEST ĐỒNG NHẤT (TESTING METHODOLOGY)

Tuân thủ nguyên tắc **AAA (Arrange - Act - Assert)** trong từng Scenario:

```javascript
Scenario('[E2E-05-02] [POSITIVE] Nhập kho 500 thùng mì tôm và tăng tồn kho khả dụng [POST /api/v1/inventory/import]', async ({ I }) => {
  // 1. Arrange (Chuẩn bị payload / điều kiện test)
  const payload = {
    warehouseId: createdWarehouseId || 'WH-01',
    itemId: 'ITEM-MI-TOM',
    quantity: 500,
    importDate: '2026-11-15'
  };

  // 2. Act (Gửi request qua I helper)
  const res = await I.sendPostRequest('/api/v1/inventory/import', payload);

  // 3. Assert (Kiểm chứng nghiêm ngặt, KHÔNG dùng console.log bừa bãi)
  I.seeResponseCodeIs(200);                        // Bắt buộc: Kiểm tra HTTP Code
  I.seeResponseContainsKeys(['code', 'message']);   // Bắt buộc: Kiểm tra cấu trúc Response
});
```

### 🚫 Các điều CẤM khi viết kịch bản:
1. ❌ **Không dùng `console.log()` tràn lan:** Làm rác màn hình console và làm vỡ cấu trúc hiển thị trên Báo cáo HTML.
2. ❌ **Không bỏ sót bước Assert:** Gửi request mà không gọi `I.seeResponseCodeIs(...)` thì test case đó không có giá trị kiểm thử.
3. ❌ **Không hardcode ID tạo mới khi test liên hoàn:** Phải lưu `createdId = res.data.data.id` từ bước POST để truyền vào các bước PUT / DELETE sau.

---

## 📊 4. ĐỒNG BỘ GIAO DIỆN BÁO CÁO HTML (MOCHAWESOME REPORT)

File cấu hình `test-automation/codecept.conf.js` đã được chuẩn hóa với các thông số hiển thị chuyên nghiệp:
* **reportTitle:** `[KCPM] BÁO CÁO KIỂM THỬ TỰ ĐỘNG HÓA E2E API - HỆ THỐNG CỨU HỘ LŨ LỤT`
* **reportPageTitle:** `KCPM - Báo Cáo Kiểm Thử Tự Động Hóa E2E API`
* **charts: true:** Tự động vẽ Biểu đồ tròn (Pie Chart) hiển thị tỷ lệ Pass / Fail / Pending trực quan.
* **code: true:** Cho phép click mở rộng để xem trực tiếp mã nguồn kiểm thử ngay trên giao diện web.

---

## ⚡ 5. CÁC LỆNH CHẠY KIỂM THỬ TRONG TERMINAL

Di chuyển vào thư mục `test-automation`:
```bash
cd test-automation
```

### Chạy kiểm thử theo từng thành viên / Epic:
* **Dư Nhật Anh (Epic 01):** `npm run test:epic01`
* **Lâm Khiêm (Epic 02):** `npm run test:epic02`
* **Phạm Minh Dũng (Epic 03):** `npm run test:epic03`
* **Nguyễn Bảo (Epic 04):** `npm run test:epic04`
* **Phan Quốc Danh (Epic 05):** `npm run test:epic05`
* **Dư Nhật Anh (Epic 06):** `npm run test:epic06`

### Chạy toàn bộ hệ thống & Xuất Báo cáo HTML đồng bộ:
```bash
# 1. Chạy tất cả kịch bản và xuất dữ liệu báo cáo
npm run test:report

# 2. Sinh giao diện HTML chuẩn đẹp với Biểu đồ Pie Chart
npm run report:generate
```

👉 File Báo cáo HTML hoàn chỉnh mở tại:  
`test-automation/output/codeceptjs-report.html`
