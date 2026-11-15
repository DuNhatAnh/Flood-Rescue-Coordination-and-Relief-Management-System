/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-03] ĐIỀU PHỐI TÁC CHIẾN & PHÂN CÔNG CỨU HỘ
 * THÀNH VIÊN PHỤ TRÁCH: PHẠM MINH DŨNG (Lead Coordination & Dispatch)
 * JIRA TICKETS: KCPM-40, KCPM-61, KCPM-76, KCPM-93, KCPM-95, KCPM-101, KCPM-112
 * ==============================================================================
 */

Feature('[EPIC-03] [Phạm Minh Dũng] Điều Phối Tác Chiến & Bản Đồ Nguy Hiểm (Coordination & Radar)');

let createdAssignmentId = null;
let createdDangerPointId = null;
const testUserId = 'test-admin-uid-001';

// ==================== NHÓM 1: ĐIỀU PHỐI & PHÂN CÔNG TÁC CHIẾN (ASSIGNMENTS) ====================

Scenario('[KCPM-112] [E2E-03-01] [POSITIVE] Lấy danh sách toàn bộ các nhiệm vụ phân công [GET /api/v1/assignments/all]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/assignments/all');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-112] [E2E-03-02] [POSITIVE] Lấy nhiệm vụ theo đội cứu hộ [GET /api/v1/assignments/my-tasks?teamId=...]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/assignments/my-tasks?teamId=team-01');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-112] [E2E-03-03] [WORKFLOW] Tạo phân công nhiệm vụ cứu nạn mới [POST /api/v1/assignments]', async ({ I }) => {
  const payload = {
    requestId: 'REQ-DEMO-01',
    teamId: 'team-01',
    vehicleIds: ['veh-cano-01']
  };
  const res = await I.sendPostRequest('/api/v1/assignments', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
  if (res.data && res.data.data) {
    createdAssignmentId = res.data.data.id;
  }
});

Scenario('[KCPM-112] [E2E-03-04] [POSITIVE] Điều phối xe khẩn cấp cho đơn SOS [POST /api/v1/assignments/dispatch]', async ({ I }) => {
  const payload = {
    requestId: 'REQ-DEMO-02',
    teamId: 'team-02',
    vehicleIds: ['veh-cano-02']
  };
  const res = await I.sendPostRequest('/api/v1/assignments/dispatch', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

Scenario('[KCPM-112] [E2E-03-05] [NEGATIVE] Đổi xe truyền tham số sai kiểu dữ liệu [PUT /api/v1/assignments/{id}/vehicle]', async ({ I }) => {
  // Gửi String thay vì Array để kiểm tra bắt lỗi ép kiểu dữ liệu
  const payload = {
    newVehicleIds: 'veh-cano-invalid-string',
    reason: 'Đổi xe khẩn cấp'
  };
  const targetId = createdAssignmentId || 'dummy-assignment-id';
  const res = await I.sendPutRequest(`/api/v1/assignments/${targetId}/vehicle`, payload);
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-112] [E2E-03-06] [WORKFLOW] Cập nhật trạng thái nhiệm vụ tác chiến [PUT /api/v1/assignments/{id}/status]', async ({ I }) => {
  const targetId = createdAssignmentId || 'dummy-assignment-id';
  const payload = {
    status: 'IN_PROGRESS',
    userId: testUserId,
    note: 'Đang tiếp cận vùng cô lập Lệ Thủy'
  };
  const res = await I.sendPutRequest(`/api/v1/assignments/${targetId}/status`, payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

// ==================== NHÓM 2: RADAR ĐIỂM NGUY HIỂM & XÁC MINH (DANGER POINTS & VERIFY) ====================

Scenario('[KCPM-112] [E2E-03-07] [POSITIVE] Tạo điểm cảnh báo ngập lụt trên radar [POST /api/v1/danger-points]', async ({ I }) => {
  const payload = {
    latitude: 17.2185,
    longitude: 106.7842,
    waterDepthCm: 150,
    flowSpeed: 'FAST',
    dangerLevel: 'CRITICAL',
    description: 'Vùng nước xiết cầu Kiến Giang'
  };
  const res = await I.sendPostRequest('/api/v1/danger-points', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
  if (res.data && res.data.data) {
    createdDangerPointId = res.data.data.id;
  }
});

Scenario('[KCPM-112] [E2E-03-08] [POSITIVE] Quét radar điểm ngập theo bán kính [GET /api/v1/danger-points]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/danger-points?radiusInMeters=1000&latitude=17.2185&longitude=106.7842');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-112] [E2E-03-09] [WORKFLOW] Xác minh đơn cứu hộ và gán mức độ khẩn cấp [PUT /api/v1/rescue-requests/{id}/urgency]', async ({ I }) => {
  const payload = {
    urgencyLevel: 'CRITICAL',
    floodDepthMeters: 2.0,
    numberOfPeople: 5,
    isIsolated: true,
    hasVulnerable: true
  };
  const res = await I.sendPutRequest('/api/v1/rescue-requests/REQ-DEMO-01/urgency', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});
