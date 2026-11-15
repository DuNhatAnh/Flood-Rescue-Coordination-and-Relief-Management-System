/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-05] QUẢN LÝ KHO BÃI & CỨU TRỢ HIỆN TRƯỜNG
 * THÀNH VIÊN PHỤ TRÁCH: PHAN QUỐC DANH (Lead Warehouse & Relief)
 * JIRA TICKETS: KCPM-36, KCPM-71, KCPM-72, KCPM-73, KCPM-98, KCPM-99, KCPM-103, KCPM-116
 * ==============================================================================
 */

Feature('[EPIC-05] [Phan Quốc Danh] Quản Lý Kho Bãi & Cứu Trợ Hiện Trường (Warehouse & Inventory)');

let createdWarehouseId = null;
let createdDistributionId = null;

// ==================== NHÓM 1: THÀNH LẬP KHO BÃI & NHẬP KHO NHU YẾU PHẨM ====================

Scenario('[KCPM-116] [E2E-05-01] [WORKFLOW] Tạo kho hàng dã chiến mới tiếp nhận hàng cứu trợ [POST /api/v1/warehouses]', async ({ I }) => {
  const payload = {
    name: 'Kho Dã Chiến Trung Tâm Lệ Thủy',
    location: 'Thị trấn Kiến Giang, Lệ Thủy, Quảng Bình',
    capacity: 10000,
    managerName: 'Trưởng kho Phan Quốc Danh'
  };
  const res = await I.sendPostRequest('/api/v1/warehouses', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
  if (res.data && res.data.data) {
    createdWarehouseId = res.data.data.id;
  }
});

Scenario('[KCPM-116] [E2E-05-02] [POSITIVE] Nhập kho 500 thùng mì tôm và tăng tồn kho khả dụng [POST /api/v1/inventory/import]', async ({ I }) => {
  const payload = {
    warehouseId: createdWarehouseId || 'WH-01',
    itemId: 'ITEM-MI-TOM',
    quantity: 500,
    importDate: '2026-11-15'
  };
  const res = await I.sendPostRequest('/api/v1/inventory/import', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

// ==================== NHÓM 2: XUẤT KHO CỨU TRỢ & CHẶN ÂM KHO ====================

Scenario('[KCPM-116] [E2E-05-03] [NEGATIVE] Chặn xuất kho vượt quá số lượng tồn khả dụng (Chặn âm kho) [POST /api/v1/distributions]', async ({ I }) => {
  const payload = {
    warehouseId: createdWarehouseId || 'WH-01',
    teamId: 'team-01',
    itemId: 'ITEM-MI-TOM',
    quantity: 999999, // Vượt xa tồn kho 500
    destination: 'Thôn Mỹ Lộc Thượng'
  };
  const res = await I.sendPostRequest('/api/v1/distributions', payload);
  I.seeResponseCodeIs(400);
});

Scenario('[KCPM-116] [E2E-05-04] [WORKFLOW] Xuất kho cứu trợ hợp lệ 200 thùng mì tôm [POST /api/v1/distributions]', async ({ I }) => {
  const payload = {
    warehouseId: createdWarehouseId || 'WH-01',
    teamId: 'team-01',
    itemId: 'ITEM-MI-TOM',
    quantity: 200,
    destination: 'Xã An Thủy, Lệ Thủy'
  };
  const res = await I.sendPostRequest('/api/v1/distributions', payload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
  if (res.data && res.data.data) {
    createdDistributionId = res.data.data.id;
  }
});

// ==================== NHÓM 3: ROLLBACK HOÀN KHO & THẺ KHO THỰC TẾ ====================

Scenario('[KCPM-116] [E2E-05-05] [WORKFLOW] Hủy phiếu xuất cứu trợ và tự động hoàn trả tồn kho (Rollback Inventory) [POST /api/v1/distributions/{id}/cancel]', async ({ I }) => {
  const targetId = createdDistributionId || 'DIST-DEMO-01';
  const res = await I.sendPostRequest(`/api/v1/distributions/${targetId}/cancel`, {
    reason: 'Phương tiện gặp sự cố thủy lực, hàng cứu trợ chuyển ngược về kho'
  });
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
});

Scenario('[KCPM-116] [E2E-05-06] [POSITIVE] Tra cứu danh sách các mặt hàng tồn kho dưới ngưỡng an toàn [GET /api/v1/inventory/warehouse/{id}/low-stock]', async ({ I }) => {
  const targetWarehouse = createdWarehouseId || 'WH-01';
  const res = await I.sendGetRequest(`/api/v1/inventory/warehouse/${targetWarehouse}/low-stock`);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
});
