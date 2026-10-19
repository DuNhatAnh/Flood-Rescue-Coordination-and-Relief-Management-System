Feature('Kiểm thử API Phân Công Nhiệm Vụ và Điều Phối Xe (6 API)');

let createdAssignmentId = null;
const testUserId = 'test-admin-uid-001';

Scenario('TC-ASN-01: Lấy danh sách toàn bộ các nhiệm vụ phân công [GET /api/v1/assignments/all]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/assignments/all');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('TC-ASN-02: Lấy nhiệm vụ theo đội [GET /api/v1/assignments/my-tasks?teamId=...]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/assignments/my-tasks?teamId=team-01');
  I.seeResponseCodeIs(200);
});

Scenario('TC-ASN-03: Tạo phân công nhiệm vụ cứu nạn mới [POST /api/v1/assignments]', async ({ I }) => {
  const payload = {
    requestId: 'REQ-DEMO-01',
    teamId: 'team-01',
    vehicleIds: ['veh-cano-01']
  };
  const res = await I.sendPostRequest('/api/v1/assignments', payload);
  console.log('Assignment create status:', res.status);
  if (res.data && res.data.data) {
    createdAssignmentId = res.data.data.id;
  }
});

Scenario('TC-ASN-04: Điều phối xe khẩn cấp [POST /api/v1/assignments/dispatch]', async ({ I }) => {
  const payload = {
    requestId: 'REQ-DEMO-02',
    teamId: 'team-02',
    vehicleIds: ['veh-cano-02']
  };
  const res = await I.sendPostRequest('/api/v1/assignments/dispatch', payload);
  console.log('Dispatch status:', res.status);
});

Scenario('TC-ASN-05 [NEGATIVE - BUG 03]: Đổi xe truyền tham số sai kiểu dữ liệu [PUT /api/v1/assignments/{id}/vehicle]', async ({ I }) => {
  // Gửi String thay vì Array để kiểm tra bắt lỗi ép kiểu ClassCastException
  const payload = {
    newVehicleIds: 'veh-cano-invalid-string',
    reason: 'Đổi xe khẩn cấp'
  };
  const targetId = createdAssignmentId || 'dummy-assignment-id';
  const res = await I.sendPutRequest(`/api/v1/assignments/${targetId}/vehicle`, payload);
  console.log('Status code nhận được khi gửi sai mảng:', res.status);
});

Scenario('TC-ASN-06: Cập nhật trạng thái nhiệm vụ [PUT /api/v1/assignments/{id}/status]', async ({ I }) => {
  const targetId = createdAssignmentId || 'dummy-assignment-id';
  const payload = {
    status: 'IN_PROGRESS',
    userId: testUserId,
    note: 'Đang tiếp cận vùng cô lập'
  };
  const res = await I.sendPutRequest(`/api/v1/assignments/${targetId}/status`, payload);
  console.log('Status code cập nhật nhiệm vụ:', res.status);
});
