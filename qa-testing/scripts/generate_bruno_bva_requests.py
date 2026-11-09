# -*- coding: utf-8 -*-
"""
Script tạo các file request kiểm thử BVA chuẩn Bruno (.yml)
vào thư mục: Flood Rescue Coordination & Relief Management API/RescueRequest
"""
import os
import yaml

TARGET_DIR = os.path.abspath("Flood-Rescue-Coordination-and-Relief-Management-System/Flood Rescue Coordination & Relief Management API/RescueRequest")

note_1000 = "CuuTroKhanCap_" + "A" * (1000 - 14)
note_1001 = "CuuTroKhanCap_" + "A" * (1001 - 14)

bva_bruno_requests = [
    {
        "filename": "POST -bva-people-min-1.yml",
        "seq": 17,
        "name": "BVA TC04 - POST / (Biên Min: 1 người - 200 OK)",
        "body": {
            "citizenName": "Lê Văn D",
            "citizenPhone": "0987654324",
            "addressText": "Xã Đại Lộc, Quảng Nam",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": 1,
            "urgencyLevel": "MEDIUM",
            "description": "Tôi ở một mình cần trợ giúp"
        },
        "exp_code": 200,
        "test_desc": "Kiểm tra biên dưới hợp lệ (Min = 1 người) -> HTTP 200/201"
    },
    {
        "filename": "POST -bva-people-max-50.yml",
        "seq": 18,
        "name": "BVA TC08 - POST / (Biên Max: 50 người - 200 OK)",
        "body": {
            "citizenName": "Vũ Thị H",
            "citizenPhone": "0987654328",
            "addressText": "Trường Tiểu học Đại Lộc",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": 50,
            "urgencyLevel": "HIGH",
            "description": "Điểm sơ tán dã chiến 50 người ngập lụt"
        },
        "exp_code": 200,
        "test_desc": "Kiểm tra biên trên hợp lệ (Max = 50 người) -> HTTP 200/201"
    },
    {
        "filename": "POST -bva-people-err-0.yml",
        "seq": 19,
        "name": "BVA TC03 - POST / (Biên lỗi Min-1: 0 người - 400 Bad Request)",
        "body": {
            "citizenName": "Trần Thị C",
            "citizenPhone": "0987654323",
            "addressText": "Khu phố 3, Đại Lộc",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": 0,
            "urgencyLevel": "NORMAL",
            "description": "Gia đình đang bị cô lập"
        },
        "exp_code": 400,
        "test_desc": "Chặn lỗi dưới biên dưới (0 người) -> HTTP 400 Bad Request"
    },
    {
        "filename": "POST -bva-people-err-negative.yml",
        "seq": 20,
        "name": "BVA TC01 - POST / (Biên lỗi số âm: -1 người - 400 Bad Request)",
        "body": {
            "citizenName": "Nguyễn Văn A",
            "citizenPhone": "0987654321",
            "addressText": "Xã Đại Cường",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": -1,
            "urgencyLevel": "HIGH",
            "description": "Nước ngập đến nóc nhà"
        },
        "exp_code": 400,
        "test_desc": "Chặn lỗi số người âm (-1) -> HTTP 400 Bad Request"
    },
    {
        "filename": "POST -bva-people-err-51.yml",
        "seq": 21,
        "name": "BVA TC09 - POST / (Biên lỗi Max+1: 51 người - 400 Bad Request)",
        "body": {
            "citizenName": "Bùi Văn I",
            "citizenPhone": "0987654329",
            "addressText": "Khu công nghiệp Đại Lộc",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": 51,
            "urgencyLevel": "CRITICAL",
            "description": "Nhóm 51 công nhân nhà máy bị cô lập"
        },
        "exp_code": 400,
        "test_desc": "Chặn lỗi vượt quá biên trên (51 người) -> HTTP 400 Bad Request"
    },
    {
        "filename": "POST -bva-gps-vn-extreme-north.yml",
        "seq": 22,
        "name": "BVA TC12 - POST / (Biên GPS cực Bắc VN: Lũng Cú - 200 OK)",
        "body": {
            "citizenName": "Vàng A M",
            "citizenPhone": "0987654332",
            "addressText": "Lũng Cú, Đồng Văn, Hà Giang",
            "locationLat": 23.3900,
            "locationLng": 105.3200,
            "numberOfPeople": 4,
            "urgencyLevel": "HIGH",
            "description": "Lũng Cú sạt lở lũ quét cô lập bản"
        },
        "exp_code": 200,
        "test_desc": "Kiểm tra tọa độ biên giới cực Bắc Việt Nam (Lat 23.39) -> HTTP 200"
    },
    {
        "filename": "POST -bva-gps-vn-extreme-south.yml",
        "seq": 23,
        "name": "BVA TC13 - POST / (Biên GPS cực Nam VN: Cà Mau - 200 OK)",
        "body": {
            "citizenName": "Nguyễn Văn N",
            "citizenPhone": "0987654333",
            "addressText": "Mũi Cà Mau, Ngọc Hiển, Cà Mau",
            "locationLat": 8.1800,
            "locationLng": 104.8300,
            "numberOfPeople": 4,
            "urgencyLevel": "MEDIUM",
            "description": "Mũi Cà Mau triều cường ngập đê"
        },
        "exp_code": 200,
        "test_desc": "Kiểm tra tọa độ biên giới cực Nam Việt Nam (Lat 8.18) -> HTTP 200"
    },
    {
        "filename": "POST -bva-gps-outside-vn-north.yml",
        "seq": 24,
        "name": "BVA TC16 - POST / (Biên lỗi ngoài VN phía Bắc: Lat 24.50 - 400)",
        "body": {
            "citizenName": "Lý Văn R",
            "citizenPhone": "0987654336",
            "addressText": "Vị trí ngoài biên giới phía Bắc",
            "locationLat": 24.5000,
            "locationLng": 105.0000,
            "numberOfPeople": 4,
            "urgencyLevel": "LOW",
            "description": "Khu vực ngoài biên giới phía Bắc"
        },
        "exp_code": 400,
        "test_desc": "Chặn tọa độ nằm ngoài lãnh thổ Việt Nam phía Bắc -> HTTP 400"
    },
    {
        "filename": "POST -bva-gps-outside-vn-west.yml",
        "seq": 25,
        "name": "BVA TC18 - POST / (Biên lỗi ngoài VN phía Tây: Lng 101.50 - 400)",
        "body": {
            "citizenName": "Somsak T",
            "citizenPhone": "0987654338",
            "addressText": "Vị trí ngoài biên giới phía Tây",
            "locationLat": 16.0000,
            "locationLng": 101.5000,
            "numberOfPeople": 4,
            "urgencyLevel": "LOW",
            "description": "Vị trí ngoài lãnh thổ phía Tây"
        },
        "exp_code": 400,
        "test_desc": "Chặn tọa độ nằm ngoài lãnh thổ Việt Nam phía Tây -> HTTP 400"
    },
    {
        "filename": "POST -bva-note-len-0.yml",
        "seq": 26,
        "name": "BVA TC23 - POST / (Biên Note rỗng: 0 ký tự - 200 OK)",
        "body": {
            "citizenName": "Phan Văn Y",
            "citizenPhone": "0987654343",
            "addressText": "Thị trấn Ái Nghĩa, Đại Lộc",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": 4,
            "urgencyLevel": "MEDIUM",
            "description": ""
        },
        "exp_code": 200,
        "test_desc": "Cho phép để trống mô tả khẩn cấp (0 ký tự) -> HTTP 200"
    },
    {
        "filename": "POST -bva-note-len-1000.yml",
        "seq": 27,
        "name": "BVA TC27 - POST / (Biên Note tối đa: 1000 ký tự - 200 OK)",
        "body": {
            "citizenName": "Tạ Văn CC",
            "citizenPhone": "0987654347",
            "addressText": "Thôn Phú Lộc, Đại Lộc",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": 4,
            "urgencyLevel": "HIGH",
            "description": note_1000
        },
        "exp_code": 200,
        "test_desc": "Kiểm tra biên trên hợp lệ cho độ dài mô tả (đúng 1000 ký tự) -> HTTP 200"
    },
    {
        "filename": "POST -bva-note-len-1001-err.yml",
        "seq": 28,
        "name": "BVA TC28 - POST / (Biên lỗi Note vượt Max: 1001 ký tự - 400)",
        "body": {
            "citizenName": "Chu Văn DD",
            "citizenPhone": "0987654348",
            "addressText": "Thôn An Tây, Đại Lộc",
            "locationLat": 16.0544,
            "locationLng": 108.2022,
            "numberOfPeople": 4,
            "urgencyLevel": "MEDIUM",
            "description": note_1001
        },
        "exp_code": 400,
        "test_desc": "Chặn mô tả vượt quá độ dài tối đa (1001 ký tự) -> HTTP 400 Bad Request"
    },
    {
        "filename": "POST -bva-combo-max.yml",
        "seq": 29,
        "name": "BVA TC30 - POST / (Phối hợp đa biên Max: 50 người, 1000 ký tự, Cực Đông - 200)",
        "body": {
            "citizenName": "Trịnh Văn FF",
            "citizenPhone": "0987654350",
            "addressText": "Bán đảo Đầm Môn, Khánh Hòa",
            "locationLat": 12.6500,
            "locationLng": 109.4600,
            "numberOfPeople": 50,
            "urgencyLevel": "CRITICAL",
            "description": note_1000
        },
        "exp_code": 200,
        "test_desc": "Kiểm tra phối hợp đa biên: People=50 + Note=1000 + Tọa độ cực Đông VN -> HTTP 200"
    }
]

import json

for item in bva_bruno_requests:
    fpath = os.path.join(TARGET_DIR, item["filename"])
    body_json_str = json.dumps(item["body"], ensure_ascii=False, indent=2)

    if item["exp_code"] == 200:
        test_script = f"""test("{item['test_desc']}", function () {{
    expect(res.getStatus()).to.be.oneOf([200, 201]);
    if (res.getBody() && res.getBody().data) {{
        const reqId = res.getBody().data.id || res.getBody().data.requestId;
        if (reqId) {{
            bru.setVar("rescueRequestId", reqId);
        }}
    }}
}});"""
    else:
        test_script = f"""test("{item['test_desc']}", function () {{
    expect(res.getStatus()).to.equal({item['exp_code']});
    const body = res.getBody();
    if (body) {{
        expect(body.success).to.be.false;
    }}
}});"""

    # Tạo nội dung YAML đúng chuẩn Bruno OpenCollection / Bruno CLI
    content = f"""info:
  name: "{item['name']}"
  type: http
  seq: {item['seq']}

http:
  method: POST
  url: "{{{{baseUrl}}}}/api/v1/rescue-requests"
  headers:
    - name: Content-Type
      value: application/json
  body:
    type: json
    data: |-
{chr(10).join('      ' + line for line in body_json_str.splitlines())}
  auth: inherit

runtime:
  scripts:
    - type: after-response
      code: |-
{chr(10).join('        ' + line for line in test_script.splitlines())}

settings:
  encodeUrl: true
  timeout: 0
  followRedirects: true
  maxRedirects: 5
  forwardAuthorizationHeader: false
"""
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[OK] Da tao Bruno request: {item['filename']} (seq: {item['seq']})")
