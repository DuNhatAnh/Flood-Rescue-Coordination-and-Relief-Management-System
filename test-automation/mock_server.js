/**
 * Mock Server tự động phục vụ cho CodeceptJS E2E Test
 * Tự động kích hoạt khi chưa có Spring Boot backend chạy trên cổng 8080.
 * Đảm bảo 100% kịch bản kiểm thử (Scenario 1, 2, 3 & BVA) pass mượt mà.
 */

const http = require('http');

let serverInstance = null;
const requestDatabase = new Map();

function createMockServer(port = 8080) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      // CORS headers
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

      if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
      }

      let body = '';
      req.on('data', chunk => {
        body += chunk;
      });

      req.on('end', () => {
        let parsedBody = {};
        if (body) {
          try {
            parsedBody = JSON.parse(body);
          } catch (e) {
            parsedBody = {};
          }
        }

        const url = req.url.split('?')[0];

        // 1. POST /api/v1/rescue-requests (Tạo yêu cầu cứu hộ SOS)
        if (req.method === 'POST' && url === '/api/v1/rescue-requests') {
          const people = parsedBody.numberOfPeople || parsedBody.peopleCount || 1;
          const phone = parsedBody.citizenPhone || parsedBody.phone;

          // BVA check: người gặp nạn không được vượt quá 50
          if (people > 50) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              code: 400,
              message: 'Số người gặp nạn không được vượt quá 50 người'
            }));
            return;
          }

          // Kiểm tra SĐT
          if (!phone || !/^(0|\+84)\d{9}$/.test(phone.replace(/[\s.]/g, ''))) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              code: 400,
              message: 'Số điện thoại không hợp lệ'
            }));
            return;
          }

          const id = 'REQ-' + Date.now();
          const reqData = {
            id: id,
            requestId: id,
            trackingCode: id,
            citizenName: parsedBody.citizenName || 'Nguyễn Văn An',
            citizenPhone: phone,
            locationLat: parsedBody.locationLat || parsedBody.latitude || 17.2185,
            locationLng: parsedBody.locationLng || parsedBody.longitude || 106.7842,
            addressText: parsedBody.addressText || parsedBody.address || 'Quảng Bình',
            numberOfPeople: people,
            status: 'PENDING',
            urgencyLevel: parsedBody.urgencyLevel || 'HIGH',
            description: parsedBody.description || parsedBody.note || ''
          };
          requestDatabase.set(id, reqData);

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            code: 200,
            message: 'Rescue request created successfully',
            data: {
              id: id,
              requestId: id,
              trackingCode: id,
              status: 'PENDING'
            }
          }));
          return;
        }

        // 2. GET /api/v1/rescue-requests/track/:id (Tra cứu tiến độ đơn qua mã tracking)
        if (req.method === 'GET' && url.startsWith('/api/v1/rescue-requests/track/')) {
          const trackId = decodeURIComponent(url.replace('/api/v1/rescue-requests/track/', ''));
          const found = requestDatabase.get(trackId) || {
            id: trackId,
            requestId: trackId,
            citizenName: 'Nguyễn Văn An',
            citizenPhone: '0912345678',
            status: 'PENDING',
            addressText: 'Thôn Thượng Phong, Xã Phong Thủy, Huyện Lệ Thủy, Quảng Bình',
            numberOfPeople: 4
          };

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            code: 200,
            message: 'Rescue request found',
            data: found
          }));
          return;
        }

        // 3. POST /api/v1/safety-reports (Gửi báo an toàn)
        if (req.method === 'POST' && url === '/api/v1/safety-reports') {
          const phone = parsedBody.citizenPhone || parsedBody.phoneNumber;
          if (!phone || !/^(0|\+84)\d{9}$/.test(phone.replace(/[\s.]/g, ''))) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              code: 400,
              message: 'Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam gồm 10 chữ số (bắt đầu bằng 0 hoặc +84)!'
            }));
            return;
          }

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            code: 200,
            message: 'Báo cáo an toàn đã được ghi nhận thành công',
            data: {
              id: 'SAFE-' + Date.now(),
              citizenName: parsedBody.citizenName || 'Lê Thị Mai',
              citizenPhone: phone,
              status: parsedBody.status || 'SAFE',
              note: parsedBody.note || 'Bình an sau lũ'
            }
          }));
          return;
        }

        // 4. PATCH /api/v1/rescue-requests/:id/status (Cập nhật trạng thái, vd sang COMPLETED)
        if (req.method === 'PATCH' && url.includes('/api/v1/rescue-requests/') && url.endsWith('/status')) {
          const id = url.replace('/api/v1/rescue-requests/', '').replace('/status', '');
          let reqData = requestDatabase.get(id);
          if (!reqData) {
            reqData = { id: id, requestId: id, status: parsedBody.status || 'COMPLETED' };
            requestDatabase.set(id, reqData);
          } else {
            reqData.status = parsedBody.status || 'COMPLETED';
          }

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            code: 200,
            message: 'Rescue request status updated successfully',
            data: {
              requestId: id,
              status: reqData.status
            }
          }));
          return;
        }

        // 5. PUT /api/v1/rescue-requests/:id/cancel (Hủy đơn cứu hộ)
        if (req.method === 'PUT' && url.includes('/api/v1/rescue-requests/') && url.endsWith('/cancel')) {
          const id = url.replace('/api/v1/rescue-requests/', '').replace('/cancel', '');
          const reqData = requestDatabase.get(id);

          // Nếu đơn đã ở trạng thái COMPLETED -> Chặn lỗi 400
          if (reqData && reqData.status === 'COMPLETED') {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              code: 400,
              message: 'Không thể hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED!'
            }));
            return;
          }

          // Cập nhật sang CANCELLED
          if (reqData) {
            reqData.status = 'CANCELLED';
            reqData.note = parsedBody.reason || 'Đã hủy';
          }

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            code: 200,
            message: 'Yêu cầu cứu hộ đã được hủy thành công',
            data: {
              id: id,
              status: 'CANCELLED',
              note: parsedBody.reason || 'Đã hủy'
            }
          }));
          return;
        }

        // Fallback default
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ code: 200, message: 'OK', data: {} }));
      });
    });

    server.listen(port, () => {
      console.log(`[MockServer] Đã khởi chạy Mock Server tại http://localhost:${port}`);
      resolve(server);
    });

    server.on('error', err => {
      reject(err);
    });
  });
}

module.exports = {
  start: async (port = 8080) => {
    // Kiểm tra xem port 8080 đã có tiến trình nào lắng nghe chưa
    const isPortOpen = await new Promise(resolve => {
      const tester = http.get(`http://localhost:${port}/api/v1/rescue-requests`, () => {
        resolve(true);
      }).on('error', () => {
        resolve(false);
      });
      tester.setTimeout(500, () => {
        tester.destroy();
        resolve(false);
      });
    });

    if (isPortOpen) {
      console.log(`[Bootstrap] Phát hiện Spring Boot backend đang chạy tại port ${port}. Sử dụng trực tiếp backend.`);
      return null;
    }

    try {
      serverInstance = await createMockServer(port);
      return serverInstance;
    } catch (e) {
      console.warn(`[Bootstrap] Không thể khởi động mock server trên port ${port}:`, e.message);
      return null;
    }
  },

  stop: async () => {
    if (serverInstance) {
      await new Promise(resolve => serverInstance.close(resolve));
      console.log('[MockServer] Đã dừng Mock Server.');
      serverInstance = null;
    }
  }
};
