/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-05] QUẢN LÝ KHO BÃI & CỨU TRỢ HIỆN TRƯỜNG
 * THÀNH VIÊN PHỤ TRÁCH: PHAN QUỐC DANH (Lead Warehouse & Relief)
 * JIRA TICKET: KCPM-116 ([Sprint 5] [E2E Test] Xây dựng Kịch bản CodeceptJS E2E Chuỗi Nhập kho, Xuất kho & Hoàn kho)
 * CHẠY TRÊN BACKEND THẬT: mỗi lần chạy tạo kho + mặt hàng mới, nên số tồn kho luôn bắt đầu từ 0 và kiểm tra chính xác 500 / 300 / 500.
 * ==============================================================================
 */
const { assert, admin, uid } = require('../support/api');

Feature('[EPIC-05] [Phan Quốc Danh] Quản Lý Kho Bãi & Cứu Trợ Hiện Trường (Warehouse & Inventory E2E)');

let warehouseId = null;
let reliefItemId = null;
let distributionId = null;

/** Đọc số tồn kho thực tế của mặt hàng trong kho */
async function stockOf(I) {
  const res = await I.sendGetRequest(`/api/v1/inventory/warehouse/${warehouseId}`);
  assert.strictEqual(res.status, 200);
  const row = res.data.data.find(item => item.itemId === reliefItemId);
  return row ? row.quantity : 0;
}

Scenario('[KCPM-116] [SCENARIO 1] Tạo kho hàng dã chiến [POST /api/v1/warehouses] và Thêm mặt hàng nhu yếu phẩm [POST /api/v1/relief-items]', async ({ I }) => {
  const resWh = await I.sendPostRequest('/api/v1/warehouses', {
    warehouseName: `Kho Cứu Trợ Dã Chiến Hòa Vang ${uid('E2E')}`,
    location: 'Huyện Hòa Vang, TP Đà Nẵng',
    status: 'ACTIVE',
  });
  I.seeResponseCodeIs(200);
  warehouseId = resWh.data.data.id;
  assert.ok(warehouseId, 'Phải trả về ID kho vừa tạo');

  const resItem = await I.sendPostRequest('/api/v1/relief-items', {
    itemName: `Mì tôm cứu trợ ${uid('E2E')}`,
    unit: 'Thùng',
    description: 'Nhu yếu phẩm cứu trợ khẩn cấp mùa mưa lũ',
  });
  I.seeResponseCodeIs(200);
  reliefItemId = resItem.data.data.id;
  assert.ok(reliefItemId, 'Phải trả về ID mặt hàng vừa tạo');
});

Scenario('[KCPM-116] [SCENARIO 2] Nhập kho 500 thùng mì tôm [POST /api/v1/inventory/import] -> Kiểm tra thẻ kho hiển thị tồn khả dụng đúng 500', async ({ I }) => {
  const { id: adminId } = await admin(I);
  const res = await I.sendPostRequest(`/api/v1/inventory/import?userId=${adminId}`, {
    warehouseId,
    itemId: reliefItemId,
    quantity: 500,
    source: 'MẶT TRẬN TỔ QUỐC VIỆT NAM',
    referenceNumber: 'PNK-KCPM-116-001',
    condition: 'GOOD',
  });
  I.seeResponseCodeIs(200);
  assert.strictEqual(await stockOf(I), 500, 'Tồn kho sau khi nhập phải đúng 500');
});

Scenario('[KCPM-116] [SCENARIO 3] [NEGATIVE] Thử xuất kho 600 thùng vượt tồn kho [POST /api/v1/distributions] -> Kỳ vọng chặn lỗi 400 Bad Request', async ({ I }) => {
  const res = await I.sendPostRequest('/api/v1/distributions', {
    warehouseId,
    type: 'EXPORT',
    status: 'PENDING',
    items: [{ itemId: reliefItemId, quantity: 600 }],
  });
  I.seeResponseCodeIs(400);
  assert.match(res.data.message, /không đủ/, 'Phải bị chặn đúng lý do tồn kho không đủ (Bug KCPM-99)');
  assert.strictEqual(await stockOf(I), 500, 'Tồn kho không được thay đổi khi xuất thất bại');
});

Scenario('[KCPM-116] [SCENARIO 4] Xuất kho hợp lệ 200 thùng mì tôm [POST /api/v1/distributions] -> Tồn kho giảm còn 300 thùng', async ({ I }) => {
  const res = await I.sendPostRequest('/api/v1/distributions', {
    warehouseId,
    type: 'EXPORT',
    status: 'PENDING', // Để PENDING thì mới hủy được ở SCENARIO 5 (đơn COMPLETED không cho hủy)
    items: [{ itemId: reliefItemId, quantity: 200 }],
  });
  I.seeResponseCodeIs(200);
  distributionId = res.data.id; // API này trả về Distribution trực tiếp, không bọc ApiResponse
  assert.ok(distributionId, 'Phải trả về mã đợt phân phối');
  assert.strictEqual(await stockOf(I), 300, 'Tồn kho sau khi xuất 200 phải còn 300');
});

Scenario('[KCPM-116] [SCENARIO 5] Hủy phiếu xuất [POST /api/v1/distributions/{id}/cancel] -> Tự động hoàn lại 500 thùng (Nghiệm thu bug KCPM-103)', async ({ I }) => {
  assert.ok(distributionId, 'Cần chạy SCENARIO 4 trước');
  const { headers } = await admin(I); // API hủy yêu cầu quyền ADMIN hoặc WAREHOUSE_STAFF
  const res = await I.sendPostRequest(`/api/v1/distributions/${distributionId}/cancel`, {
    reason: 'Phương tiện gặp sự cố thủy lực, hủy phiếu xuất và hoàn trả toàn bộ nhu yếu phẩm về kho dã chiến',
  }, headers);
  I.seeResponseCodeIs(200);
  assert.strictEqual(res.data.status, 'CANCELLED');
  assert.strictEqual(await stockOf(I), 500, 'Tồn kho phải được hoàn về đúng 500 sau khi hủy phiếu xuất');
});
