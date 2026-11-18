/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-03] ĐIỀU PHỐI TÁC CHIẾN & PHÂN CÔNG CỨU HỘ
 * THÀNH VIÊN PHỤ TRÁCH: PHẠM MINH DŨNG (Lead Coordination & Dispatch)
 * JIRA TICKETS: KCPM-40, KCPM-61, KCPM-76, KCPM-93, KCPM-95, KCPM-101, KCPM-112
 * CHẠY TRÊN BACKEND THẬT: mỗi lần chạy tự tạo đơn SOS, đội cứu hộ và phương tiện mới,
 * không dùng ID giả và không chiếm dụng đội/xe có sẵn trong dữ liệu mẫu.
 * ==============================================================================
 */
const { assert, admin, createUser, createRescueRequest, createVehicle } = require('../support/api');

Feature('[EPIC-03] [Phạm Minh Dũng] Điều Phối Tác Chiến & Bản Đồ Nguy Hiểm (Coordination & Radar)');

let createdAssignmentId = null;
let assignedTeamId = null;
let createdDangerPointId = null;

// ==================== NHÓM 1: ĐIỀU PHỐI & PHÂN CÔNG TÁC CHIẾN (ASSIGNMENTS) ====================

Scenario('[KCPM-112] [E2E-03-01] [POSITIVE] Lấy danh sách toàn bộ các nhiệm vụ phân công [GET /api/v1/assignments/all]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/assignments/all');
  I.seeResponseCodeIs(200);
  assert.ok(Array.isArray(res.data.data), 'data phải là danh sách nhiệm vụ');
});

Scenario('[KCPM-112] [E2E-03-02] [WORKFLOW] Tạo phân công nhiệm vụ cứu nạn mới -> Đơn SOS chuyển ASSIGNED, đội chuyển BUSY [POST /api/v1/assignments]', async ({ I }) => {
  const { id: adminId } = await admin(I);
  const sos = await createRescueRequest(I);
  const staff = await createUser(I, 'RESCUE_STAFF', 'Dispatch'); // Backend tự tạo đội AVAILABLE cho nhân viên cứu hộ
  const vehicle = await createVehicle(I);
  assignedTeamId = staff.teamId;

  const res = await I.sendPostRequest('/api/v1/assignments', {
    requestId: sos.id,
    teamId: assignedTeamId,
    vehicleIds: [vehicle.id],
    assignedBy: adminId,
    note: 'Phân công E2E',
  });
  I.seeResponseCodeIs(200);
  createdAssignmentId = res.data.data.id;
  assert.strictEqual(res.data.data.status, 'ASSIGNED');

  const sosAfter = await I.sendGetRequest(`/api/v1/rescue-requests/${sos.id}`);
  assert.strictEqual(sosAfter.data.data.status, 'ASSIGNED', 'Đơn SOS phải chuyển sang ASSIGNED');
  const teamAfter = await I.sendGetRequest(`/api/v1/teams/${assignedTeamId}`);
  assert.strictEqual(teamAfter.data.data.status, 'BUSY', 'Đội được phân công phải chuyển sang BUSY');
});

Scenario('[KCPM-112] [E2E-03-03] [POSITIVE] Lấy nhiệm vụ theo đội cứu hộ vừa được phân công [GET /api/v1/assignments/my-tasks?teamId=...]', async ({ I }) => {
  assert.ok(assignedTeamId, 'Cần chạy E2E-03-02 trước');
  const res = await I.sendGetRequest(`/api/v1/assignments/my-tasks?teamId=${assignedTeamId}`);
  I.seeResponseCodeIs(200);
  assert.ok(Array.isArray(res.data.data) && res.data.data.length >= 1, 'Đội phải có ít nhất 1 nhiệm vụ');
});

Scenario('[KCPM-112] [E2E-03-04] [POSITIVE] Điều phối xe khẩn cấp cho đơn SOS [POST /api/v1/assignments/dispatch]', async ({ I }) => {
  const sos = await createRescueRequest(I);
  const vehicle = await createVehicle(I);

  const res = await I.sendPostRequest('/api/v1/assignments/dispatch', { requestId: sos.id, vehicleIds: [vehicle.id] });
  I.seeResponseCodeIs(200);
  assert.ok(res.data.assignmentId, 'Phải trả về mã phân công');
  assert.deepStrictEqual(res.data.vehicleIds, [vehicle.id]);

  const available = await I.sendGetRequest('/api/v1/vehicles/available');
  assert.ok(!available.data.data.some(v => v.id === vehicle.id), 'Xe đã điều phối không được nằm trong danh sách sẵn sàng');
});

Scenario('[KCPM-112] [E2E-03-05] [NEGATIVE] Đổi xe truyền tham số sai kiểu dữ liệu (String thay vì Array) [PUT /api/v1/assignments/{id}/vehicle]', async ({ I }) => {
  assert.ok(createdAssignmentId, 'Cần chạy E2E-03-02 trước');
  const res = await I.sendPutRequest(`/api/v1/assignments/${createdAssignmentId}/vehicle`, {
    newVehicleIds: 'veh-cano-invalid-string',
    reason: 'Đổi xe khẩn cấp',
  });
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-112] [E2E-03-06] [WORKFLOW] Cập nhật trạng thái nhiệm vụ tác chiến sang IN_PROGRESS [PUT /api/v1/assignments/{id}/status]', async ({ I }) => {
  assert.ok(createdAssignmentId, 'Cần chạy E2E-03-02 trước');
  const { id: adminId } = await admin(I);
  const res = await I.sendPutRequest(`/api/v1/assignments/${createdAssignmentId}/status`, {
    status: 'IN_PROGRESS',
    userId: adminId,
    note: 'Đang tiếp cận vùng cô lập Lệ Thủy',
  });
  I.seeResponseCodeIs(200);

  const all = await I.sendGetRequest('/api/v1/assignments/all');
  const task = all.data.data.find(a => (a.id || a.assignmentId) === createdAssignmentId);
  assert.ok(task, 'Nhiệm vụ vừa tạo phải có trong danh sách');
  assert.strictEqual(task.status, 'IN_PROGRESS');
});

// ==================== NHÓM 2: RADAR ĐIỂM NGUY HIỂM & XÁC MINH (DANGER POINTS & VERIFY) ====================

Scenario('[KCPM-112] [E2E-03-07] [POSITIVE] Admin tạo điểm cảnh báo ngập lụt trên radar [POST /api/v1/danger-points]', async ({ I }) => {
  const { headers } = await admin(I);
  const res = await I.sendPostRequest('/api/v1/danger-points', {
    name: 'Vùng nước xiết cầu Kiến Giang (E2E)',
    address: 'Cầu Kiến Giang, Lệ Thủy, Quảng Bình',
    latitude: 17.2185,
    longitude: 106.7842,
    depth: 1.5,
  }, headers);
  I.seeResponseCodeIs(200);
  createdDangerPointId = res.data.data.id;
  assert.ok(createdDangerPointId);
});

Scenario('[KCPM-112] [E2E-03-08] [POSITIVE] Lấy danh sách điểm ngập trên radar có chứa điểm vừa tạo, sau đó xóa dọn dữ liệu [GET & DELETE /api/v1/danger-points]', async ({ I }) => {
  assert.ok(createdDangerPointId, 'Cần chạy E2E-03-07 trước');
  const res = await I.sendGetRequest('/api/v1/danger-points');
  I.seeResponseCodeIs(200);
  assert.ok(res.data.data.some(p => p.id === createdDangerPointId), 'Điểm vừa tạo phải xuất hiện trên radar');

  const { headers } = await admin(I);
  const del = await I.sendDeleteRequest(`/api/v1/danger-points/${createdDangerPointId}`, headers);
  assert.strictEqual(del.status, 200, 'Dọn dữ liệu: xóa điểm nguy hiểm vừa tạo');
});

Scenario('[KCPM-112] [E2E-03-09] [WORKFLOW] Điều phối viên gán mức độ khẩn cấp CRITICAL cho đơn SOS [PUT /api/v1/rescue-requests/{id}/urgency]', async ({ I }) => {
  const sos = await createRescueRequest(I, { urgencyLevel: 'MEDIUM' });
  // API nhận body là chuỗi thuần (@RequestBody String) nên gửi text/plain
  const res = await I.sendPutRequest(`/api/v1/rescue-requests/${sos.id}/urgency`, 'CRITICAL', { 'Content-Type': 'text/plain' });
  I.seeResponseCodeIs(200);

  const after = await I.sendGetRequest(`/api/v1/rescue-requests/${sos.id}`);
  assert.strictEqual(after.data.data.urgencyLevel, 'CRITICAL', 'Mức độ khẩn cấp phải được cập nhật');
});
