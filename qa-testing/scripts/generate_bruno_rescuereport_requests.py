# -*- coding: utf-8 -*-
"""
Tạo các ca kiểm thử bổ sung cho module RescueReport trong Bruno:
Endpoint: POST /api/v1/rescue-reports
"""
import os
import json

TARGET_DIR = os.path.abspath("Flood-Rescue-Coordination-and-Relief-Management-System/Flood Rescue Coordination & Relief Management API/RescueReport")

reports_cases = [
    {
        "filename": "POST -bva-rescued-count-0.yml",
        "seq": 2,
        "name": "TC_REPORT_02 - POST / (Biên Min: 0 người được cứu - 200 OK)",
        "body": {
            "assignmentId": "6ad65252e38bd958953c0001",
            "rescuedPeopleCount": 0,
            "actualCondition": "Tiếp cận điểm ngập, không có nạn nhân bị kẹt, chỉ cấp phát nhu yếu phẩm",
            "detailedNote": "Hộ dân đã tự di tản lên tầng cao, đã tiếp tế 2 thùng mì tôm",
            "actualDistributedItems": [
                {
                    "itemId": "item-01",
                    "itemName": "Mì tôm Hảo Hảo",
                    "unit": "Thùng",
                    "quantity": 2
                }
            ]
        },
        "exp_code": 200,
        "test_desc": "Cho phép nộp báo cáo với 0 người cần cứu hộ (chỉ tiếp tế) -> HTTP 200"
    },
    {
        "filename": "POST -bva-rescued-count-max-50.yml",
        "seq": 3,
        "name": "TC_REPORT_03 - POST / (Biên Max: 50 người giải cứu thành công - 200 OK)",
        "body": {
            "assignmentId": "6ad65252e38bd958953c0001",
            "rescuedPeopleCount": 50,
            "actualCondition": "Điểm trường ngập nóc, nước chảy xiết",
            "detailedNote": "Dùng cano sơ tán toàn bộ 50 người dân đến nơi tập kết an toàn",
            "actualDistributedItems": [
                {
                    "itemId": "item-01",
                    "itemName": "Mì tôm Hảo Hảo",
                    "unit": "Thùng",
                    "quantity": 25
                },
                {
                    "itemId": "item-02",
                    "itemName": "Nước khoáng Lavie 500ml",
                    "unit": "Lốc",
                    "quantity": 20
                }
            ]
        },
        "exp_code": 200,
        "test_desc": "Nộp báo cáo giải cứu số lượng tối đa 50 người thành công -> HTTP 200"
    },
    {
        "filename": "POST -empty-items.yml",
        "seq": 4,
        "name": "TC_REPORT_04 - POST / (Báo cáo chỉ cứu người không cấp phát hàng - 200 OK)",
        "body": {
            "assignmentId": "6ad65252e38bd958953c0001",
            "rescuedPeopleCount": 3,
            "actualCondition": "Nước chảy xiết sạt lở nguy hiểm",
            "detailedNote": "Ưu tiên đưa khẩn cấp 3 người đi bệnh viện, không mang hàng cứu trợ",
            "actualDistributedItems": []
        },
        "exp_code": 200,
        "test_desc": "Cho phép danh sách hàng phân phối rỗng khi chỉ thực hiện cứu người -> HTTP 200"
    }
]

for item in reports_cases:
    fpath = os.path.join(TARGET_DIR, item["filename"])
    body_json_str = json.dumps(item["body"], ensure_ascii=False, indent=2)

    test_script = f"""test("{item['test_desc']}", function () {{
    expect(res.getStatus()).to.be.oneOf([200, 201]);
    const body = res.getBody();
    expect(body.success).to.be.true;
    expect(body.data.rescuedPeopleCount).to.equal({item['body']['rescuedPeopleCount']});
}});"""

    content = f"""info:
  name: "{item['name']}"
  type: http
  seq: {item['seq']}

http:
  method: POST
  url: "{{{{baseUrl}}}}/api/v1/rescue-reports"
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
    print(f"[OK] Da tao RescueReport request: {item['filename']} (seq: {item['seq']})")
