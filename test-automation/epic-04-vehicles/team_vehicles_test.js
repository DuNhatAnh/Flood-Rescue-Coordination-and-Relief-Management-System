/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-04] ĐỘI CƠ ĐỘNG & PHƯƠNG TIỆN CỨU HỘ
 * THÀNH VIÊN PHỤ TRÁCH: NGUYỄN BẢO (Lead Teams & Vehicles)
 * JIRA TICKETS: KCPM-34, KCPM-35, KCPM-66, KCPM-67, KCPM-96, KCPM-97, KCPM-114
 * CHẠY TRÊN BACKEND THẬT: đội và phương tiện dùng để test đều được tạo mới, không đổi tên/chiếm dụng dữ liệu mẫu.
 * LƯU Ý: Backend hiện CHƯA có API chuyển xe sang MAINTENANCE (VehicleRequest không có trường status),
 *        nên máy trạng thái được kiểm thử qua luồng có thật: AVAILABLE -> điều phối -> BUSY -> chặn điều phối lần 2.
 * ==============================================================================
 */
const { assert, admin, createUser, createRescueRequest, createVehicle, uid } = require('../support/api');

Feature('[EPIC-04] [Nguyễn Bảo] Đội Cơ Động & Phương Tiện Cứu Hộ (Teams, Vehicles & State Machine)');

let createdVehicleId = null;
let ownTeamId = null;

// ==================== NHÓM 1: ĐỘI CỨU HỘ (TEAMS - 4 API) ====================

Scenario('[KCPM-114] [E2E-04-01] [POSITIVE] Lấy danh sách tất cả các đội cứu hộ [GET /api/v1/teams]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/teams');
  I.seeResponseCodeIs(200);
  assert.ok(Array.isArray(res.data.data) && res.data.data.length > 0, 'Phải có ít nhất 1 đội cứu hộ');
});

Scenario('[KCPM-114] [E2E-04-02] [POSITIVE] Lọc danh sách đội cứu hộ sẵn sàng [GET /api/v1/teams/available]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/teams/available');
  I.seeResponseCodeIs(200);
  res.data.data.forEach(t => assert.strictEqual(t.status, 'AVAILABLE', `Đội ${t.teamName} không ở trạng thái AVAILABLE`));
});

Scenario('[KCPM-114] [E2E-04-03] [POSITIVE] Xem chi tiết đội cứu hộ theo ID [GET /api/v1/teams/{id}]', async ({ I }) => {
  const staff = await createUser(I, 'RESCUE_STAFF', 'TeamLead'); // Backend tự tạo đội riêng cho nhân viên cứu hộ
  ownTeamId = staff.teamId;
  const res = await I.sendGetRequest(`/api/v1/teams/${ownTeamId}`);
  I.seeResponseCodeIs(200);
  assert.strictEqual(res.data.data.id, ownTeamId);
  assert.strictEqual(res.data.data.leaderId, staff.id);
});

Scenario('[KCPM-114] [E2E-04-04] [POSITIVE] Cập nhật tên đội cứu hộ [PUT /api/v1/teams/{id}]', async ({ I }) => {
  assert.ok(ownTeamId, 'Cần chạy E2E-04-03 trước');
  const newName = `Đội Phản Ứng Nhanh ${uid('E2E')}`;
  const res = await I.sendPutRequest(`/api/v1/teams/${ownTeamId}`, { teamName: newName });
  I.seeResponseCodeIs(200);
  assert.strictEqual(res.data.data.teamName, newName);
});

// ==================== NHÓM 2: PHƯƠNG TIỆN CỨU HỘ (VEHICLES - 6 API) ====================

Scenario('[KCPM-114] [E2E-04-05] [POSITIVE] Lấy thống kê số lượng phương tiện [GET /api/v1/vehicles/statistics-summary]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles/statistics-summary');
  I.seeResponseCodeIs(200);
  assert.ok(typeof res.data.data.available === 'number', 'Thống kê phải có số lượng xe sẵn sàng');
});

Scenario('[KCPM-114] [E2E-04-06] [WORKFLOW] Tạo mới ca nô cứu hộ hợp lệ [POST /api/v1/vehicles?userId=...]', async ({ I }) => {
  const { id: adminId } = await admin(I);
  const warehouses = await I.sendGetRequest('/api/v1/warehouses');
  assert.ok(warehouses.data.data.length > 0, 'Cần ít nhất 1 kho để biên chế phương tiện');
  const plate = uid('CN').slice(0, 20);
  const res = await I.sendPostRequest(`/api/v1/vehicles?userId=${adminId}`, {
    vehicleType: 'CANO',
    licensePlate: plate,
    currentLocation: 'Bến Lệ Thủy - Quảng Bình',
    warehouseId: warehouses.data.data[0].id, // Xe được biên chế vào kho có sẵn như nghiệp vụ thực tế
  });
  I.seeResponseCodeIs(201);
  createdVehicleId = res.data.data.id;
  assert.strictEqual(res.data.data.licensePlate, plate);
  assert.strictEqual(res.data.data.status, 'AVAILABLE', 'Xe mới tạo phải ở trạng thái AVAILABLE');
});

Scenario('[KCPM-114] [E2E-04-07] [NEGATIVE] Chặn tạo phương tiện thiếu query param userId [POST /api/v1/vehicles]', async ({ I }) => {
  const res = await I.sendPostRequest('/api/v1/vehicles', {
    vehicleType: 'CANO',
    licensePlate: 'CN-FAIL-001',
    currentLocation: 'Bến Lệ Thủy',
  });
  I.seeResponseCodeIs(400);
  assert.match(JSON.stringify(res.data), /userId/);
});

Scenario('[KCPM-114] [E2E-04-08] [POSITIVE] Lấy danh sách phương tiện kèm phân trang và lọc theo loại [GET /api/v1/vehicles]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles?type=CANO&page=0&size=5');
  I.seeResponseCodeIs(200);
  const page = res.data.data;
  assert.ok(page.content.length <= 5, 'Kích thước trang không được vượt quá 5');
  page.content.forEach(v => assert.match(v.vehicleType, /CANO/i));
});

Scenario('[KCPM-114] [E2E-04-09] [POSITIVE] Lấy danh sách phương tiện đang sẵn sàng có chứa xe vừa tạo [GET /api/v1/vehicles/available]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles/available');
  I.seeResponseCodeIs(200);
  res.data.data.forEach(v => assert.strictEqual(v.status.toUpperCase(), 'AVAILABLE'));
  assert.ok(res.data.data.some(v => v.id === createdVehicleId), 'Xe vừa tạo phải nằm trong danh sách sẵn sàng');
});

Scenario('[KCPM-114] [E2E-04-10] [POSITIVE] Cập nhật thông tin phương tiện [PUT /api/v1/vehicles/{id}?userId=...]', async ({ I }) => {
  assert.ok(createdVehicleId, 'Cần chạy E2E-04-06 trước');
  const { id: adminId } = await admin(I);
  const newPlate = uid('UPD').slice(0, 20);
  const warehouses = await I.sendGetRequest('/api/v1/warehouses');
  const res = await I.sendPutRequest(`/api/v1/vehicles/${createdVehicleId}?userId=${adminId}`, {
    vehicleType: 'CANO',
    licensePlate: newPlate,
    currentLocation: 'Khu vực ngập sâu Đồng Hới',
    warehouseId: warehouses.data.data[0].id,
  });
  I.seeResponseCodeIs(200);
  assert.strictEqual(res.data.data.licensePlate, newPlate);
  assert.strictEqual(res.data.data.currentLocation, 'Khu vực ngập sâu Đồng Hới');
});

// ==================== NHÓM 3: MÁY TRẠNG THÁI PHƯƠNG TIỆN (STATE TRANSITION) ====================

Scenario('[KCPM-114] [E2E-04-11] [WORKFLOW] Máy trạng thái xe: AVAILABLE -> điều phối nhận đơn SOS -> BUSY [POST /api/v1/assignments/dispatch]', async ({ I }) => {
  assert.ok(createdVehicleId, 'Cần chạy E2E-04-06 trước');
  const sos = await createRescueRequest(I);
  const res = await I.sendPostRequest('/api/v1/assignments/dispatch', { requestId: sos.id, vehicleIds: [createdVehicleId] });
  I.seeResponseCodeIs(200);

  const busyList = await I.sendGetRequest('/api/v1/vehicles?status=BUSY&size=1000');
  assert.ok(busyList.data.data.content.some(v => v.id === createdVehicleId), 'Xe sau khi điều phối phải chuyển sang BUSY');
});

Scenario('[KCPM-114] [E2E-04-12] [NEGATIVE] Chặn điều phối phương tiện đang BUSY cho đơn SOS khác [POST /api/v1/assignments/dispatch]', async ({ I }) => {
  assert.ok(createdVehicleId, 'Cần chạy E2E-04-11 trước');
  const anotherSos = await createRescueRequest(I);
  const res = await I.sendPostRequest('/api/v1/assignments/dispatch', { requestId: anotherSos.id, vehicleIds: [createdVehicleId] });
  I.seeResponseCodeIs(400);
  assert.match(JSON.stringify(res.data), /đang bận|AVAILABLE/);
});

Scenario('[KCPM-114] [E2E-04-13] [POSITIVE] Xóa phương tiện cứu hộ [DELETE /api/v1/vehicles/{id}?userId=...]', async ({ I }) => {
  const { id: adminId } = await admin(I);
  const vehicle = await createVehicle(I); // Xóa xe riêng, không xóa xe đang gắn với nhiệm vụ ở E2E-04-11
  const res = await I.sendDeleteRequest(`/api/v1/vehicles/${vehicle.id}?userId=${adminId}`);
  I.seeResponseCodeIs(200);

  const available = await I.sendGetRequest('/api/v1/vehicles/available');
  assert.ok(!available.data.data.some(v => v.id === vehicle.id), 'Xe đã xóa không được còn trong danh sách');
});
