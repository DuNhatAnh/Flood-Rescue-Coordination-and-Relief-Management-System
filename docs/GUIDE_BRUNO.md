# 📙 HƯỚNG DẪN CHUẨN HÓA VIẾT REQUEST BRUNO API (.YML)

> **Mục tiêu:** Đảm bảo tất cả 5 thành viên trong nhóm tạo các file request kiểm thử API trên Bruno đồng nhất 100% về cấu trúc, cách đặt tên và assert kết quả.

---

## 1. QUY TẮC ĐẶT TÊN FILE (BẮT BUỘC)

* **Vị trí lưu file:** Trong thư mục `Flood Rescue Coordination & Relief Management API/<Tên_Module>/`
* **Cú pháp tên file:** `[HTTP_METHOD] -[chuc_nang]-[loai_test].yml`
* **Ví dụ chuẩn:**
  * `POST -bva-people-min-1.yml` *(Test biên Min 1 người)*
  * `POST -bva-people-err-51.yml` *(Test biên lỗi 51 người)*
  * `POST -change-password-too-short.yml` *(Test mật khẩu ngắn)*
  * `PUT -{id}-status.yml` *(Cập nhật trạng thái)*

---

## 2. TEMPLATE FILE CHUẨN (COPY & PASTE ĐỂ SỬ DỤNG)

Mỗi file request trong Bruno là một file định dạng YAML `.yml`. Hãy copy template dưới đây và thay đổi các thông số phù hợp:

```yaml
info:
  name: TC_CODE - [METHOD] /api/v1/duong-dan (Mô tả ngắn ca test)
  type: http
  seq: 10

http:
  method: POST
  url: "{{baseUrl}}/api/v1/rescue-requests"
  headers:
    - name: Content-Type
      value: application/json
    - name: Authorization
      value: Bearer {{bearerToken}}
  body:
    type: json
    data: |-
      {
        "citizenName": "Nguyễn Văn A",
        "citizenPhone": "0987654321",
        "peopleCount": 1,
        "note": "Cần hỗ trợ xuồng cứu hộ khẩn cấp"
      }
  auth: inherit

runtime:
  scripts:
    - type: after-response
      code: |-
        test("TC_CODE: Kiểm tra mã phản hồi HTTP", function () {
            expect(res.getStatus()).to.equal(200);
        });

settings:
  encodeUrl: true
  timeout: 0
  followRedirects: true
  maxRedirects: 5
  forwardAuthorizationHeader: false
```

---

## 3. CÁC ĐOẠN CODE ASSERTION PHỔ BIẾN TRONG `runtime.scripts`

### A. Kiểm tra phản hồi thành công (200 OK / 201 Created):
```javascript
test("Kiểm tra HTTP Status 200 OK", function () {
    expect(res.getStatus()).to.equal(200);
});

test("Kiểm tra cấu trúc dữ liệu trả về", function () {
    const data = res.getBody();
    expect(data).to.have.property('code');
    expect(data.code).to.equal(200);
});
```

### B. Kiểm tra bắt lỗi nghiệp vụ (400 Bad Request):
```javascript
test("Bắt lỗi dữ liệu không hợp lệ - HTTP 400", function () {
    expect(res.getStatus()).to.equal(400);
    const body = res.getBody();
    expect(body.message).to.include("không hợp lệ");
});
```

### C. Kiểm tra phân quyền RBAC (403 Forbidden):
```javascript
test("Chặn truy cập trái phép - HTTP 403 Forbidden", function () {
    expect(res.getStatus()).to.equal(403);
});
```

---

## 4. QUY TẮC SỬ DỤNG BIẾN MÔI TRƯỜNG
* Luôn dùng `{{baseUrl}}` thay vì gõ cứng `http://localhost:8080`.
* Với các API cần xác thực: thêm header `Authorization: Bearer {{bearerToken}}`.
* Với các API nhận ID từ URL: dùng `{{requestId}}`, `:id`, hoặc gõ thẳng mock ID hợp lệ.
