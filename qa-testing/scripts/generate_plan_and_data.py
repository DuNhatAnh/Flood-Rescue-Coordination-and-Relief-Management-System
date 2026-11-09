# -*- coding: utf-8 -*-
"""
Script khởi tạo dữ liệu kiểm thử CSV và Kế hoạch kiểm thử Excel (BVA)
cho API POST /api/v1/rescue-requests.
"""
import os
import sys
import csv
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# Đường dẫn thư mục
QA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
PLANS_DIR = os.path.join(QA_DIR, 'plans')
DATA_DIR = os.path.join(QA_DIR, 'data')
REPORTS_DIR = os.path.join(QA_DIR, 'reports')

os.makedirs(PLANS_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(REPORTS_DIR, exist_ok=True)

CSV_FILE = os.path.join(DATA_DIR, 'citizen_rescue_request_data.csv')
PLAN_FILE = os.path.join(PLANS_DIR, 'PLAN_CITIZEN_RESCUE_REQUEST.xlsx')

# Styling chuẩn từ excel_helper
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

# Định nghĩa các chuỗi dài đặc biệt cho note
note_999  = "CuuTroKhanCap_" + "A" * (999 - 14)
note_1000 = "CuuTroKhanCap_" + "A" * (1000 - 14)
note_1001 = "CuuTroKhanCap_" + "A" * (1001 - 14)
note_1200 = "CuuTroKhanCap_" + "A" * (1200 - 14)

# Danh sách dữ liệu kiểm thử 31 test cases
RAW_CASES = [
    # --- Nhóm 1: BVA Số lượng người cần cứu (Min=1, Nominal=4, Max=50; Lỗi: 0, 51, âm) ---
    {
        "id": "TC_RES_01", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Min - 2 (Số người âm)", "name": "Nguyễn Văn A", "phone": "0987654321",
        "people": -1, "lat": 16.0544, "lng": 108.2022, "note_len": 21,
        "note": "Nước ngập đến nóc nhà", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Số người gặp nạn phải lớn hơn hoặc bằng 1"
    },
    {
        "id": "TC_RES_02", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Số âm cực đoan (-5)", "name": "Nguyễn Văn B", "phone": "0987654322",
        "people": -5, "lat": 16.0544, "lng": 108.2022, "note_len": 20,
        "note": "Cần xuồng cứu hộ gấp", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Số người gặp nạn phải lớn hơn hoặc bằng 1"
    },
    {
        "id": "TC_RES_03", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Min - 1 (Dưới biên dưới: 0 người)", "name": "Trần Thị C", "phone": "0987654323",
        "people": 0, "lat": 16.0544, "lng": 108.2022, "note_len": 23,
        "note": "Gia đình đang bị cô lập", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Số người gặp nạn phải lớn hơn hoặc bằng 1"
    },
    {
        "id": "TC_RES_04", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Min (Tại biên dưới: 1 người)", "name": "Lê Văn D", "phone": "0987654324",
        "people": 1, "lat": 16.0544, "lng": 108.2022, "note_len": 26,
        "note": "Tôi ở một mình cần trợ giúp", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_05", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Min + 1 (Trên biên dưới: 2 người)", "name": "Phạm Thị E", "phone": "0987654325",
        "people": 2, "lat": 16.0544, "lng": 108.2022, "note_len": 32,
        "note": "Hai vợ chồng già bị kẹt trên gác", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_06", "group": "Biên số lượng người (peopleCount)", "tech": "EP",
        "boundary": "Nominal (Danh định điển hình: 4 người)", "name": "Hoàng Văn F", "phone": "0987654326",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 34,
        "note": "Hộ gia đình 4 người cần lương thực", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_07", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Max - 1 (Dưới biên trên: 49 người)", "name": "Đỗ Văn G", "phone": "0987654327",
        "people": 49, "lat": 16.0544, "lng": 108.2022, "note_len": 34,
        "note": "Khu xóm trọ 49 người nước ngập sâu", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_08", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Max (Tại biên trên: 50 người)", "name": "Vũ Thị H", "phone": "0987654328",
        "people": 50, "lat": 16.0544, "lng": 108.2022, "note_len": 38,
        "note": "Điểm sơ tán dã chiến 50 người ngập lụt", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_09", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Max + 1 (Vượt biên trên: 51 người)", "name": "Bùi Văn I", "phone": "0987654329",
        "people": 51, "lat": 16.0544, "lng": 108.2022, "note_len": 36,
        "note": "Nhóm 51 công nhân nhà máy bị cô lập", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Số người gặp nạn không được vượt quá 50 người"
    },
    {
        "id": "TC_RES_10", "group": "Biên số lượng người (peopleCount)", "tech": "BVA",
        "boundary": "Vượt biên xa (100 người)", "name": "Ngô Văn K", "phone": "0987654330",
        "people": 100, "lat": 16.0544, "lng": 108.2022, "note_len": 37,
        "note": "Cụm dân cư 100 người cần cứu trợ khẩn", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Số người gặp nạn không được vượt quá 50 người"
    },

    # --- Nhóm 2: BVA Tọa độ GPS (VN vs Ngoài lãnh thổ & Chuẩn kỹ thuật toàn cầu) ---
    {
        "id": "TC_RES_11", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "EP",
        "boundary": "Nominal VN (Vùng lũ Miền Trung)", "name": "Đinh Văn L", "phone": "0987654331",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 34,
        "note": "Khu vực Hòa Vang Đà Nẵng ngập nặng", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_12", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Biên cực Bắc VN (Lũng Cú, Hà Giang)", "name": "Vàng A M", "phone": "0987654332",
        "people": 4, "lat": 23.3900, "lng": 105.3200, "note_len": 32,
        "note": "Lũng Cú sạt lở lũ quét cô lập bản", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_13", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Biên cực Nam VN (Cà Mau)", "name": "Nguyễn Văn N", "phone": "0987654333",
        "people": 4, "lat": 8.1800, "lng": 104.8300, "note_len": 30,
        "note": "Mũi Cà Mau triều cường ngập đê", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_14", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Biên cực Tây VN (A Pa Chải, Điện Biên)", "name": "Lò Văn P", "phone": "0987654334",
        "people": 4, "lat": 22.4000, "lng": 102.1400, "note_len": 29,
        "note": "Mường Nhé lũ quét chia cắt xã", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_15", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Biên cực Đông đất liền VN (Mũi Đôi, Khánh Hòa)", "name": "Trần Văn Q", "phone": "0987654335",
        "people": 4, "lat": 12.6500, "lng": 109.4600, "note_len": 31,
        "note": "Mũi Đôi sóng lớn triều cường dâng", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_16", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Ngoài VN Phía Bắc (Vân Nam, TQ)", "name": "Lý Văn R", "phone": "0987654336",
        "people": 4, "lat": 24.5000, "lng": 105.0000, "note_len": 31,
        "note": "Khu vực ngoài biên giới phía Bắc", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Tọa độ vĩ độ nằm ngoài lãnh thổ Việt Nam (8.18 - 23.39)"
    },
    {
        "id": "TC_RES_17", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Ngoài VN Phía Nam (Vịnh Thái Lan)", "name": "Dương Văn S", "phone": "0987654337",
        "people": 4, "lat": 7.5000, "lng": 104.0000, "note_len": 29,
        "note": "Vị trí ngoài lãnh thổ phía Nam", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Tọa độ vĩ độ nằm ngoài lãnh thổ Việt Nam (8.18 - 23.39)"
    },
    {
        "id": "TC_RES_18", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Ngoài VN Phía Tây (Lào / Thái Lan)", "name": "Somsak T", "phone": "0987654338",
        "people": 4, "lat": 16.0000, "lng": 101.5000, "note_len": 27,
        "note": "Vị trí ngoài lãnh thổ phía Tây", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Tọa độ kinh độ nằm ngoài lãnh thổ Việt Nam (102.14 - 109.46)"
    },
    {
        "id": "TC_RES_19", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Ngoài VN Phía Đông (Hải phận quốc tế)", "name": "Trương Văn U", "phone": "0987654339",
        "people": 4, "lat": 15.0000, "lng": 115.0000, "note_len": 31,
        "note": "Vị trí ngoài phạm vi cứu hộ VN", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Tọa độ kinh độ nằm ngoài lãnh thổ Việt Nam (102.14 - 109.46)"
    },
    {
        "id": "TC_RES_20", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Lỗi kỹ thuật GPS: Lat > 90.0", "name": "Đặng Văn V", "phone": "0987654340",
        "people": 4, "lat": 95.0000, "lng": 108.2022, "note_len": 28,
        "note": "Vĩ độ vượt giới hạn kỹ thuật", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Vĩ độ (Lat) phải nằm trong khoảng từ -90.0 đến 90.0"
    },
    {
        "id": "TC_RES_21", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "BVA",
        "boundary": "Lỗi kỹ thuật GPS: Lng > 180.0", "name": "Võ Văn W", "phone": "0987654341",
        "people": 4, "lat": 16.0544, "lng": 185.0000, "note_len": 29,
        "note": "Kinh độ vượt giới hạn kỹ thuật", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Kinh độ (Lng) phải nằm trong khoảng từ -180.0 đến 180.0"
    },
    {
        "id": "TC_RES_22", "group": "Biên tọa độ GPS (latitude / longitude)", "tech": "Validation",
        "boundary": "Tọa độ vĩ độ rỗng (Null)", "name": "Mai Văn X", "phone": "0987654342",
        "people": 4, "lat": "NULL_VAL", "lng": 108.2022, "note_len": 21,
        "note": "Tọa độ vĩ độ bị thiếu", "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Tọa độ vĩ độ (Lat) không được để trống"
    },

    # --- Nhóm 3: BVA Độ dài mô tả/ghi chú khẩn cấp (0 - 1000 ký tự; Lỗi: 1001 ký tự) ---
    {
        "id": "TC_RES_23", "group": "Biên độ dài mô tả (note / description)", "tech": "BVA",
        "boundary": "Min (0 ký tự - Chuỗi rỗng)", "name": "Phan Văn Y", "phone": "0987654343",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 0,
        "note": "", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_24", "group": "Biên độ dài mô tả (note / description)", "tech": "BVA",
        "boundary": "Min + 1 (1 ký tự)", "name": "Hồ Văn Z", "phone": "0987654344",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 1,
        "note": "C", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_25", "group": "Biên độ dài mô tả (note / description)", "tech": "EP",
        "boundary": "Nominal (Danh định 66 ký tự)", "name": "Đoàn Thị AA", "phone": "0987654345",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 66,
        "note": "Nước đang dâng nhanh tới mái nhà gia đình có 1 người già khó đi lại", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_26", "group": "Biên độ dài mô tả (note / description)", "tech": "BVA",
        "boundary": "Max - 1 (999 ký tự)", "name": "Lâm Văn BB", "phone": "0987654346",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 999,
        "note": note_999, "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_27", "group": "Biên độ dài mô tả (note / description)", "tech": "BVA",
        "boundary": "Max (Tại biên trên: 1000 ký tự)", "name": "Tạ Văn CC", "phone": "0987654347",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 1000,
        "note": note_1000, "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_28", "group": "Biên độ dài mô tả (note / description)", "tech": "BVA",
        "boundary": "Max + 1 (Vượt biên: 1001 ký tự)", "name": "Chu Văn DD", "phone": "0987654348",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 1001,
        "note": note_1001, "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Độ dài mô tả khẩn cấp vượt quá giới hạn tối đa 1000 ký tự"
    },
    {
        "id": "TC_RES_29", "group": "Biên độ dài mô tả (note / description)", "tech": "BVA",
        "boundary": "Vượt biên xa (1200 ký tự)", "name": "Cao Văn EE", "phone": "0987654349",
        "people": 4, "lat": 16.0544, "lng": 108.2022, "note_len": 1200,
        "note": note_1200, "exp_st": "FAIL", "exp_code": 400,
        "exp_ex": "BadRequestException", "exp_msg": "Độ dài mô tả khẩn cấp vượt quá giới hạn tối đa 1000 ký tự"
    },

    # --- Nhóm 4: Phối hợp đa biên (Boundary Combination & Robustness) ---
    {
        "id": "TC_RES_30", "group": "Phối hợp đa biên (Combination)", "tech": "BVA",
        "boundary": "Đa biên Max (50 người + 1000 ký tự + Cực Đông VN)", "name": "Trịnh Văn FF", "phone": "0987654350",
        "people": 50, "lat": 12.6500, "lng": 109.4600, "note_len": 1000,
        "note": note_1000, "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    },
    {
        "id": "TC_RES_31", "group": "Phối hợp đa biên (Combination)", "tech": "BVA",
        "boundary": "Đa biên Min (1 người + 0 ký tự note + Cực Nam VN)", "name": "Thái Văn GG", "phone": "0987654351",
        "people": 1, "lat": 8.1800, "lng": 104.8300, "note_len": 0,
        "note": "", "exp_st": "PASS", "exp_code": 200,
        "exp_ex": "NONE", "exp_msg": "SUCCESS"
    }
]

def export_csv():
    """Xuất file citizen_rescue_request_data.csv chuẩn UTF-8."""
    headers = [
        "testCaseId", "testGroup", "technique", "boundaryType",
        "citizenName", "citizenPhone", "peopleCount", "latitude", "longitude",
        "noteLength", "note", "expectedStatus", "expectedHttpCode",
        "expectedException", "expectedMessage"
    ]
    with open(CSV_FILE, mode='w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        writer.writerow(headers)
        for c in RAW_CASES:
            writer.writerow([
                c["id"], c["group"], c["tech"], c["boundary"],
                c["name"], c["phone"], c["people"], c["lat"], c["lng"],
                c["note_len"], c["note"], c["exp_st"], c["exp_code"],
                c["exp_ex"], c["exp_msg"]
            ])
    print(f"[OK] Da xuat CSV: {CSV_FILE} ({len(RAW_CASES)} ca kiem thu)")

def export_plan_excel():
    """Tạo file Plan Excel chuẩn chuyên nghiệp 2 sheets: BVA Toàn Diện & Ma Trận Test Case."""
    wb = openpyxl.Workbook()

    # =========================================================================
    # SHEET 1: Phân Tích BVA Toàn Diện
    # =========================================================================
    ws1 = wb.active
    ws1.title = "Phân Tích BVA Toàn Diện"

    ws1['A1'] = "KẾ HOẠCH & BẢNG PHÂN TÍCH GIÁ TRỊ BIÊN (BVA) - API TẠO YÊU CẦU CỨU HỘ"
    ws1['A1'].font = TITLE_FONT
    ws1['A2'] = "Dự án: Hệ thống Điều phối Cứu hộ Lũ lụt | Module: Citizen Rescue Request | Endpoint: POST /api/v1/rescue-requests"
    ws1['A2'].font = ITALIC_FONT

    # Section 1: Đặc tả tiêu chí BVA
    ws1['A4'] = "1. ĐẶC TẢ CÁC BIẾN KIỂM THỬ GIÁ TRỊ BIÊN (BVA SPECIFICATION)"
    ws1['A4'].font = SUB_FONT

    spec_headers = [
        "Tham Số Kiểm Thử", "Kiểu Dữ Liệu", "Quy Chuẩn Biên Hợp Lệ [Min, Max]",
        "Giá Trị Danh Định (Nominal)", "Biên Lỗi (Invalid Boundaries)", "Mô Tả Nghiệp Vụ Cứu Hộ"
    ]
    for col_idx, h in enumerate(spec_headers, 1):
        c = set_cell(ws1, 5, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    specs_data = [
        [
            "Số người cần cứu (peopleCount)", "Integer", "Min = 1, Max = 50",
            "Nominal = 4 người", "Biên âm (-1, -5), Biên 0, Biên trên 51, 100",
            "Mỗi yêu cầu tiếp nhận từ 1 cá nhân đến 1 cụm sơ tán tối đa 50 người/lần."
        ],
        [
            "Vĩ độ GPS (latitude / Lat)", "Double", "8.18° N đến 23.39° N (Biên lãnh thổ VN)",
            "16.0544° N (Đà Nẵng / Quảng Nam)", "< 8.18° (Ngoài VN Nam), > 23.39° (Ngoài VN Bắc), |Lat| > 90.0",
            "Cứu hộ triển khai trong lãnh thổ VN; loại bỏ tọa độ ngoài nước và lỗi GPS."
        ],
        [
            "Kinh độ GPS (longitude / Lng)", "Double", "102.14° E đến 109.46° E (Biên đất liền VN)",
            "108.2022° E (Miền Trung lũ lụt)", "< 102.14° (Ngoài VN Tây), > 109.46° (Ngoài VN Đông), |Lng| > 180.0",
            "Đảm bảo định vị đúng vùng đất liền / ven biển vùng lũ lụt Việt Nam."
        ],
        [
            "Độ dài mô tả khẩn cấp (note)", "String", "0 đến 1000 ký tự",
            "Nominal = 66 ký tự", "> 1000 ký tự (Biên lỗi: 1001, 1200 ký tự)",
            "Cho phép để trống (0 ký tự) khi người dân hoảng loạn, chặn spam văn bản > 1000 ký tự."
        ],
        [
            "Phối hợp đa biên (Combination)", "Multi-param", "Kết hợp các biên Min/Max hợp lệ",
            "People=4, VN GPS, Note danh định", "Bất kỳ biến nào vi phạm biên sẽ kích hoạt HTTP 400",
            "Kiểm tra tính bền vững và toàn vẹn dữ liệu khi nhiều biên cùng chạm ngưỡng."
        ]
    ]

    for r_idx, row in enumerate(specs_data, 6):
        for c_idx, val in enumerate(row, 1):
            cell = set_cell(ws1, r_idx, c_idx, val, NORMAL_FONT)
            if c_idx in [1, 2, 4]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if c_idx == 1:
                cell.font = BOLD_FONT

    # Section 2: Bảng chi tiết phân tích BVA
    start_sec2 = 6 + len(specs_data) + 2
    ws1.cell(row=start_sec2, column=1, value="2. BẢNG CHI TIẾT TÍNH TOÁN ĐIỂM BIÊN (BVA DETAILED MATRIX)").font = SUB_FONT

    bva_headers = [
        "Nhóm Thông Số", "Điểm Biên BVA", "Công Thức / Cơ Sở",
        "Giá Trị Test", "Phân Loại Miền", "Hành Vi Hệ Thống Kỳ Vọng", "HTTP Code"
    ]
    for col_idx, h in enumerate(bva_headers, 1):
        set_cell(ws1, start_sec2 + 1, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    bva_rows = [
        # peopleCount
        ["Số người", "Biên âm (Min - 2)", "peopleCount = -1 < 1", "-1", "Invalid (Lỗi)", "Chặn với lỗi: Số người >= 1", "400 Bad Request"],
        ["Số người", "Dưới biên dưới (Min - 1)", "Min - 1 = 1 - 1 = 0", "0", "Invalid (Lỗi)", "Chặn với lỗi: Số người >= 1", "400 Bad Request"],
        ["Số người", "Tại biên dưới (Min)", "Min = 1", "1", "Valid (Biên Min)", "Tạo thành công yêu cầu cứu hộ 1 người", "200 OK"],
        ["Số người", "Trên biên dưới (Min + 1)", "Min + 1 = 1 + 1 = 2", "2", "Valid", "Tạo thành công yêu cầu cứu hộ 2 người", "200 OK"],
        ["Số người", "Giá trị danh định (Nominal)", "Nominal = 4", "4", "Valid", "Tạo thành công yêu cầu hộ gia đình 4 người", "200 OK"],
        ["Số người", "Dưới biên trên (Max - 1)", "Max - 1 = 50 - 1 = 49", "49", "Valid", "Tạo thành công yêu cầu nhóm 49 người", "200 OK"],
        ["Số người", "Tại biên trên (Max)", "Max = 50", "50", "Valid (Biên Max)", "Tạo thành công yêu cầu nhóm 50 người", "200 OK"],
        ["Số người", "Trên biên trên (Max + 1)", "Max + 1 = 50 + 1 = 51", "51", "Invalid (Lỗi)", "Chặn với lỗi: Số người <= 50 người", "400 Bad Request"],
        ["Số người", "Vượt biên xa", "peopleCount = 100 > 50", "100", "Invalid (Lỗi)", "Chặn với lỗi: Số người <= 50 người", "400 Bad Request"],

        # GPS
        ["Tọa độ GPS", "Danh định VN (Miền Trung)", "Lat=16.0544, Lng=108.2022", "16.0544, 108.2022", "Valid", "Tọa độ hợp lệ tại trung tâm lũ lụt", "200 OK"],
        ["Tọa độ GPS", "Biên cực Bắc VN", "Lat = 23.3900 (Lũng Cú)", "23.3900, 105.3200", "Valid (Biên Bắc)", "Tiếp nhận tọa độ cực Bắc VN", "200 OK"],
        ["Tọa độ GPS", "Biên cực Nam VN", "Lat = 8.1800 (Cà Mau)", "8.1800, 104.8300", "Valid (Biên Nam)", "Tiếp nhận tọa độ cực Nam VN", "200 OK"],
        ["Tọa độ GPS", "Biên cực Tây VN", "Lng = 102.1400 (Điện Biên)", "22.4000, 102.1400", "Valid (Biên Tây)", "Tiếp nhận tọa độ cực Tây VN", "200 OK"],
        ["Tọa độ GPS", "Biên cực Đông đất liền", "Lng = 109.4600 (Khánh Hòa)", "12.6500, 109.4600", "Valid (Biên Đông)", "Tiếp nhận tọa độ cực Đông đất liền VN", "200 OK"],
        ["Tọa độ GPS", "Ngoài VN Phía Bắc", "Lat = 24.5000 > 23.3900", "24.5000, 105.0000", "Invalid (Lỗi)", "Từ chối: Tọa độ ngoài lãnh thổ VN", "400 Bad Request"],
        ["Tọa độ GPS", "Ngoài VN Phía Nam", "Lat = 7.5000 < 8.1800", "7.5000, 104.0000", "Invalid (Lỗi)", "Từ chối: Tọa độ ngoài lãnh thổ VN", "400 Bad Request"],
        ["Tọa độ GPS", "Ngoài VN Phía Tây", "Lng = 101.5000 < 102.1400", "16.0000, 101.5000", "Invalid (Lỗi)", "Từ chối: Tọa độ ngoài lãnh thổ VN", "400 Bad Request"],
        ["Tọa độ GPS", "Ngoài VN Phía Đông", "Lng = 115.0000 > 109.4600", "15.0000, 115.0000", "Invalid (Lỗi)", "Từ chối: Tọa độ ngoài phạm vi cứu hộ VN", "400 Bad Request"],
        ["Tọa độ GPS", "Lỗi kỹ thuật Lat > 90°", "Lat = 95.0000 > 90.0", "95.0000, 108.2022", "Invalid (Lỗi)", "Vi phạm ràng buộc kỹ thuật vĩ độ GPS", "400 Bad Request"],
        ["Tọa độ GPS", "Lỗi kỹ thuật Lng > 180°", "Lng = 185.0000 > 180.0", "16.0544, 185.0000", "Invalid (Lỗi)", "Vi phạm ràng buộc kỹ thuật kinh độ GPS", "400 Bad Request"],

        # Note Length
        ["Độ dài Note", "Tại biên dưới (Min)", "Len = 0 ký tự", "0 ký tự (rỗng)", "Valid (Biên Min)", "Cho phép để trống mô tả khẩn cấp", "200 OK"],
        ["Độ dài Note", "Trên biên dưới (Min + 1)", "Len = 1 ký tự", "1 ký tự ('C')", "Valid", "Tiếp nhận mô tả 1 ký tự", "200 OK"],
        ["Độ dài Note", "Danh định (Nominal)", "Len = 66 ký tự", "66 ký tự", "Valid", "Tiếp nhận mô tả tình huống thông thường", "200 OK"],
        ["Độ dài Note", "Dưới biên trên (Max - 1)", "Len = 999 ký tự", "999 ký tự", "Valid", "Tiếp nhận mô tả dài chi tiết sát trần", "200 OK"],
        ["Độ dài Note", "Tại biên trên (Max)", "Len = 1000 ký tự", "1000 ký tự", "Valid (Biên Max)", "Tiếp nhận mô tả đúng ngưỡng 1000 ký tự", "200 OK"],
        ["Độ dài Note", "Trên biên trên (Max + 1)", "Len = 1001 ký tự", "1001 ký tự", "Invalid (Lỗi)", "Từ chối: Vượt quá giới hạn 1000 ký tự", "400 Bad Request"],
        ["Độ dài Note", "Vượt biên trên xa", "Len = 1200 ký tự", "1200 ký tự", "Invalid (Lỗi)", "Từ chối: Vượt quá giới hạn 1000 ký tự", "400 Bad Request"],

        # Combination
        ["Phối hợp đa biên", "Đa biên Max hợp lệ", "People=50, Note=1000, Cực Đông", "50 người, 1000 kt, Đông VN", "Valid (Robust)", "Tạo thành công khi đồng thời chạm ngưỡng Max", "200 OK"],
        ["Phối hợp đa biên", "Đa biên Min hợp lệ", "People=1, Note=0, Cực Nam", "1 người, 0 kt, Nam VN", "Valid (Robust)", "Tạo thành công khi đồng thời chạm ngưỡng Min", "200 OK"]
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

    auto_fit_columns(ws1)

    # =========================================================================
    # SHEET 2: Ma Trận Test Case
    # =========================================================================
    ws2 = wb.create_sheet(title="Ma Trận Test Case")

    ws2['A1'] = "MA TRẬN CA KIỂM THỬ GIÁ TRỊ BIÊN CHI TIẾT (TEST CASE SPECIFICATION)"
    ws2['A1'].font = TITLE_FONT
    ws2['A2'] = "Bao quát toàn bộ: Biên số người (1-50), Biên tọa độ GPS Việt Nam, Biên độ dài ghi chú (0-1000 ký tự) và Phối hợp đa biên"
    ws2['A2'].font = ITALIC_FONT

    matrix_headers = [
        "Mã Test Case", "Nhóm Tiêu Chí", "Kỹ Thuật", "Phân Loại BVA Chi Tiết",
        "Số Người", "Vĩ Độ (Lat)", "Kinh Độ (Lng)", "Độ Dài Note",
        "Nội Dung Note (Input Preview)", "Kết Quả Mong Đợi", "HTTP Code Kỳ Vọng",
        "Thông Báo / Exception Kỳ Vọng"
    ]

    for col_idx, h in enumerate(matrix_headers, 1):
        set_cell(ws2, 4, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    for r_idx, c in enumerate(RAW_CASES, 5):
        note_display = c["note"] if len(c["note"]) <= 35 else c["note"][:32] + "..."
        if c["note_len"] == 0:
            note_display = "(trống)"

        row_vals = [
            c["id"], c["group"], c["tech"], c["boundary"],
            c["people"], c["lat"], c["lng"], c["note_len"],
            note_display, c["exp_st"], c["exp_code"], c["exp_msg"]
        ]

        for col_idx, val in enumerate(row_vals, 1):
            cell = set_cell(ws2, r_idx, col_idx, val, NORMAL_FONT)
            if col_idx in [1, 3, 5, 6, 7, 8, 10, 11]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if col_idx == 10: # Cột Kết Quả Mong Đợi
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
