/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-02] CỔNG NGƯỜI DÂN & TIẾP NHẬN CỨU NẠN SOS
 * THÀNH VIÊN PHỤ TRÁCH: LÂM KHIÊM (Lead Citizen & SOS)
 * JIRA TICKETS: KCPM-5, KCPM-25, KCPM-45, KCPM-64, KCPM-84, KCPM-85, KCPM-91, KCPM-94, KCPM-105, KCPM-110
 * ==============================================================================
 */

Feature('[EPIC-02] [Lâm Khiêm] Cổng Người Dân & Tiếp Nhận SOS (Rescue Requests & Safety Reports)');

let createdRequestId = null;
let trackingCode = null;

// ==================== NHÓM 1: GỬI ĐƠN CỨU NẠN SOS (RESCUE REQUESTS) ====================

Scenario('[KCPM-110] [E2E-02-01] [WORKFLOW] Người dân gửi yêu cầu cứu nạn SOS khẩn cấp [POST /api/v1/rescue-requests]', async ({ I }) => {
  const payload = {
    citizenName: 'Nguyễn Văn An',
    phone: '0912345678',
    latitude: 17.2185,
    longitude: 106.7842,
    address: 'Thôn Thượng Phong, Xã Phong Thủy, Huyện Lệ Thủy',
    peopleCount: 4,
    hasElderly: true,
    hasChildren: false,
    note: 'Nước ngập ngang mái nhà, cần ca nô gấp'
  };
  const res = await I.sendPostRequest('/api/v1/rescue-requests', payload);
  I.seeResponseCodeIs(201);
  I.seeResponseContainsKeys(['code', 'data']);
  if (res.data && res.data.data) {
    createdRequestId = res.data.data.id;
    trackingCode = res.data.data.trackingCode || createdRequestId;
  }
});

Scenario('[KCPM-110] [E2E-02-02] [POSITIVE] Tra cứu tiến độ cứu hộ công dân qua mã Tracking [GET /api/v1/rescue-requests/track/{id}]', async ({ I }) => {
  const targetCode = trackingCode || 'TRACK-DEMO-01';
  const res = await I.sendGetRequest(`/api/v1/rescue-requests/track/${targetCode}`);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-110] [E2E-02-03] [NEGATIVE] Chặn tạo yêu cầu cứu nạn khi số người vượt biên tối đa (BVA > 50) [POST /api/v1/rescue-requests]', async ({ I }) => {
  const payload = {
    citizenName: 'Trần Văn Cường',
    phone: '0988776655',
    latitude: 17.2185,
    longitude: 106.7842,
    peopleCount: 51, // Vượt ngưỡng 50 người
    note: 'Yêu cầu vượt tải trọng'
  };
  const res = await I.sendPostRequest('/api/v1/rescue-requests', payload);
  I.seeResponseCodeIs(400);
});

// ==================== NHÓM 2: BÁO AN TOÀN CÔNG DÂN (SAFETY REPORTS) ====================

Scenario('[KCPM-110] [E2E-02-04] [POSITIVE] Công dân gửi báo an toàn với số điện thoại 10 số chuẩn VN [POST /api/v1/safety-reports]', async ({ I }) => {
  const payload = {
    citizenName: 'Lê Thị Mai',
    citizenPhone: '0905123456',
    currentLocation: 'Khu sơ tán THPT Lệ Thủy',
    status: 'SAFE',
    note: 'Gia đình đã lên thuyền cứu hộ an toàn'
  };
  const res = await I.sendPostRequest('/api/v1/safety-reports', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

Scenario('[KCPM-110] [E2E-02-05] [NEGATIVE] Chặn gửi báo an toàn với số điện thoại không hợp lệ (Chữ cái / Thiếu số) [POST /api/v1/safety-reports]', async ({ I }) => {
  const payload = {
    citizenName: 'Phan Văn Sai',
    citizenPhone: '0905INVALID',
    status: 'SAFE'
  };
  const res = await I.sendPostRequest('/api/v1/safety-reports', payload);
  I.seeResponseCodeIs(400);
});

// ==================== NHÓM 3: HỦY ĐƠN & BÁO CÁO KẾT THÚC ====================

Scenario('[KCPM-110] [E2E-02-06] [WORKFLOW] Hủy yêu cầu cứu nạn khi đang ở trạng thái PENDING [PUT /api/v1/rescue-requests/{id}/cancel]', async ({ I }) => {
  const targetId = createdRequestId || 'dummy-req-id';
  const res = await I.sendPutRequest(`/api/v1/rescue-requests/${targetId}/cancel`, {
    reason: 'Đã được xuồng hàng xóm hỗ trợ sơ tán'
  });
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});
