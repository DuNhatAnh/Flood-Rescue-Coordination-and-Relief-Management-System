/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-06] BÁO CÁO PHÂN TÍCH & HẠ TẦNG CHUNG
 * THÀNH VIÊN PHỤ TRÁCH: DƯ NHẬT ANH (Lead Reporting & Common Infra)
 * JIRA TICKETS: KCPM-8, KCPM-45, KCPM-117
 * ==============================================================================
 */

const { assert, createUser } = require('../support/api');

Feature('[EPIC-06] [Dư Nhật Anh] Báo Cáo Phân Tích & Hạ Tầng Chung (Reports & Files)');

// ==================== NHÓM 1: FILE UPLOAD (CHẶN HTTP 500 & VALIDATION) ====================

Scenario('[KCPM-117] [E2E-06-01] [NEGATIVE] Upload ảnh không có file hoặc file rỗng [POST /api/upload/image]', async ({ I }) => {
  const res = await I.sendPostRequest('/api/upload/image', {});
  I.seeResponseCodeIs(400);
});

// ==================== NHÓM 2: THÔNG BÁO KHẨN CẤP (NOTIFICATIONS) ====================

Scenario('[KCPM-117] [E2E-06-02] [NEGATIVE] Gửi thông báo thiếu người nhận (userId) [POST /api/v1/notifications]', async ({ I }) => {
  const payload = {
    title: 'Cảnh báo lũ lụt cấp 3',
    content: 'Mực nước sông Kiến Giang dâng cao trên báo động 3'
  };
  const res = await I.sendPostRequest('/api/v1/notifications', payload);
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-117] [E2E-06-03] [NEGATIVE] Gửi thông báo thiếu tiêu đề (title) [POST /api/v1/notifications]', async ({ I }) => {
  const payload = {
    userId: 'user-flood-001',
    content: 'Nội dung thông báo khẩn cấp'
  };
  const res = await I.sendPostRequest('/api/v1/notifications', payload);
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-117] [E2E-06-04] [NEGATIVE] Lấy số thông báo chưa đọc không truyền userId [GET /api/v1/notifications/unread-count]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/notifications/unread-count');
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-117] [E2E-06-05] [POSITIVE] Gửi thông báo khẩn cấp hợp lệ -> Số thông báo chưa đọc của người nhận tăng 1 [POST /api/v1/notifications]', async ({ I }) => {
  const receiver = await createUser(I, 'USER', 'Notify'); // Người nhận là user thật, không dùng ID giả
  const before = await I.sendGetRequest(`/api/v1/notifications/unread-count?userId=${receiver.id}`);
  assert.strictEqual(before.status, 200);

  const res = await I.sendPostRequest('/api/v1/notifications', {
    userId: receiver.id,
    title: 'Thông báo điều động cano cứu nạn',
    content: 'Đội số 1 đã xuất phát đi Lệ Thủy',
  });
  I.seeResponseCodeIs(200);

  const after = await I.sendGetRequest(`/api/v1/notifications/unread-count?userId=${receiver.id}`);
  assert.strictEqual(Number(after.data.data), Number(before.data.data) + 1, 'Số thông báo chưa đọc phải tăng thêm 1');
});

// ==================== NHÓM 3: CHẶN LỌC BÁO CÁO KHI NGÀY BẮT ĐẦU > NGÀY KẾT THÚC ====================

Scenario('[KCPM-117] [E2E-06-06] [NEGATIVE] Lọc Safety Report khi startDate > endDate [GET /api/v1/safety-reports]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/safety-reports?startDate=2026-10-25&endDate=2026-10-10');
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-117] [E2E-06-07] [NEGATIVE] Lọc Report cứu hộ khi startDate > endDate [GET /api/v1/reports/rescue-history]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/reports/rescue-history?startDate=2026-10-25&endDate=2026-10-10');
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-117] [E2E-06-08] [NEGATIVE] Lọc Report xuất nhập kho khi startDate > endDate [GET /api/v1/reports/warehouse-history]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/reports/warehouse-history?startDate=2026-10-25&endDate=2026-10-10');
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-117] [E2E-06-09] [POSITIVE] Lọc Safety Report với khoảng ngày hợp lệ [GET /api/v1/safety-reports]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/safety-reports?startDate=2026-10-01&endDate=2026-10-20');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

// ==================== NHÓM 4: BÁO CÁO XU HƯỚNG TỒN KHO & DANH MỤC HÀNG KHẢ DỤNG ====================

Scenario('[KCPM-117] [E2E-06-10] [POSITIVE] Lấy báo cáo phân tích xu hướng tồn kho nhu yếu phẩm [GET /api/v1/reports/warehouse-trend]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/reports/warehouse-trend');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-117] [E2E-06-11] [POSITIVE] Lấy danh mục hàng cứu trợ sẵn sàng cấp phát [GET /api/v1/reports/available-items]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/reports/available-items');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});
