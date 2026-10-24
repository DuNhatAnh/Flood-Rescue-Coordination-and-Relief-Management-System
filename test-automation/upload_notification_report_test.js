Feature('Kiểm thử API FileUpload, Notification và Lọc ngày Report (KCPM-8)');

// ==================== NHÓM 1: FILE UPLOAD (FileUpload - Chặn HTTP 500) ====================

Scenario('TC-FILE-01 [NEGATIVE]: Upload ảnh không có file hoặc file rỗng [POST /api/upload/image]', async ({ I }) => {
  // Gửi request POST không có file (Content-Length 0 hoặc non-multipart)
  const res = await I.sendPostRequest('/api/upload/image', {});
  console.log('Upload không có file status code:', res.status);
  I.seeResponseCodeIs(400); // Phải là 400 Bad Request, không được là 500
});

// ==================== NHÓM 2: THÔNG BÁO (Notification - Validate userId & title) ====================

Scenario('TC-NOTIF-01 [NEGATIVE]: Gửi thông báo thiếu người nhận (userId) [POST /api/v1/notifications]', async ({ I }) => {
  const payload = {
    title: 'Cảnh báo lũ lụt cấp 3',
    content: 'Mực nước sông dâng cao'
  };
  const res = await I.sendPostRequest('/api/v1/notifications', payload);
  console.log('Thông báo thiếu userId status code:', res.status);
  I.seeResponseCodeIs(400);
});

Scenario('TC-NOTIF-02 [NEGATIVE]: Gửi thông báo thiếu tiêu đề (title) [POST /api/v1/notifications]', async ({ I }) => {
  const payload = {
    userId: 'user-flood-001',
    content: 'Nội dung thông báo khẩn cấp'
  };
  const res = await I.sendPostRequest('/api/v1/notifications', payload);
  console.log('Thông báo thiếu title status code:', res.status);
  I.seeResponseCodeIs(400);
});

Scenario('TC-NOTIF-03 [NEGATIVE]: Lấy số thông báo chưa đọc không truyền userId [GET /api/v1/notifications/unread-count]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/notifications/unread-count');
  console.log('Unread count thiếu userId status code:', res.status);
  I.seeResponseCodeIs(400);
});

Scenario('TC-NOTIF-04 [POSITIVE]: Gửi thông báo hợp lệ đầy đủ người nhận và tiêu đề [POST /api/v1/notifications]', async ({ I }) => {
  const payload = {
    userId: 'user-flood-001',
    title: 'Thông báo điều động cano cứu nạn',
    content: 'Đội số 1 đã xuất phát đi Lệ Thủy'
  };
  const res = await I.sendPostRequest('/api/v1/notifications', payload);
  console.log('Gửi thông báo hợp lệ status code:', res.status);
  I.seeResponseCodeIs(200);
});

// ==================== NHÓM 3: CHẶN LỌC BÁO CÁO KHI NGÀY BẮT ĐẦU > NGÀY KẾT THÚC ====================

Scenario('TC-REP-01 [NEGATIVE]: Lọc Safety Report khi startDate > endDate [GET /api/v1/safety-reports]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/safety-reports?startDate=2026-10-25&endDate=2026-10-10');
  console.log('Safety report ngày bắt đầu > ngày kết thúc status code:', res.status);
  I.seeResponseCodeIs(400);
});

Scenario('TC-REP-02 [NEGATIVE]: Lọc Report cứu hộ khi startDate > endDate [GET /api/v1/reports/rescue-history]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/reports/rescue-history?startDate=2026-10-25&endDate=2026-10-10');
  console.log('Rescue history ngày bắt đầu > ngày kết thúc status code:', res.status);
  I.seeResponseCodeIs(400);
});

Scenario('TC-REP-03 [NEGATIVE]: Lọc Report xuất nhập kho khi startDate > endDate [GET /api/v1/reports/warehouse-history]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/reports/warehouse-history?startDate=2026-10-25&endDate=2026-10-10');
  console.log('Warehouse history ngày bắt đầu > ngày kết thúc status code:', res.status);
  I.seeResponseCodeIs(400);
});

Scenario('TC-REP-04 [POSITIVE]: Lọc Safety Report với khoảng ngày hợp lệ [GET /api/v1/safety-reports]', async ({ I }) => {
  const res = await I.sendGetRequest('/api/v1/safety-reports?startDate=2026-10-01&endDate=2026-10-20');
  console.log('Safety report khoảng ngày hợp lệ status code:', res.status);
  I.seeResponseCodeIs(200);
});
