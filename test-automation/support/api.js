/**
 * Helper dùng chung cho toàn bộ kịch bản E2E chạy trên BACKEND THẬT (Spring Boot :8080).
 * - Đăng nhập lấy JWT thật qua POST /api/auth/login (token nằm ở root response: res.data.token).
 * - Sinh dữ liệu test riêng cho mỗi lần chạy (email, biển số...) để chạy lặp lại nhiều lần không bị trùng.
 */
const assert = require('assert');

const ADMIN = {
  email: process.env.ADMIN_EMAIL || 'admin@rescue.vn',
  password: process.env.ADMIN_PASSWORD || 'admin123',
};

// Mật khẩu mặc định backend gán khi Admin tạo user mới (UserService.createUser)
const DEFAULT_NEW_USER_PASSWORD = '123456';

let adminSession = null;

/** Sinh chuỗi duy nhất cho mỗi lần chạy */
function uid(prefix) {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

/** Đăng nhập và trả về { token, id, headers } — fail ngay nếu đăng nhập không thành công */
async function login(I, email, password) {
  const res = await I.sendPostRequest('/api/auth/login', { email, password });
  assert.strictEqual(res.status, 200, `Đăng nhập ${email} thất bại: HTTP ${res.status} ${JSON.stringify(res.data)}`);
  return { token: res.data.token, id: res.data.id, headers: { Authorization: `Bearer ${res.data.token}` } };
}

/** Phiên đăng nhập Admin (cache trong một lần chạy) */
async function admin(I) {
  if (!adminSession) adminSession = await login(I, ADMIN.email, ADMIN.password);
  return adminSession;
}

/** Admin tạo user mới với role chỉ định. RESCUE_STAFF sẽ được backend tự tạo một đội AVAILABLE riêng. */
async function createUser(I, roleId, namePrefix = 'E2E') {
  const { headers } = await admin(I);
  const email = `${uid(namePrefix.toLowerCase())}@rescue.vn`;
  const res = await I.sendPostRequest('/api/v1/admin/users', {
    fullName: `${namePrefix} ${roleId}`,
    email,
    phone: '0912345678',
    roleId,
  }, headers);
  assert.strictEqual(res.status, 200, `Tạo user ${roleId} thất bại: ${JSON.stringify(res.data)}`);
  return { ...res.data.data, email, password: DEFAULT_NEW_USER_PASSWORD };
}

/** Người dân gửi một đơn SOS mới (trạng thái PENDING) */
async function createRescueRequest(I, overrides = {}) {
  const res = await I.sendPostRequest('/api/v1/rescue-requests', {
    citizenName: 'Nguyễn Văn E2E',
    citizenPhone: '0912345678',
    locationLat: 17.2185,
    locationLng: 106.7842,
    addressText: 'Xã Phong Thủy, Huyện Lệ Thủy, Quảng Bình',
    numberOfPeople: 3,
    urgencyLevel: 'HIGH',
    description: 'Đơn SOS sinh tự động cho kiểm thử E2E',
    ...overrides,
  });
  assert.strictEqual(res.status, 200, `Tạo đơn SOS thất bại: ${JSON.stringify(res.data)}`);
  return res.data.data; // { id, requestId, status }
}

/** Tạo phương tiện mới (trạng thái AVAILABLE) */
async function createVehicle(I, overrides = {}) {
  const { id: adminId } = await admin(I);
  const res = await I.sendPostRequest(`/api/v1/vehicles?userId=${adminId}`, {
    vehicleType: 'CANO',
    licensePlate: uid('CN').slice(0, 20),
    currentLocation: 'Bến Lệ Thủy - Quảng Bình',
    ...overrides,
  });
  assert.strictEqual(res.status, 201, `Tạo phương tiện thất bại: ${JSON.stringify(res.data)}`);
  return res.data.data;
}

module.exports = {
  assert, ADMIN, DEFAULT_NEW_USER_PASSWORD,
  uid, login, admin, createUser, createRescueRequest, createVehicle,
};
