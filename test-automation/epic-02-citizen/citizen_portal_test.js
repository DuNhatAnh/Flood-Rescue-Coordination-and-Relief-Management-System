/**
 * ==============================================================================
 * DỰ ÁN: [KCPM] HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ
 * PHÂN HỆ: [EPIC-02] CỔNG NGƯỜI DÂN & TIẾP NHẬN CỨU NẠN SOS
 * THÀNH VIÊN PHỤ TRÁCH: LÂM KHIÊM (Lead Citizen & SOS)
 * JIRA TICKETS: KCPM-53, KCPM-84, KCPM-85, KCPM-91, KCPM-94, KCPM-109, KCPM-110
 * MÔ TẢ: Kịch bản kiểm thử tự động hóa E2E API bằng CodeceptJS bao gồm:
 *   - Scenario 1: Người dân gửi đơn SOS -> Nhận trackingId -> Gọi GET /track/{id} kiểm tra trạng thái ban đầu là PENDING.
 *   - Scenario 2: Người dân gửi báo an toàn (POST /api/v1/safety-reports) với SĐT chuẩn 10 số VN -> Kiểm tra nhận phản hồi 200 OK.
 *   - Scenario 3: Người dân hủy yêu cầu cứu hộ khi còn PENDING (PUT /api/v1/rescue-requests/{id}/cancel) -> Thành công (200);
 *                 Thử gọi hủy đơn đã COMPLETED -> Kỳ vọng hệ thống chặn lỗi (HTTP 400).
 * ==============================================================================
 */

const assert = require('assert');

Feature('[EPIC-02] [Lâm Khiêm] Cổng Người Dân & Tiếp Nhận SOS (Rescue Requests & Safety Reports)');

let createdRequestId = null;
let trackingId = null;

// ==================== SCENARIO 1: TẠO ĐƠN & TRA CỨU ====================
Scenario('[KCPM-110] [Scenario 1] (Tạo đơn & Tra cứu): Người dân gửi đơn SOS -> Nhận trackingId -> Kiểm tra trạng thái ban đầu là PENDING', async ({ I }) => {
  const sosPayload = {
    citizenName: 'Nguyễn Văn An',
    citizenPhone: '0912345678',
    locationLat: 17.2185,
    locationLng: 106.7842,
    addressText: 'Thôn Thượng Phong, Xã Phong Thủy, Huyện Lệ Thủy, Quảng Bình',
    numberOfPeople: 4,
    urgencyLevel: 'HIGH',
    description: 'Nước lũ dâng cao ngang mái nhà, gia đình cần ca nô cứu hộ gấp'
  };

  // 1. Gửi đơn kêu cứu SOS (POST /api/v1/rescue-requests)
  const res = await I.sendPostRequest('/api/v1/rescue-requests', sosPayload);
  I.seeResponseCodeIsSuccessful();
  I.seeResponseContainsKeys(['code', 'data']);

  // 2. Nhận trackingId từ dữ liệu trả về
  if (res.data && res.data.data) {
    createdRequestId = res.data.data.id || res.data.data.requestId;
    trackingId = res.data.data.requestId || res.data.data.trackingCode || createdRequestId;
  }

  // 3. Gọi GET /api/v1/rescue-requests/track/{id} với trackingId
  const targetTrackId = trackingId || createdRequestId;
  const trackRes = await I.sendGetRequest(`/api/v1/rescue-requests/track/${targetTrackId}`);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);

  // 4. Kiểm tra trạng thái ban đầu của yêu cầu cứu trợ là PENDING
  I.seeResponseContainsJson({
    data: {
      status: 'PENDING'
    }
  });
});

// ==================== SCENARIO 2: BÁO AN TOÀN ====================
Scenario('[KCPM-110] [Scenario 2] (Báo an toàn): Người dân gửi báo an toàn với SĐT chuẩn 10 số VN -> Kiểm tra nhận phản hồi 200 OK', async ({ I }) => {
  const safetyPayload = {
    citizenName: 'Lê Thị Mai',
    citizenPhone: '0905123456',
    locationLat: 17.2185,
    locationLng: 106.7842,
    addressText: 'Khu sơ tán Trường THPT Lệ Thủy, Tỉnh Quảng Bình',
    note: 'Gia đình đã lên thuyền cứu hộ an toàn sau lũ'
  };

  // Gửi báo an toàn (POST /api/v1/safety-reports)
  const res = await I.sendPostRequest('/api/v1/safety-reports', safetyPayload);
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code', 'data']);
  I.seeResponseContainsJson({
    code: 200,
    data: {
      citizenPhone: '0905123456'
    }
  });
});

// ==================== SCENARIO 3: HỦY ĐƠN KHẨN CẤP ====================
Scenario('[KCPM-110] [Scenario 3] (Hủy đơn khẩn cấp): Hủy đơn cứu hộ khi còn PENDING -> Thành công; Thử gọi hủy đơn đã COMPLETED -> Chặn lỗi 400', async ({ I }) => {
  // 1. Chuẩn bị mã yêu cầu ở trạng thái PENDING
  let pendingId = createdRequestId;
  if (!pendingId) {
    const initRes = await I.sendPostRequest('/api/v1/rescue-requests', {
      citizenName: 'Trần Văn Bình',
      citizenPhone: '0934567890',
      locationLat: 17.2190,
      locationLng: 106.7850,
      addressText: 'Xã An Thủy, Huyện Lệ Thủy, Quảng Bình',
      numberOfPeople: 2,
      urgencyLevel: 'MEDIUM',
      description: 'Nước ngập sân, cần hỗ trợ'
    });
    if (initRes.data && initRes.data.data) {
      pendingId = initRes.data.data.id || initRes.data.data.requestId;
    }
  }

  // 2. Người dân hủy yêu cầu cứu hộ khi còn PENDING (PUT /api/v1/rescue-requests/{id}/cancel) -> Thành công 200 OK
  const cancelRes = await I.sendPutRequest(`/api/v1/rescue-requests/${pendingId}/cancel`, {
    reason: 'Người dân tự hủy khi nước đã rút, gia đình an toàn'
  });
  I.seeResponseCodeIs(200);
  I.seeResponseContainsKeys(['code']);
  I.seeResponseContainsJson({
    code: 200,
    data: {
      status: 'CANCELLED'
    }
  });

  // 3. Chuẩn bị một yêu cầu cứu nạn và cập nhật trạng thái sang COMPLETED
  const completedSetupRes = await I.sendPostRequest('/api/v1/rescue-requests', {
    citizenName: 'Hoàng Thị Cúc',
    citizenPhone: '0978123456',
    locationLat: 17.2200,
    locationLng: 106.7860,
    addressText: 'Xã Sơn Thủy, Huyện Lệ Thủy, Quảng Bình',
    numberOfPeople: 3,
    urgencyLevel: 'HIGH',
    description: 'Cần cứu hộ chuyển người già đi cấp cứu'
  });

  const completedTargetId = completedSetupRes.data?.data?.id || completedSetupRes.data?.data?.requestId;

  // Cập nhật trạng thái sang COMPLETED
  const completeRes = await I.sendPatchRequest(`/api/v1/rescue-requests/${completedTargetId}/status`, {
    status: 'COMPLETED',
    note: 'Đội cứu hộ đã đưa người già đến trạm xá an toàn, hoàn thành nhiệm vụ'
  });

  // 4. Thử gọi hủy đơn đã ở trạng thái COMPLETED -> Kỳ vọng hệ thống chặn lỗi HTTP 400
  const invalidCancelRes = await I.sendPutRequest(`/api/v1/rescue-requests/${completedTargetId}/cancel`, {
    reason: 'Cố tình hủy nhiệm vụ cứu hộ đã ở trạng thái COMPLETED'
  });
  I.seeResponseCodeIs(400);
  // Đảm bảo bị chặn đúng lý do (đơn đã COMPLETED), không phải do bước chuẩn bị bị lỗi
  assert.strictEqual(completeRes.status, 200, 'Bước chuẩn bị chuyển đơn sang COMPLETED phải thành công');
  assert.strictEqual(invalidCancelRes.data.success, false);
});

// ==================== BỔ SUNG: KIỂM THỬ GIÁ TRỊ BIÊN (BVA) & VALIDATION ====================
Scenario('[KCPM-110] [Scenario 4] [NEGATIVE] Chặn tạo yêu cầu cứu nạn khi số người vượt biên tối đa (BVA > 50 người) [POST /api/v1/rescue-requests]', async ({ I }) => {
  const invalidPeoplePayload = {
    citizenName: 'Trần Văn Cường',
    citizenPhone: '0988776655',
    locationLat: 17.2185,
    locationLng: 106.7842,
    addressText: 'Xã Phong Thủy, Huyện Lệ Thủy, Quảng Bình',
    numberOfPeople: 51, // Vượt ngưỡng tối đa 50 người cho phép
    description: 'Yêu cầu vượt quá tải trọng tối đa'
  };
  const res = await I.sendPostRequest('/api/v1/rescue-requests', invalidPeoplePayload);
  I.seeResponseCodeIs(400);
  assert.match(JSON.stringify(res.data), /vượt quá 50/, 'Phải bị chặn đúng do vượt biên 50 người');
});

Scenario('[KCPM-110] [Scenario 5] [NEGATIVE] Chặn gửi báo an toàn với số điện thoại không hợp lệ (Chứa chữ cái / Sai định dạng) [POST /api/v1/safety-reports]', async ({ I }) => {
  const invalidPhonePayload = {
    citizenName: 'Phan Văn Sai',
    citizenPhone: '0905INVALID',
    addressText: 'Khu sơ tán THPT Lệ Thủy',
    note: 'SĐT không đúng định dạng 10 số'
  };
  const res = await I.sendPostRequest('/api/v1/safety-reports', invalidPhonePayload);
  I.seeResponseCodeIs(400);
  assert.match(JSON.stringify(res.data), /điện thoại/i, 'Phải bị chặn đúng do số điện thoại sai định dạng');
});
