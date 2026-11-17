/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-04] ĐỘI CƠ ĐỘNG & PHƯƠNG TIỆN CỨU HỘ
 * THÀNH VIÊN PHỤ TRÁCH: NGUYỄN BẢO (Lead Teams & Vehicles)
 * JIRA TICKETS: KCPM-34, KCPM-35, KCPM-66, KCPM-67, KCPM-96, KCPM-97, KCPM-114
 * ==============================================================================
 */

Feature('[EPIC-04] [Nguyễn Bảo] Đội Cơ Động & Phương Tiện Cứu Hộ (Teams, Vehicles & Maintenance)');

let createdVehicleId = null;
const testUserId = 'test-admin-uid-001';

// ==================== NHÓM 1: ĐỘI CỨU HỘ (TEAMS - 4 API) ====================

Scenario('[KCPM-114] [E2E-04-01] [POSITIVE] Lấy danh sách tất cả các đội cứu hộ [GET /api/v1/teams]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/teams');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-114] [E2E-04-02] [POSITIVE] Lọc danh sách đội cứu hộ sẵn sàng [GET /api/v1/teams/available]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/teams/available');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-114] [E2E-04-03] [POSITIVE] Xem chi tiết đội cứu hộ theo ID [GET /api/v1/teams/{id}]', async ({ I }) => {
  const teamsRes = await I.sendGetRequest('/api/v1/teams');
  if (teamsRes.data && teamsRes.data.data && teamsRes.data.data.length > 0) {
    const validId = teamsRes.data.data[0].id;
    const res = await I.sendGetRequest(`/api/v1/teams/${validId}`);
    I.seeResponseCodeIs(200);
    I.seeResponseContainsKeys(['code', 'data']);
  }
});

Scenario('[KCPM-114] [E2E-04-04] [POSITIVE] Cập nhật thông tin đội cứu hộ [PUT /api/v1/teams/{id}]', async ({ I }) => {
  const teamsRes = await I.sendGetRequest('/api/v1/teams');
  if (teamsRes.data && teamsRes.data.data && teamsRes.data.data.length > 0) {
    const validId = teamsRes.data.data[0].id;
    const res = await I.sendPutRequest(`/api/v1/teams/${validId}`, {
      teamName: 'Đội Phản Ứng Nhanh Lũ Lụt - Chuẩn Hóa'
    });
    I.seeResponseCodeIs(200);
    I.seeResponseContainsKeys(['code']);
  }
});

// ==================== NHÓM 2: PHƯƠNG TIỆN CỨU HỘ (VEHICLES - 6 API) ====================

Scenario('[KCPM-114] [E2E-04-05] [POSITIVE] Lấy thống kê số lượng phương tiện [GET /api/v1/vehicles/statistics-summary]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles/statistics-summary');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-114] [E2E-04-06] [WORKFLOW] Tạo mới ca nô cứu hộ hợp lệ [POST /api/v1/vehicles?userId=...]', async ({ I }) => {
  const randomPlate = 'CN-AUTO-' + Math.floor(1000 + Math.random() * 9000);
  const payload = {
    vehicleType: 'CANO',
    licensePlate: randomPlate,
    currentLocation: 'Bến Lệ Thủy - Quảng Bình',
    warehouseId: 'WH-01'
  };

  const res = await I.sendPostRequest(`/api/v1/vehicles?userId=${testUserId}`, payload);
  I.seeResponseCodeIs(201);
  I.seeResponseContainsKeys(['code', 'data']);
  if (res.data && res.data.data) {
    createdVehicleId = res.data.data.id;
  }
});

Scenario('[KCPM-114] [E2E-04-07] [NEGATIVE] Chặn tạo phương tiện thiếu query param userId [POST /api/v1/vehicles]', async ({ I }) => {
  const payload = {
    vehicleType: 'CANO',
    licensePlate: 'CN-FAIL-001',
    currentLocation: 'Bến Lệ Thủy'
  };
  const res = await I.sendPostRequest('/api/v1/vehicles', payload);
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-114] [E2E-04-08] [POSITIVE] Lấy danh sách phương tiện kèm phân trang và lọc [GET /api/v1/vehicles]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles?type=CANO&page=0&size=5');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});

Scenario('[KCPM-114] [E2E-04-09] [POSITIVE] Lấy danh sách phương tiện đang sẵn sàng [GET /api/v1/vehicles/available]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/vehicles/available');
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
  // Xác minh danh sách chỉ chứa xe có status = AVAILABLE
  if (res.data && res.data.data && Array.isArray(res.data.data)) {
    res.data.data.forEach(v => {
      I.assertDeepEqual(v.status.toUpperCase(), 'AVAILABLE', 'Phương tiện trong danh sách available phải có status = AVAILABLE');
    });
  }
});

Scenario('[KCPM-114] [E2E-04-10] [POSITIVE] Cập nhật thông tin phương tiện [PUT /api/v1/vehicles/{id}?userId=...]', async ({ I }) => {
  if (createdVehicleId) {
    const updatePayload = {
      vehicleType: 'CANO',
      licensePlate: 'CN-UPDATED-' + Math.floor(1000 + Math.random() * 9000),
      currentLocation: 'Khu vực ngập sâu Đồng Hới'
    };
    const res = await I.sendPutRequest(`/api/v1/vehicles/${createdVehicleId}?userId=${testUserId}`, updatePayload);
    I.seeResponseCodeIs(200);
    I.seeResponseContainsKeys(['code']);
  }
});

// ==================== NHÓM 3: MÁY TRẠNG THÁI BẢO TRÌ XE (STATE TRANSITION MACHINE) ====================

Scenario('[KCPM-114] [E2E-04-11] [WORKFLOW] Vòng đời bảo trì xe: BUSY -> Gặp sự cố chuyển sang MAINTENANCE -> Nghiệm thu về AVAILABLE [PUT /api/v1/vehicles/{id}]', async ({ I }) => {
  const targetId = createdVehicleId || 'veh-cano-01';

  // Bước 1: Giả lập điều động phương tiện nhận đơn cứu hộ (chuyển sang BUSY)
  await I.sendPutRequest(`/api/v1/vehicles/${targetId}?userId=${testUserId}`, {
    status: 'BUSY',
    currentLocation: 'Vùng rốn lũ Lệ Thủy'
  });

  // Bước 2: Phương tiện gặp sự cố thủy lực giữa dòng lũ -> Gọi PUT chuyển sang MAINTENANCE
  const resMaint = await I.sendPutRequest(`/api/v1/vehicles/${targetId}?userId=${testUserId}`, {
    status: 'MAINTENANCE',
    reason: 'Sự cố thủy lực do ngập nước sâu và vướng rác lũ',
    currentLocation: 'Xưởng sửa chữa tiền phương'
  });
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);

  // Bước 3: Hoàn tất sửa chữa nghiệm thu an toàn kỹ thuật -> Chuyển về AVAILABLE thành công
  const resAvail = await I.sendPutRequest(`/api/v1/vehicles/${targetId}?userId=${testUserId}`, {
    status: 'AVAILABLE',
    currentLocation: 'Bến Lệ Thủy - Sẵn sàng nhận lệnh'
  });
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

Scenario('[KCPM-114] [E2E-04-12] [NEGATIVE] Chặn điều phối phương tiện đang trong trạng thái MAINTENANCE [POST /api/v1/assignments/dispatch]', async ({ I }) => {
  const targetId = createdVehicleId || 'veh-cano-01';

  // Đảm bảo phương tiện đang ở trạng thái MAINTENANCE
  await I.sendPutRequest(`/api/v1/vehicles/${targetId}?userId=${testUserId}`, {
    status: 'MAINTENANCE',
    reason: 'Đang bảo dưỡng động cơ'
  });

  // Thử lập lệnh điều phối xe này -> Xác nhận hệ thống chặn ném lỗi 400
  const payload = {
    requestId: 'REQ-DEMO-03',
    teamId: 'team-01',
    vehicleIds: [targetId]
  };
  const res = await I.sendPostRequest('/api/v1/assignments/dispatch', payload);
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-114] [E2E-04-13] [POSITIVE] Xóa phương tiện cứu hộ [DELETE /api/v1/vehicles/{id}?userId=...]', async ({ I }) => {
  if (createdVehicleId) {
    const res = await I.sendDeleteRequest(`/api/v1/vehicles/${createdVehicleId}?userId=${testUserId}`);
    I.seeResponseCodeIs(200);
    I.seeResponseContainsKeys(['code']);
  }
});
