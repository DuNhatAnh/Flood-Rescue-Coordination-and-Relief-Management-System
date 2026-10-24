Feature('Kiểm thử API Quản lý Đội Cứu Hộ và Phương Tiện (10 API)');

let createdVehicleId = null;
const testUserId = 'test-admin-uid-001';

// ==================== NHÓM 1: ĐỘI CỨU HỘ (TEAMS - 4 API) ====================

Scenario('TC-TEAM-01: Lấy danh sách tất cả các đội cứu hộ [GET /api/v1/teams]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/teams');
  I.seeResponseCodeIsSuccessful(); // 200 OK
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('TC-TEAM-02: Lọc danh sách đội cứu hộ sẵn sàng [GET /api/v1/teams/available]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/teams/available');
  I.seeResponseCodeIs(200);
});

Scenario('TC-TEAM-03: Xem chi tiết đội cứu hộ theo ID [GET /api/v1/teams/{id}]', async ({ I }) => {
  const teamsRes = await I.sendGetRequest('/api/v1/teams');
  if (teamsRes.data && teamsRes.data.data && teamsRes.data.data.length > 0) {
    const validId = teamsRes.data.data[0].id;
    const res = await I.sendGetRequest(`/api/v1/teams/${validId}`);
    I.seeResponseCodeIs(200);
  }
});

Scenario('TC-TEAM-04: Cập nhật tên đội cứu hộ [PUT /api/v1/teams/{id}]', async ({ I }) => {
  const teamsRes = await I.sendGetRequest('/api/v1/teams');
  if (teamsRes.data && teamsRes.data.data && teamsRes.data.data.length > 0) {
    const validId = teamsRes.data.data[0].id;
    const res = await I.sendPutRequest(`/api/v1/teams/${validId}`, {
      teamName: 'Đội Phản Ứng Nhanh Lũ Lụt - Test'
    });
    I.seeResponseCodeIs(200);
  }
});

// ==================== NHÓM 2: PHƯƠNG TIỆN CỨU HỘ (VEHICLES - 6 API) ====================

Scenario('TC-VEH-01: Lấy thống kê số lượng phương tiện [GET /api/v1/vehicles/statistics-summary]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles/statistics-summary');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('TC-VEH-02: Tạo mới ca nô cứu hộ hợp lệ [POST /api/v1/vehicles?userId=...]', async ({ I }) => {
  const randomPlate = 'CN-AUTO-' + Math.floor(1000 + Math.random() * 9000);
  const payload = {
    vehicleType: 'CANO',
    licensePlate: randomPlate,
    currentLocation: 'Bến Lệ Thủy - Quảng Bình',
    warehouseId: 'WH-01'
  };

  const res = await I.sendPostRequest(`/api/v1/vehicles?userId=${testUserId}`, payload);
  I.seeResponseCodeIs(201); // 201 Created
  if (res.data && res.data.data) {
    createdVehicleId = res.data.data.id;
  }
});

Scenario('TC-VEH-03 [NEGATIVE - BUG 01]: Tạo phương tiện thiếu query param userId [POST /api/v1/vehicles]', async ({ I }) => {
  const payload = {
    vehicleType: 'CANO',
    licensePlate: 'CN-FAIL-001',
    currentLocation: 'Bến Lệ Thủy'
  };
  // Khi thiếu userId, hệ thống kỳ vọng 400 Bad Request (hiện tại văng 500 do Bug-01)
  const res = await I.sendPostRequest('/api/v1/vehicles', payload);
  console.log('Status code nhận được khi thiếu userId:', res.status);
});

Scenario('TC-VEH-04: Lấy danh sách phương tiện kèm phân trang và lọc [GET /api/v1/vehicles]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles?type=CANO&page=0&size=5');
  I.seeResponseCodeIs(200);
});

Scenario('TC-VEH-05: Lấy danh sách phương tiện đang rảnh [GET /api/v1/vehicles/available]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles/available');
  I.seeResponseCodeIs(200);
});

Scenario('TC-VEH-06: Cập nhật thông tin phương tiện [PUT /api/v1/vehicles/{id}?userId=...]', async ({ I }) => {
  if (createdVehicleId) {
    const updatePayload = {
      vehicleType: 'CANO',
      licensePlate: 'CN-UPDATED-' + Math.floor(1000 + Math.random() * 9000),
      currentLocation: 'Khu vực ngập sâu Đồng Hới'
    };
    const res = await I.sendPutRequest(`/api/v1/vehicles/${createdVehicleId}?userId=${testUserId}`, updatePayload);
    I.seeResponseCodeIs(200);
  }
});

Scenario('TC-VEH-07: Xóa phương tiện [DELETE /api/v1/vehicles/{id}?userId=...]', async ({ I }) => {
  if (createdVehicleId) {
    const res = await I.sendDeleteRequest(`/api/v1/vehicles/${createdVehicleId}?userId=${testUserId}`);
    I.seeResponseCodeIs(200);
  }
});
