# ⚙️ scripts/ — Script Thực Thi Kiểm Thử & Xuất Báo Cáo

Thư mục này chứa các script Python chạy kiểm thử tự động theo mô hình Data-Driven Testing và xuất kết quả ra file Excel báo cáo chuẩn định dạng.

---

## Danh sách Script

| File | Đọc dữ liệu từ | Xuất báo cáo ra | Subtask |
|:---|:---|:---|:---|
| `run_change_password.py` | `data/auth_change_password_data.csv` | `reports/REPORT_AUTH_CHANGE_PASSWORD.xlsx` | KCPM-88 |
| `run_login.py` | `data/auth_login_data.csv` | `reports/REPORT_AUTH_LOGIN.xlsx` | KCPM-89 |
| `run_rbac.py` | `data/auth_rbac_data.csv` | `reports/REPORT_AUTH_RBAC.xlsx` | KCPM-90 |

---

## Cách chạy

```bash
# Chạy từng chức năng riêng lẻ (từ thư mục gốc của dự án):
python qa-testing/scripts/run_change_password.py
python qa-testing/scripts/run_login.py
python qa-testing/scripts/run_rbac.py
```

**Yêu cầu môi trường:**
- Python 3.8+
- Thư viện `openpyxl`: `pip install openpyxl`
- **Không cần bật backend** — Script mô phỏng logic nghiệp vụ nội bộ (Black-box simulation).

---

## Chuẩn Format File Script (Template bắt buộc)

Mỗi file script **phải tuân theo cấu trúc sau** để đảm bảo tính đồng nhất:

```python
# 1. IMPORTS & UTF-8 CONFIG
import os, sys, time
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
import openpyxl
from openpyxl.styles import ...

# 2. CONSTANTS (đường dẫn file)
DATA_FILE   = 'qa-testing/data/<ten_file>.csv'
REPORT_FILE = 'qa-testing/reports/REPORT_<TEN>.xlsx'

# 3. STYLING CONSTANTS (giữ nguyên, không thay đổi màu sắc)
HEADER_FONT  = Font(name='Segoe UI', size=10, bold=True, color='FFFFFF')
HEADER_FILL  = PatternFill(start_color='1F497D', ...)
PASS_FILL    = PatternFill(start_color='E2EFDA', ...)  # Xanh lá nhạt
FAIL_FILL    = PatternFill(start_color='FCE4D6', ...)  # Cam đỏ nhạt

# 4. SIMULATE FUNCTION (logic nghiệp vụ)
def simulate(...):
    """Mô phỏng chính xác logic của Service.java"""
    ...

# 5. EXPORT FUNCTIONS
def _set(ws, row, col, val, ...):  # Helper ghi cell
def _auto_width(ws):               # Tự điều chỉnh độ rộng cột

# 6. RUN FUNCTION (điểm thực thi chính)
def run():
    # 6a. Đọc CSV
    # 6b. Chạy từng dòng qua simulate()
    # 6c. In tiến độ ra console
    # 6d. Xuất Excel 2 Sheet:
    #     Sheet 1: Dashboard Tổng Quan (Summary + Rubric)
    #     Sheet 2: Chi Tiết Kết Quả (Bảng từng test case)

if __name__ == '__main__':
    run()
```

---

## Chuẩn Format File Excel Báo Cáo Đầu Ra (Report Output)

Mỗi file Report Excel xuất ra **phải có đúng 2 Sheet**:

### Sheet 1: `Dashboard Tổng Quan`
```
Dòng 1  : Tiêu đề báo cáo (TITLE_FONT - to đậm xanh navy)
Dòng 2  : Thông tin module + ngày giờ chạy (font nhỏ nghiêng xám)
Dòng 4  : Tiêu đề bảng 1 "THỐNG KÊ TỔNG QUAN"
Dòng 5  : Header (nền navy, chữ trắng)
Dòng 6-10: Các chỉ số: Tổng TC | PASS | FAIL | Tỉ lệ % | Thời gian
Dòng 13 : Tiêu đề bảng 2 "ĐÁNH GIÁ TIÊU CHÍ RUBRIC"
Dòng 14 : Header (nền navy, chữ trắng)
Dòng 15+: Từng tiêu chí và trạng thái đạt/không đạt
```

### Sheet 2: `Chi Tiết Kết Quả`
```
Dòng 1  : Tiêu đề bảng chi tiết
Dòng 2  : Chú thích
Dòng 4  : Header các cột (nền navy, chữ trắng)
Dòng 5+ : Từng dòng test case với màu:
           - Cột KẾT QUẢ = PASS → nền xanh (#E2EFDA), chữ xanh đậm (#276A3C)
           - Cột KẾT QUẢ = FAIL → nền cam (#FCE4D6), chữ đỏ đậm (#9C0006)
```

---

## Lưu ý khi thêm script cho thành viên khác

> [!IMPORTANT]
> **Mỗi Epic / thành viên tạo file script riêng của mình**, không chỉnh sửa script của người khác:
> - Lâm Khiêm (Epic 2): Tạo `run_sos_request.py`
> - Phạm Minh Dũng (Epic 3): Tạo `run_coordination.py`
> - Nguyễn Bảo (Epic 4): Tạo `run_team_vehicles.py`
> - Phan Quốc Danh (Epic 5): Tạo `run_warehouse.py`

> [!TIP]
> Copy file `run_change_password.py` làm template rồi chỉnh phần `simulate()`, `DATA_FILE`, `REPORT_FILE` và nội dung Rubric. Phần styling và _helper function có thể giữ nguyên 100%.

> [!WARNING]
> Tên biến trong hàm `simulate()` phải **phản ánh đúng tên tham số trong class Java** (Controller/Service) để dễ đối chiếu khi báo cáo. Ví dụ: `old_pass` → `oldPassword` trong `ChangePasswordRequest.java`.

