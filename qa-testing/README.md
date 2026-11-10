# 📁 qa-testing — Bộ Kiểm Thử Hộp Đen (Black-box Data-Driven Testing)

> **Dự án:** Hệ thống Điều phối Cứu hộ Lũ lụt  
> **Module:** Auth, Rescue & Safety Management  
> **Kỹ thuật áp dụng:** BVA · Phân vùng tương đương (EP) · Bảng quyết định (Decision Table)

---

## Cấu trúc thư mục

```
qa-testing/
├── plans/      # File Excel thiết kế Plan kiểm thử (Tính BVA, EP, Decision Table)
├── data/       # File CSV dữ liệu đầu vào (máy đọc để chạy test)
├── scripts/    # Script Python thực thi test và xuất báo cáo
└── reports/    # File Excel báo cáo kết quả sau khi chạy (tự động sinh ra)
```

---

## Luồng hoạt động

```
plans/*.xlsx  →  data/*.csv  →  scripts/run_*.py  →  reports/*.xlsx
   (Thiết kế)     (Dữ liệu)       (Thực thi)          (Báo cáo)
```

---

## Cách chạy kiểm thử

> **Yêu cầu:** Python 3.x + thư viện `openpyxl`  
> Cài một lần: `pip install openpyxl`

| Chức năng | Lệnh chạy | File báo cáo sinh ra |
|:---|:---|:---|
| Đổi mật khẩu (KCPM-88) | `python qa-testing/scripts/run_change_password.py` | `reports/REPORT_AUTH_CHANGE_PASSWORD.xlsx` |
| Đăng nhập (KCPM-89) | `python qa-testing/scripts/run_login.py` | `reports/REPORT_AUTH_LOGIN.xlsx` |
| Phân quyền RBAC (KCPM-90) | `python qa-testing/scripts/run_rbac.py` | `reports/REPORT_AUTH_RBAC.xlsx` |
| Yêu cầu cứu hộ (BVA) | `python qa-testing/scripts/run_rescue_request.py` | `reports/REPORT_CITIZEN_RESCUE_REQUEST.xlsx` |
| Quét radar điểm nguy hiểm (KCPM-93) | `python qa-testing/scripts/run_danger_point.py` | `reports/REPORT_DANGER_POINT_RADAR.xlsx` |
| Báo an toàn & Theo dõi đơn (EP) | `python qa-testing/scripts/run_safety_report.py` | `reports/REPORT_CITIZEN_SAFETY_REPORT.xlsx` |
| Điều phối đơn cứu nạn (KCPM-95) | `python qa-testing/scripts/run_coordination_dispatch.py` | `reports/REPORT_COORDINATION_DISPATCH.xlsx` |
| Quản lý Phương tiện EP, BVA & Decision Table (KCPM-96) | `python qa-testing/scripts/run_vehicles.py` | `reports/REPORT_VEHICLES_MANAGEMENT.xlsx` |

---

## Quy tắc đặt tên file (Bắt buộc)

| Loại file | Quy tắc đặt tên | Ví dụ |
|:---|:---|:---|
| Plan Excel | `PLAN_<MODULE>_<FEATURE>.xlsx` | `PLAN_CITIZEN_SAFETY_REPORT.xlsx` |
| Dữ liệu CSV | `<module>_<feature>_data.csv` | `citizen_safety_report_data.csv` |
| Script Runner | `run_<feature>.py` | `run_safety_report.py` |
| Báo cáo kết quả | `REPORT_<MODULE>_<FEATURE>.xlsx` | `REPORT_CITIZEN_SAFETY_REPORT.xlsx` |

---

## Lưu ý quan trọng

> [!IMPORTANT]
> File trong thư mục `reports/` được **tự động sinh ra bởi script**. Không chỉnh sửa tay — mọi thay đổi sẽ bị ghi đè lần chạy tiếp theo.

> [!WARNING]
> File CSV phải được lưu với mã hóa **UTF-8** (không phải UTF-8 BOM hay ANSI). Nếu mở và lưu lại bằng Excel trên Windows, hãy chọn `Save As → CSV UTF-8 (Comma delimited)`.
