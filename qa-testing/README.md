# 📁 qa-testing — Bộ Kiểm Thử Hộp Đen (Black-box Data-Driven Testing)

> **Dự án:** Hệ thống Điều phối Cứu hộ Lũ lụt  
> **Module:** Auth & RBAC (Epic 1) · Kho bãi & Cứu trợ (Epic 5)  
> **Phụ trách:** Anh (KCPM-88, 89, 90) · Danh (KCPM-98, 99)  
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
| Nhập kho nhu yếu phẩm (KCPM-98) | `python qa-testing/scripts/run_inventory.py` | `reports/REPORT_INVENTORY_IMPORT.xlsx` |
| Xuất kho cứu trợ & Chặn âm kho (KCPM-99) | `python qa-testing/scripts/run_distribution.py` | `reports/REPORT_DISTRIBUTION_EXPORT.xlsx` |

---

## Quy tắc đặt tên file (Bắt buộc)

| Loại file | Quy tắc đặt tên | Ví dụ |
|:---|:---|:---|
| Plan Excel | `PLAN_<MODULE>_<FEATURE>.xlsx` | `PLAN_AUTH_CHANGE_PASSWORD.xlsx` |
| Dữ liệu CSV | `<module>_<feature>_data.csv` | `auth_change_password_data.csv` |
| Script Runner | `run_<feature>.py` | `run_change_password.py` |
| Báo cáo kết quả | `REPORT_<MODULE>_<FEATURE>.xlsx` | `REPORT_AUTH_LOGIN.xlsx` |

---

## Lưu ý quan trọng

> [!IMPORTANT]
> File trong thư mục `reports/` được **tự động sinh ra bởi script**. Không chỉnh sửa tay — mọi thay đổi sẽ bị ghi đè lần chạy tiếp theo.

> [!WARNING]
> File CSV phải được lưu với mã hóa **UTF-8** (không phải UTF-8 BOM hay ANSI). Nếu mở và lưu lại bằng Excel trên Windows, hãy chọn `Save As → CSV UTF-8 (Comma delimited)`.

> [!NOTE]
> Thư mục `reports/` đã được thêm vào `.gitignore`. Chỉ commit các file trong `plans/`, `data/`, và `scripts/`.

