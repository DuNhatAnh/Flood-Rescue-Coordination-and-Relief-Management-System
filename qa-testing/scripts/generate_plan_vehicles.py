# -*- coding: utf-8 -*-
"""
KCPM-96: Script khởi tạo Kế hoạch kiểm thử Excel (EP, BVA & Decision Table)
và tập dữ liệu kiểm thử CSV cho Quản lý Phương tiện cứu hộ
(POST /api/v1/vehicles & PUT /api/v1/vehicles/{id}).
"""

import os
import sys
import csv
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# Thư mục gốc qa-testing
QA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
PLANS_DIR = os.path.join(QA_DIR, 'plans')
DATA_DIR = os.path.join(QA_DIR, 'data')
REPORTS_DIR = os.path.join(QA_DIR, 'reports')

os.makedirs(PLANS_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(REPORTS_DIR, exist_ok=True)

PLAN_FILE = os.path.join(PLANS_DIR, 'PLAN_VEHICLES_MANAGEMENT.xlsx')
CSV_FILE = os.path.join(DATA_DIR, 'vehicles_management_data.csv')

# Styling chuẩn Segoe UI thống nhất toàn dự án
FONT_NAME = 'Segoe UI'
HEADER_FONT = Font(name=FONT_NAME, size=10, bold=True, color='FFFFFF')
HEADER_FILL = PatternFill(start_color='1F497D', end_color='1F497D', fill_type='solid') # Xanh Navy đậm
TITLE_FONT  = Font(name=FONT_NAME, size=13, bold=True, color='1F497D')
SUB_FONT    = Font(name=FONT_NAME, size=11, bold=True, color='1F497D')
NORMAL_FONT = Font(name=FONT_NAME, size=9)
BOLD_FONT   = Font(name=FONT_NAME, size=9, bold=True)
ITALIC_FONT = Font(name=FONT_NAME, size=9, italic=True, color='595959')

PASS_FILL   = PatternFill(start_color='E2EFDA', end_color='E2EFDA', fill_type='solid')
FAIL_FILL   = PatternFill(start_color='FCE4D6', end_color='FCE4D6', fill_type='solid')
PASS_FONT   = Font(name=FONT_NAME, size=9, bold=True, color='276A3C')
FAIL_FONT   = Font(name=FONT_NAME, size=9, bold=True, color='9C0006')

THIN_BORDER = Border(
    left=Side(style='thin', color='D9D9D9'), right=Side(style='thin', color='D9D9D9'),
    top=Side(style='thin', color='D9D9D9'),  bottom=Side(style='thin', color='D9D9D9')
)

def set_cell(ws, row, col, val, font=None, fill=None, align=None, border=True):
    cell = ws.cell(row=row, column=col, value=val)
    if font: cell.font = font
    if fill: cell.fill = fill
    if align: cell.alignment = align
    if border: cell.border = THIN_BORDER
    return cell

def auto_fit_columns(ws, min_w=12, max_w=50):
    for col in ws.columns:
        max_len = max((len(str(c.value or '')) for c in col if c.row > 2), default=10)
        col_letter = get_column_letter(col[0].column)
        ws.column_dimensions[col_letter].width = min(max(max_len + 3, min_w), max_w)

# Danh sách 26 ca kiểm thử chi tiết bao phủ EP, BVA và 8 Quy tắc Bảng Quyết Định (Decision Table)
TEST_CASES = [
    # --- Nhóm 1: BVA Sức chứa chở người (Capacity) (Min=1, Nominal=6, Max=20; Lỗi: 0, -1, 21, 25, định dạng) ---
    {
        "id": "TC_VEH_01", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-001.01", "capacity": "-1",
        "tech": "BVA", "rule": "R4 (Sức chứa <=0)", "boundary": "Min - 2 (Số âm)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Sức chứa phương tiện phải lớn hơn hoặc bằng 1"
    },
    {
        "id": "TC_VEH_02", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-001.02", "capacity": "0",
        "tech": "BVA", "rule": "R4 (Sức chứa <=0)", "boundary": "Min - 1 (Dưới biên dưới)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Sức chứa phương tiện phải lớn hơn hoặc bằng 1"
    },
    {
        "id": "TC_VEH_03", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "THUYEN", "plate": "43A-001.03", "capacity": "1",
        "tech": "BVA", "rule": "R1 (Tạo chuẩn)", "boundary": "Min (Tại biên dưới)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_04", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "THUYEN", "plate": "43A-001.04", "capacity": "2",
        "tech": "BVA", "rule": "R1 (Tạo chuẩn)", "boundary": "Min + 1 (Trên biên dưới)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_05", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-001.05", "capacity": "6",
        "tech": "EP/BVA", "rule": "R1 (Tạo chuẩn)", "boundary": "Nominal (Danh định chuẩn)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_06", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "XE_LOI_NUOC", "plate": "43A-001.06", "capacity": "19",
        "tech": "BVA", "rule": "R1 (Tạo chuẩn)", "boundary": "Max - 1 (Dưới biên trên)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_07", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "XE_LOI_NUOC", "plate": "43A-001.07", "capacity": "20",
        "tech": "BVA", "rule": "R1 (Tạo chuẩn)", "boundary": "Max (Tại biên trên)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_08", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "XE_LOI_NUOC", "plate": "43A-001.08", "capacity": "21",
        "tech": "BVA", "rule": "R3 (Quá tải >20/25)", "boundary": "Max + 1 (Vượt trần)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Sức chứa chở người không được vượt quá 20 người"
    },
    {
        "id": "TC_VEH_09", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "XE_LOI_NUOC", "plate": "43A-001.09", "capacity": "25",
        "tech": "BVA", "rule": "R3 (Quá tải >20/25)", "boundary": "Ngoại lệ đề bài (25)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Sức chứa chở người không được vượt quá 20 người"
    },
    {
        "id": "TC_VEH_10", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-001.10", "capacity": "NULL_VAL",
        "tech": "Validation", "rule": "R6 (Để trống)", "boundary": "Rỗng sức chứa",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Sức chứa phương tiện không được để trống"
    },
    {
        "id": "TC_VEH_11", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-001.11", "capacity": "SIX",
        "tech": "Validation", "rule": "R6 (Sai định dạng)", "boundary": "Sai kiểu dữ liệu (chữ)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Sức chứa phải là số nguyên"
    },

    # --- Nhóm 2: EP Phân vùng Loại xe (CANO, THUYEN, XE_LOI_NUOC, Ngoại lệ) ---
    {
        "id": "TC_VEH_12", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-002.01", "capacity": "8",
        "tech": "EP", "rule": "R1 (Tạo chuẩn)", "boundary": "Loại xe hợp lệ (CANO)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_13", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "THUYEN", "plate": "43A-002.02", "capacity": "4",
        "tech": "EP", "rule": "R1 (Tạo chuẩn)", "boundary": "Loại xe hợp lệ (THUYEN)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_14", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "XE_LOI_NUOC", "plate": "43A-002.03", "capacity": "15",
        "tech": "EP", "rule": "R1 (Tạo chuẩn)", "boundary": "Loại xe hợp lệ (XE_LOI_NUOC)",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_15", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "XE_DAP", "plate": "43A-002.04", "capacity": "1",
        "tech": "EP", "rule": "R2 (Sai loại xe)", "boundary": "Loại xe không hợp lệ",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Loại phương tiện không hợp lệ, chỉ chấp nhận CANO, THUYEN, XE_LOI_NUOC"
    },
    {
        "id": "TC_VEH_16", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "TRUC_THANG", "plate": "43A-002.05", "capacity": "6",
        "tech": "EP", "rule": "R2 (Sai loại xe)", "boundary": "Loại xe không hợp lệ",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Loại phương tiện không hợp lệ, chỉ chấp nhận CANO, THUYEN, XE_LOI_NUOC"
    },
    {
        "id": "TC_VEH_17", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "NULL_VAL", "plate": "43A-002.06", "capacity": "6",
        "tech": "Validation", "rule": "R6 (Để trống)", "boundary": "Trống loại xe",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Loại phương tiện không được để trống"
    },

    # --- Nhóm 3: Nghiệp vụ Biển số xe & Trùng lặp ---
    {
        "id": "TC_VEH_18", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-123.45", "capacity": "6",
        "tech": "Nghiệp vụ", "rule": "R1 (Tạo chuẩn)", "boundary": "Biển số mới hợp lệ",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_19", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "43A-999.99", "capacity": "6",
        "tech": "Nghiệp vụ", "rule": "R5 (Trùng biển)", "boundary": "Trùng biển số xe",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Biển số xe đã tồn tại trong hệ thống: 43A-999.99"
    },
    {
        "id": "TC_VEH_20", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "CANO", "plate": "NULL_VAL", "capacity": "6",
        "tech": "Validation", "rule": "R6 (Để trống)", "boundary": "Biển số xe để trống",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Biển số xe không được để trống"
    },

    # --- Nhóm 4: Cập nhật Phương tiện (PUT /api/v1/vehicles/{id}) ---
    {
        "id": "TC_VEH_21", "method": "PUT", "veh_id": "VEH-001",
        "type": "CANO", "plate": "43A-123.45", "capacity": "10",
        "tech": "Nghiệp vụ", "rule": "R7 (PUT Chuẩn)", "boundary": "Cập nhật xe ID tồn tại",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Cập nhật phương tiện thành công"
    },
    {
        "id": "TC_VEH_22", "method": "PUT", "veh_id": "VEH-NOT-FOUND",
        "type": "CANO", "plate": "43A-888.88", "capacity": "6",
        "tech": "Nghiệp vụ", "rule": "R8 (PUT ID Lạ)", "boundary": "Cập nhật ID không tồn tại",
        "exp_st": "FAIL", "exp_code": 404, "exp_ex": "ResourceNotFoundException",
        "exp_msg": "Không tìm thấy phương tiện ID: VEH-NOT-FOUND"
    },
    {
        "id": "TC_VEH_23", "method": "PUT", "veh_id": "VEH-001",
        "type": "CANO", "plate": "43A-123.45", "capacity": "25",
        "tech": "BVA", "rule": "R3 (Quá tải >20/25)", "boundary": "PUT vượt quá tải (25)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Sức chứa chở người không được vượt quá 20 người"
    },
    {
        "id": "TC_VEH_24", "method": "PUT", "veh_id": "VEH-001",
        "type": "CANO", "plate": "43A-999.99", "capacity": "6",
        "tech": "Nghiệp vụ", "rule": "R5 (Trùng biển)", "boundary": "PUT trùng biển số xe khác",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Biển số xe đã tồn tại trong hệ thống: 43A-999.99"
    },

    # --- Nhóm 5: Đa biên phối hợp (Robustness) ---
    {
        "id": "TC_VEH_25", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "XE_LOI_NUOC", "plate": "43A-555.01", "capacity": "20",
        "tech": "Robustness", "rule": "R1 (Tạo chuẩn)", "boundary": "Đa biên Max + Hợp lệ",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    },
    {
        "id": "TC_VEH_26", "method": "POST", "veh_id": "AUTO_GEN",
        "type": "THUYEN", "plate": "43A-555.02", "capacity": "1",
        "tech": "Robustness", "rule": "R1 (Tạo chuẩn)", "boundary": "Đa biên Min + Hợp lệ",
        "exp_st": "PASS", "exp_code": 201, "exp_ex": "NONE",
        "exp_msg": "Tạo phương tiện thành công"
    }
]

def export_csv():
    with open(CSV_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([
            "testCaseId", "method", "vehicleId", "vehicleType", "licensePlate",
            "capacity", "technique", "decisionRule", "boundaryType", "expectedStatus",
            "expectedHttpCode", "expectedException", "expectedMessage"
        ])
        for tc in TEST_CASES:
            writer.writerow([
                tc["id"], tc["method"], tc["veh_id"], tc["type"], tc["plate"],
                tc["capacity"], tc["tech"], tc["rule"], tc["boundary"], tc["exp_st"],
                tc["exp_code"], tc["exp_ex"], tc["exp_msg"]
            ])
    print(f"[OK] Da xuat CSV: {CSV_FILE}")

def export_plan_excel():
    wb = openpyxl.Workbook()

    # =========================================================================
    # SHEET 1: Phân Tích EP, BVA & Bảng Quyết Định
    # =========================================================================
    ws1 = wb.active
    ws1.title = "Phân Tích EP, BVA & Bảng QĐ"

    ws1['A1'] = "THIẾT KẾ KIỂM THỬ EP, BVA & BẢNG QUYẾT ĐỊNH (DECISION TABLE) - QUẢN LÝ PHƯƠNG TIỆN CỨU HỘ"
    ws1['A1'].font = TITLE_FONT
    ws1['A2'] = "Dự án: Hệ thống Điều phối Cứu hộ Lũ lụt | Module: Đội cứu hộ & Phương tiện (Epic 3) | Subtask: KCPM-96 | APIs: POST /api/v1/vehicles & PUT /api/v1/vehicles/{id}"
    ws1['A2'].font = ITALIC_FONT

    # --- Bảng 1: Phân vùng tương đương (EP) Loại phương tiện ---
    ws1['A4'] = "1. BẢNG PHÂN VÙNG TƯƠNG ĐƯƠNG (EP) - LOẠI PHƯƠNG TIỆN (VEHICLE TYPE)"
    ws1['A4'].font = SUB_FONT

    ep_headers = ["Phân Vùng Tương Đương", "Loại Dữ Liệu", "Giá Trị Đại Diện (Input)", "Phân Loại Miền", "Hành Vi Kỳ Vọng", "HTTP Code"]
    for col_idx, h in enumerate(ep_headers, 1):
        set_cell(ws1, 5, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    ep_rows = [
        ["EP_TYPE_01", "Ca nô cao tốc chuyên dụng ngập sâu", "CANO", "Valid (Hợp lệ)", "Tiếp nhận và đăng ký phương tiện cứu hộ", "201 Created"],
        ["EP_TYPE_02", "Thuyền nan / thuyền cứu hộ ngõ nhỏ", "THUYEN", "Valid (Hợp lệ)", "Tiếp nhận và đăng ký phương tiện cứu hộ", "201 Created"],
        ["EP_TYPE_03", "Xe lội nước lội bùn tải trọng lớn", "XE_LOI_NUOC", "Valid (Hợp lệ)", "Tiếp nhận và đăng ký phương tiện cứu hộ", "201 Created"],
        ["EP_TYPE_04", "Phương tiện không thuộc danh mục cứu hộ", "XE_DAP", "Invalid (Lỗi)", "Từ chối: Loại phương tiện không hợp lệ", "400 Bad Request"],
        ["EP_TYPE_05", "Phương tiện hàng không ngoài phân hệ", "TRUC_THANG", "Invalid (Lỗi)", "Từ chối: Loại phương tiện không hợp lệ", "400 Bad Request"],
        ["EP_TYPE_06", "Để trống loại phương tiện", "NULL_VAL (rỗng)", "Invalid (Lỗi)", "Từ chối: Loại phương tiện không được để trống", "400 Bad Request"]
    ]

    for r_idx, row in enumerate(ep_rows, 6):
        for c_idx, val in enumerate(row, 1):
            cell = set_cell(ws1, r_idx, c_idx, val, NORMAL_FONT)
            if c_idx in [1, 3, 4, 6]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if c_idx == 4:
                if 'Valid' in val:
                    cell.fill = PASS_FILL
                    cell.font = PASS_FONT
                else:
                    cell.fill = FAIL_FILL
                    cell.font = FAIL_FONT

    # --- Bảng 2: Phân tích giá trị biên (BVA) Sức chứa chở người (Capacity) ---
    start_sec2 = 6 + len(ep_rows) + 2
    ws1.cell(row=start_sec2, column=1, value="2. BẢNG PHÂN TÍCH GIÁ TRỊ BIÊN (BVA) - SỨC CHỨA CHỞ NGƯỜI (CAPACITY)").font = SUB_FONT

    bva_headers = ["Tham Số", "Điểm Biên BVA", "Công Thức / Cơ Sở", "Giá Trị Test", "Phân Loại Miền", "Hành Vi Hệ Thống Kỳ Vọng", "HTTP Code"]
    for col_idx, h in enumerate(bva_headers, 1):
        set_cell(ws1, start_sec2 + 1, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    bva_rows = [
        ["Sức chứa (capacity)", "Biên âm (Min - 2)", "capacity = -1 < 1", "-1", "Invalid (Lỗi)", "Chặn với lỗi: Sức chứa >= 1", "400 Bad Request"],
        ["Sức chứa (capacity)", "Dưới biên dưới (Min - 1)", "Min - 1 = 1 - 1 = 0", "0", "Invalid (Lỗi)", "Chặn với lỗi: Sức chứa >= 1", "400 Bad Request"],
        ["Sức chứa (capacity)", "Tại biên dưới (Min)", "Min = 1 (Xuồng cá nhân)", "1", "Valid (Biên Min)", "Đăng ký thành công phương tiện sức chứa 1 người", "201 Created"],
        ["Sức chứa (capacity)", "Trên biên dưới (Min + 1)", "Min + 1 = 1 + 1 = 2", "2", "Valid", "Đăng ký thành công phương tiện sức chứa 2 người", "201 Created"],
        ["Sức chứa (capacity)", "Danh định chuẩn (Nominal)", "Nominal = 6 (Ca nô tiêu chuẩn)", "6", "Valid (Nominal)", "Đăng ký thành công phương tiện sức chứa 6 người", "201 Created"],
        ["Sức chứa (capacity)", "Dưới biên trên (Max - 1)", "Max - 1 = 20 - 1 = 19", "19", "Valid", "Đăng ký thành công phương tiện sức chứa 19 người", "201 Created"],
        ["Sức chứa (capacity)", "Tại biên trên (Max)", "Max = 20 (Xe lội nước dã chiến)", "20", "Valid (Biên Max)", "Đăng ký thành công phương tiện sức chứa 20 người", "201 Created"],
        ["Sức chứa (capacity)", "Vượt biên trên (Max + 1)", "Max + 1 = 20 + 1 = 21", "21", "Invalid (Lỗi)", "Chặn với lỗi: Sức chứa <= 20 người", "400 Bad Request"],
        ["Sức chứa (capacity)", "Biên ngoại lệ đề bài", "capacity = 25 (Quá tải)", "25", "Invalid (Lỗi)", "Chặn với lỗi: Sức chứa <= 20 người", "400 Bad Request"],
        ["Sức chứa (capacity)", "Trống giá trị", "capacity = NULL / Rỗng", "NULL_VAL", "Invalid (Lỗi)", "Chặn với lỗi: Sức chứa không được để trống", "400 Bad Request"],
        ["Sức chứa (capacity)", "Sai kiểu dữ liệu", "Chuỗi ký tự 'SIX'", "SIX", "Invalid (Lỗi)", "Chặn với lỗi: Sức chứa phải là số nguyên", "400 Bad Request"]
    ]

    for r_idx, row in enumerate(bva_rows, start_sec2 + 2):
        for c_idx, val in enumerate(row, 1):
            cell = set_cell(ws1, r_idx, c_idx, val, NORMAL_FONT)
            if c_idx in [1, 2, 4, 5, 7]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if c_idx == 5:
                if 'Valid' in val:
                    cell.fill = PASS_FILL
                    cell.font = PASS_FONT
                else:
                    cell.fill = FAIL_FILL
                    cell.font = FAIL_FONT

    # --- Bảng 3: BẢNG QUYẾT ĐỊNH (DECISION TABLE) ---
    start_sec3 = start_sec2 + len(bva_rows) + 3
    ws1.cell(row=start_sec3, column=1, value="3. BẢNG QUYẾT ĐỊNH (DECISION TABLE) - MA TRẬN ĐĂNG KÝ & CẬP NHẬT PHƯƠNG TIỆN").font = SUB_FONT

    dt_headers = [
        "Điều Kiện / Hành Động Kỳ Vọng",
        "R1 (Tạo chuẩn)", "R2 (Sai loại xe)", "R3 (Quá tải >20/25)", "R4 (Sức chứa <=0)",
        "R5 (Trùng biển)", "R6 (Để trống)", "R7 (PUT Chuẩn)", "R8 (PUT ID Lạ)"
    ]
    for col_idx, h in enumerate(dt_headers, 1):
        set_cell(ws1, start_sec3 + 1, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    dt_rows = [
        ["C1: Loại xe hợp lệ (CANO, THUYEN, XE_LOI_NUOC)?", "Y", "N", "Y", "Y", "Y", "N (Rỗng)", "Y", "Y"],
        ["C2: Sức chứa hợp lệ biên an toàn [1 .. 20]?", "Y", "Y", "N (>20)", "N (<=0)", "Y", "N (Rỗng)", "Y", "Y"],
        ["C3: Biển số xe hợp lệ & Chưa tồn tại (Unique)?", "Y", "Y", "Y", "Y", "N (Trùng)", "N (Rỗng)", "Y", "Y"],
        ["C4: Phương tiện tồn tại trong hệ thống (Áp dụng PUT)?", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A", "Y", "N (404)"],
        ["A1: HÀNH ĐỘNG KỲ VỌNG", "201 Created", "400 BadRequest", "400 BadRequest", "400 BadRequest", "400 BadRequest", "400 BadRequest", "200 OK", "404 NotFound"],
        ["A2: Đánh Giá Kết Quả Kiểm Thử", "PASS", "FAIL (Chặn)", "FAIL (Chặn)", "FAIL (Chặn)", "FAIL (Chặn)", "FAIL (Chặn)", "PASS", "FAIL (Chặn)"]
    ]

    for r_idx, row in enumerate(dt_rows, start_sec3 + 2):
        for c_idx, val in enumerate(row, 1):
            cell = set_cell(ws1, r_idx, c_idx, val, NORMAL_FONT)
            if c_idx >= 2:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if r_idx == start_sec3 + 7: # Dòng Đánh Giá Kết Quả
                if "PASS" in val:
                    cell.fill = PASS_FILL
                    cell.font = PASS_FONT
                else:
                    cell.fill = FAIL_FILL
                    cell.font = FAIL_FONT

    auto_fit_columns(ws1)

    # =========================================================================
    # SHEET 2: Ma Trận Test Case
    # =========================================================================
    ws2 = wb.create_sheet(title="Ma Trận Test Case")

    ws2['A1'] = "MA TRẬN CA KIỂM THỬ EP, BVA & DECISION TABLE - QUẢN LÝ PHƯƠNG TIỆN CỨU HỘ"
    ws2['A1'].font = TITLE_FONT
    ws2['A2'] = "Chi tiết 26 test cases: Phân vùng loại xe, Biên sức chứa (1-20, ngoại lệ 0, -1, 25), Ma trận Decision Table R1-R8, Bắt trùng biển số & Cập nhật PUT"
    ws2['A2'].font = ITALIC_FONT

    matrix_headers = [
        "Mã Test Case", "HTTP Method", "Mã Xe (ID)", "Loại Phương Tiện",
        "Biển Số Xe", "Sức Chứa", "Kỹ Thuật", "Quy Tắc Quyết Định", "Phân Loại BVA / EP",
        "Kết Quả Mong Đợi", "HTTP Code Kỳ Vọng", "Exception Kỳ Vọng", "Thông Báo / Ghi Chú Kỳ Vọng"
    ]

    for col_idx, h in enumerate(matrix_headers, 1):
        set_cell(ws2, 4, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    for r_idx, tc in enumerate(TEST_CASES, 5):
        row_vals = [
            tc["id"], tc["method"], tc["veh_id"], tc["type"],
            tc["plate"], tc["capacity"], tc["tech"], tc["rule"], tc["boundary"],
            tc["exp_st"], tc["exp_code"], tc["exp_ex"], tc["exp_msg"]
        ]

        for col_idx, val in enumerate(row_vals, 1):
            cell = set_cell(ws2, r_idx, col_idx, val, NORMAL_FONT)
            if col_idx in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if col_idx == 10: # Kết Quả Mong Đợi
                if val == "PASS":
                    cell.fill = PASS_FILL
                    cell.font = PASS_FONT
                else:
                    cell.fill = FAIL_FILL
                    cell.font = FAIL_FONT

    auto_fit_columns(ws2)

    wb.save(PLAN_FILE)
    print(f"[OK] Da xuat Plan Excel: {PLAN_FILE}")

if __name__ == '__main__':
    export_csv()
    export_plan_excel()
