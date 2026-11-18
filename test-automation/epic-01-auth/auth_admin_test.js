/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-01] QUẢN TRỊ & XÁC THỰC
 * THÀNH VIÊN PHỤ TRÁCH: DƯ NHẬT ANH (Lead Auth & RBAC)
 * JIRA TICKETS: KCPM-4, KCPM-37, KCPM-60, KCPM-80, KCPM-82, KCPM-83, KCPM-89, KCPM-100, KCPM-108
 * CHẠY TRÊN BACKEND THẬT: mọi tài khoản test được tạo mới mỗi lần chạy, không đụng mật khẩu admin.
 * ==============================================================================
 */
const { assert, ADMIN, admin, createUser, login } = require('../support/api');

Feature('[EPIC-01] [Dư Nhật Anh] Quản Trị & Xác Thực (Auth, Users & RBAC Matrix)');

let lifecycleUser = null; // User được tạo ở E2E-01-05, bị khóa và dùng lại ở E2E-01-06

// ==================== NHÓM 1: ĐĂNG NHẬP & CẤP JWT TOKEN ====================

Scenario('[KCPM-108] [E2E-01-01] [POSITIVE] Đăng nhập Admin và cấp mã xác thực JWT Token [POST /api/auth/login]', async ({ I }) => {
  const res = await I.sendPostRequest('/api/auth/login', { email: ADMIN.email, password: ADMIN.password });
  I.seeResponseCodeIs(200);
  assert.match(res.data.token, /^eyJ/, 'Token trả về phải là JWT');
  assert.strictEqual(res.data.email, ADMIN.email);
  assert.ok(res.data.roles.includes('ROLE_ADMIN'), 'Admin phải có quyền ROLE_ADMIN');
});

Scenario('[KCPM-108] [E2E-01-02] [NEGATIVE] Chặn đăng nhập khi mật khẩu sai [POST /api/auth/login]', async ({ I }) => {
  const res = await I.sendPostRequest('/api/auth/login', { email: ADMIN.email, password: 'wrong_password_xyz' });
  I.seeResponseCodeIs(401);
  assert.strictEqual(res.data.success, false);
  assert.strictEqual(res.data.token, undefined, 'Không được cấp token khi sai mật khẩu');
});

// ==================== NHÓM 2: ĐỔI MẬT KHẨU (BVA ĐỘ DÀI MIN 6) ====================

Scenario('[KCPM-108] [E2E-01-03] [WORKFLOW] Đổi mật khẩu thành công -> Đăng nhập bằng mật khẩu mới được, mật khẩu cũ bị chặn [POST /api/v1/auth/change-password]', async ({ I }) => {
  const user = await createUser(I, 'USER', 'PwdUser');
  const session = await login(I, user.email, user.password);

  const res = await I.sendPostRequest('/api/v1/auth/change-password',
    { oldPassword: user.password, newPassword: 'newValidPassword123' }, session.headers);
  I.seeResponseCodeIs(200);
  assert.strictEqual(res.data.success, true);

  const newLogin = await I.sendPostRequest('/api/auth/login', { email: user.email, password: 'newValidPassword123' });
  assert.strictEqual(newLogin.status, 200, 'Phải đăng nhập được bằng mật khẩu mới');
  const oldLogin = await I.sendPostRequest('/api/auth/login', { email: user.email, password: user.password });
  assert.strictEqual(oldLogin.status, 401, 'Mật khẩu cũ phải bị vô hiệu');
});

Scenario('[KCPM-108] [E2E-01-04] [NEGATIVE] Chặn đổi mật khẩu khi độ dài dưới 6 ký tự (BVA Min=6) [POST /api/v1/auth/change-password]', async ({ I }) => {
  const user = await createUser(I, 'USER', 'PwdShort');
  const session = await login(I, user.email, user.password);

  const res = await I.sendPostRequest('/api/v1/auth/change-password',
    { oldPassword: user.password, newPassword: '12345' }, session.headers); // 5 ký tự -> vi phạm biên dưới
  I.seeResponseCodeIs(400);
  assert.match(res.data.message, /tối thiểu 6 ký tự/);
});

// ==================== NHÓM 3: QUẢN LÝ TÀI KHOẢN, PHÂN QUYỀN & KHÓA USER ====================

Scenario('[KCPM-108] [E2E-01-05] [WORKFLOW] Vòng đời User: Admin tạo nhân sự mới -> Cập nhật Role -> Khóa tài khoản [POST & PUT /api/v1/admin/users]', async ({ I }) => {
  const { headers } = await admin(I);
  lifecycleUser = await createUser(I, 'USER', 'Lifecycle');
  assert.strictEqual(lifecycleUser.status, 'ACTIVE');

  const detail = await I.sendGetRequest(`/api/v1/admin/users/${lifecycleUser.id}`, headers);
  assert.strictEqual(detail.status, 200);
  assert.strictEqual(detail.data.data.email, lifecycleUser.email);

  const roleRes = await I.sendPutRequest(`/api/v1/admin/users/${lifecycleUser.id}/role?roleId=COORDINATOR`, {}, headers);
  assert.strictEqual(roleRes.status, 200);
  assert.strictEqual(roleRes.data.data.roleId, 'COORDINATOR');

  const lockRes = await I.sendPutRequest(`/api/v1/admin/users/${lifecycleUser.id}/status?status=INACTIVE`, {}, headers);
  I.seeResponseCodeIs(200);
  assert.strictEqual(lockRes.data.data.status, 'INACTIVE');
});

Scenario('[KCPM-108] [E2E-01-06] [NEGATIVE] Chặn đăng nhập đối với tài khoản đang bị khóa INACTIVE (KCPM-100) [POST /api/auth/login]', async ({ I }) => {
  assert.ok(lifecycleUser, 'Cần chạy E2E-01-05 trước để có tài khoản bị khóa');
  const res = await I.sendPostRequest('/api/auth/login', { email: lifecycleUser.email, password: lifecycleUser.password });
  I.seeResponseCodeIs(403);
  assert.strictEqual(res.data.token, undefined, 'Tài khoản bị khóa không được cấp token');
});

Scenario('[KCPM-108] [E2E-01-07] [NEGATIVE] Phân quyền chéo RBAC: Token của Citizen gọi API quản trị Admin bị chặn 403 Forbidden [GET /api/v1/admin/users]', async ({ I }) => {
  const citizen = await createUser(I, 'USER', 'Citizen');
  const session = await login(I, citizen.email, citizen.password); // Token THẬT của tài khoản role USER

  const res = await I.sendGetRequest('/api/v1/admin/users', session.headers);
  I.seeResponseCodeIs(403);
  assert.strictEqual(res.data.success, false);

  // Đối chứng: cùng API đó, Admin gọi thì được phép
  const { headers } = await admin(I);
  const adminRes = await I.sendGetRequest('/api/v1/admin/users', headers);
  assert.strictEqual(adminRes.status, 200);
});
