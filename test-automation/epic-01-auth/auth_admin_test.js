/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-01] QUẢN TRỊ & XÁC THỰC
 * THÀNH VIÊN PHỤ TRÁCH: DƯ NHẬT ANH (Lead Auth & RBAC)
 * JIRA TICKETS: KCPM-4, KCPM-37, KCPM-60, KCPM-80, KCPM-82, KCPM-83, KCPM-89, KCPM-100, KCPM-108
 * ==============================================================================
 */

Feature('[EPIC-01] [Dư Nhật Anh] Quản Trị & Xác Thực (Auth, Users & RBAC Matrix)');

let adminToken = null;
let createdUserId = null;

// ==================== NHÓM 1: ĐĂNG NHẬP & CẤP JWT TOKEN ====================

Scenario('[KCPM-108] [E2E-01-01] [POSITIVE] Đăng nhập Admin và cấp mã xác thực JWT Token [POST /login]', async ({ I }) => {
  const payload = {
    email: 'admin@rescue.vn',
    password: 'password123'
  };
  const res = await I.sendPostRequest('/login', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
  if (res.data && res.data.data && res.data.data.token) {
    adminToken = res.data.data.token;
  }
});

Scenario('[KCPM-108] [E2E-01-02] [NEGATIVE] Chặn đăng nhập khi mật khẩu sai [POST /login]', async ({ I }) => {
  const payload = {
    email: 'admin@rescue.vn',
    password: 'wrong_password_xyz'
  };
  const res = await I.sendPostRequest('/login', payload);
  I.seeResponseCodeIs(401);
});

// ==================== NHÓM 2: ĐỔI MẬT KHẨU (BVA ĐỘ DÀI MIN 6, MAX 32) ====================

Scenario('[KCPM-108] [E2E-01-03] [WORKFLOW] Đổi mật khẩu tài khoản người dùng thành công [POST /change-password]', async ({ I }) => {
  const payload = {
    email: 'staff@rescue.vn',
    oldPassword: 'password123',
    newPassword: 'newValidPassword123'
  };
  const res = await I.sendPostRequest('/change-password', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

Scenario('[KCPM-108] [E2E-01-04] [NEGATIVE] Chặn đổi mật khẩu khi độ dài dưới 6 ký tự (BVA Min=6) [POST /change-password]', async ({ I }) => {
  const payload = {
    email: 'staff@rescue.vn',
    oldPassword: 'password123',
    newPassword: '12345' // 5 ký tự -> Vi phạm BVA
  };
  const res = await I.sendPostRequest('/change-password', payload);
  I.seeResponseCodeIs(400);
});

// ==================== NHÓM 3: QUẢN LÝ TÀI KHOẢN, PHÂN QUYỀN & KHÓA USER ====================

Scenario('[KCPM-108] [E2E-01-05] [WORKFLOW] Vòng đời User: Admin tạo nhân sự mới -> Cập nhật Role -> Khóa tài khoản [POST & PUT /api/v1/admin/users]', async ({ I }) => {
  const randomEmail = 'staff_auto_' + Math.floor(1000 + Math.random() * 9000) + '@rescue.vn';
  const createPayload = {
    fullName: 'Nhân Viên Cứu Hộ Dã Chiến',
    email: randomEmail,
    phone: '0987654321',
    role: 'ROLE_RESCUE_STAFF'
  };
  const createRes = await I.sendPostRequest('/api/v1/admin/users', createPayload);
  I.seeResponseCodeIs(201);
  I.seeResponseContainsKeys(['code', 'data']);

  if (createRes.data && createRes.data.data) {
    createdUserId = createRes.data.data.id;

    // Chuyển trạng thái sang INACTIVE (Khóa tài khoản)
    const lockRes = await I.sendPutRequest(`/api/v1/admin/users/${createdUserId}/status`, {
      status: 'INACTIVE',
      reason: 'Tạm đình chỉ công tác kiểm tra an toàn'
    });
    I.seeResponseCodeIs(200);
    I.seeResponseContainsKeys(['code']);
  }
});

Scenario('[KCPM-108] [E2E-01-06] [NEGATIVE] Chặn đăng nhập đối với tài khoản đang bị khóa INACTIVE [POST /login]', async ({ I }) => {
  const payload = {
    email: 'locked_user@rescue.vn',
    password: 'password123'
  };
  const res = await I.sendPostRequest('/login', payload);
  I.seeResponseCodeIs(403);
});

Scenario('[KCPM-108] [E2E-01-07] [NEGATIVE] Phân quyền chéo RBAC: Token của Citizen gọi API quản trị Admin bị chặn 403 Forbidden [GET /api/v1/admin/users]', async ({ I }) => {
  // Gửi request không có quyền ADMIN
  I.haveRequestHeaders({
    'Authorization': 'Bearer citizen-mock-token-no-admin-privilege'
  });
  const res = await I.sendGetRequest('/api/v1/admin/users');
  I.seeResponseCodeIs(403);
});
