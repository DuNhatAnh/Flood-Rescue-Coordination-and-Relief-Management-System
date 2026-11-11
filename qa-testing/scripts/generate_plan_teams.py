# -*- coding: utf-8 -*-
"""
KCPM-97: Script khởi tạo Kế hoạch kiểm thử Excel (Máy trạng thái & Bảng Quyết Định - Decision Table)
và tập dữ liệu kiểm thử CSV cho Quản lý Trạng thái Xe & Đội Cứu hộ
(APIs: GET /api/v1/vehicles/available, PUT /api/v1/vehicles/{id}, GET /api/v1/teams/available).
Tích hợp BẢNG QUYẾT ĐỊNH (DECISION TABLE R1-R8) chuẩn môn học.
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

PLAN_FILE = os.path.join(PLANS_DIR, 'PLAN_TEAMS_AVAILABILITY.xlsx')
CSV_FILE = os.path.join(DATA_DIR, 'teams_availability_data.csv')

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

# Danh sách 24 ca kiểm thử chi tiết gắn với 8 Quy tắc Bảng Quyết Định (Decision Table R1-R8)
TEST_CASES = [
    # --- Nhóm 1: Chuyển đổi trạng thái hợp lệ - Chu trình vòng đời (Valid State Transitions) ---
    {
        "id": "TC_STM_01", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "AVAILABLE", "event": "DISPATCH", "next_st": "BUSY",
        "tech": "State Transition", "rule": "R1 (Điều phối chuẩn)", "type": "Valid Transition (0-switch)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Điều phối phương tiện thành công, chuyển sang BUSY"
    },
    {
        "id": "TC_STM_02", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "BUSY", "event": "COMPLETE", "next_st": "AVAILABLE",
        "tech": "State Transition", "rule": "R2 (Hoàn thành nhiệm vụ)", "type": "Valid Transition (0-switch)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Hoàn thành nhiệm vụ cứu hộ, phương tiện về AVAILABLE"
    },
    {
        "id": "TC_STM_03", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "BUSY", "event": "BREAKDOWN", "next_st": "MAINTENANCE",
        "tech": "State Transition", "rule": "R2 (Sự cố hư hỏng)", "type": "Valid Transition (Sự cố)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Báo hỏng phương tiện giữa dòng lũ, chuyển sang MAINTENANCE"
    },
    {
        "id": "TC_STM_04", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "MAINTENANCE", "event": "REPAIRED", "next_st": "AVAILABLE",
        "tech": "State Transition", "rule": "R2 (Sửa chữa xong)", "type": "Valid Transition (Phục hồi)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Nghiệm thu sửa chữa hoàn tất, phương tiện về AVAILABLE"
    },
    {
        "id": "TC_STM_05", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "AVAILABLE", "event": "MAINTAIN", "next_st": "MAINTENANCE",
        "tech": "State Transition", "rule": "R2 (Đưa đi bảo dưỡng)", "type": "Valid Transition (Bảo dưỡng)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Đưa phương tiện đi bảo dưỡng định kỳ, chuyển MAINTENANCE"
    },
    {
        "id": "TC_STM_06", "target": "TEAM", "entity_id": "TEAM-001",
        "current_st": "AVAILABLE", "event": "DISPATCH", "next_st": "BUSY",
        "tech": "State Transition", "rule": "R1 (Điều phối chuẩn)", "type": "Valid Transition (Đội cứu hộ)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Điều phối đội cứu hộ thành công, chuyển sang BUSY"
    },
    {
        "id": "TC_STM_07", "target": "TEAM", "entity_id": "TEAM-001",
        "current_st": "BUSY", "event": "COMPLETE", "next_st": "AVAILABLE",
        "tech": "State Transition", "rule": "R2 (Hoàn thành nhiệm vụ)", "type": "Valid Transition (Đội cứu hộ)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Đội cứu hộ hoàn thành nhiệm vụ, giải phóng về AVAILABLE"
    },
    {
        "id": "TC_STM_08", "target": "TEAM", "entity_id": "TEAM-001",
        "current_st": "MAINTENANCE", "event": "REPAIRED", "next_st": "AVAILABLE",
        "tech": "State Transition", "rule": "R2 (Đội phục hồi)", "type": "Valid Transition (Đội phục hồi)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Đội cứu hộ phục hồi thể lực & quân tư trang, về AVAILABLE"
    },

    # --- Nhóm 2: Chặn chuyển đổi trạng thái bất hợp lệ (Invalid State Invariants) ---
    {
        "id": "TC_STM_09", "target": "VEHICLE", "entity_id": "VEH-002",
        "current_st": "BUSY", "event": "DISPATCH", "next_st": "NONE",
        "tech": "State Transition", "rule": "R3 (Chặn xe bận)", "type": "Invalid Invariant (Chặn xe bận)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Phương tiện VEH-002 đang bận hoặc không ở trạng thái sẵn sàng (AVAILABLE) để điều phối"
    },
    {
        "id": "TC_STM_10", "target": "TEAM", "entity_id": "TEAM-002",
        "current_st": "BUSY", "event": "DISPATCH", "next_st": "NONE",
        "tech": "State Transition", "rule": "R4 (Chặn đội bận)", "type": "Invalid Invariant (Chặn đội bận)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Đội cứu hộ TEAM-002 đang bận thực hiện nhiệm vụ, không thể gán đơn mới"
    },
    {
        "id": "TC_STM_11", "target": "VEHICLE", "entity_id": "VEH-003",
        "current_st": "MAINTENANCE", "event": "DISPATCH", "next_st": "NONE",
        "tech": "State Transition", "rule": "R5 (Chặn xe bảo trì)", "type": "Invalid Invariant (Chặn xe bảo trì)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Phương tiện VEH-003 đang bảo dưỡng/hỏng hóc, không thể điều phối cứu nạn"
    },
    {
        "id": "TC_STM_12", "target": "TEAM", "entity_id": "TEAM-003",
        "current_st": "MAINTENANCE", "event": "DISPATCH", "next_st": "NONE",
        "tech": "State Transition", "rule": "R6 (Chặn đội bảo trì)", "type": "Invalid Invariant (Chặn đội bảo trì)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Đội cứu hộ TEAM-003 đang tạm ngưng hoạt động, không thể điều phối"
    },
    {
        "id": "TC_STM_13", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "AVAILABLE", "event": "COMPLETE", "next_st": "NONE",
        "tech": "State Transition", "rule": "R2 (Sai ngữ cảnh)", "type": "Invalid Event (Sai ngữ cảnh)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Phương tiện đang sẵn sàng, không có nhiệm vụ đang thực hiện để hoàn tất"
    },
    {
        "id": "TC_STM_14", "target": "VEHICLE", "entity_id": "VEH-003",
        "current_st": "MAINTENANCE", "event": "COMPLETE", "next_st": "NONE",
        "tech": "State Transition", "rule": "R2 (Sai ngữ cảnh)", "type": "Invalid Event (Sai ngữ cảnh)",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Phương tiện đang bảo trì, không thể hoàn thành nhiệm vụ cứu nạn"
    },

    # --- Nhóm 3: Kiểm thử Lọc danh sách sẵn sàng (GET /available) ---
    {
        "id": "TC_STM_15", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "AVAILABLE", "event": "GET_AVAILABLE", "next_st": "AVAILABLE",
        "tech": "State Query", "rule": "R7 (Lọc danh sách sẵn sàng)", "type": "Query Included (Sẵn sàng)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Phương tiện AVAILABLE xuất hiện trong danh sách sẵn sàng"
    },
    {
        "id": "TC_STM_16", "target": "VEHICLE", "entity_id": "VEH-002",
        "current_st": "BUSY", "event": "GET_AVAILABLE", "next_st": "FILTERED_OUT",
        "tech": "State Query", "rule": "R7 (Lọc danh sách sẵn sàng)", "type": "Query Excluded (Lọc bỏ xe bận)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Phương tiện BUSY bị lọc bỏ khỏi danh sách sẵn sàng điều phối"
    },
    {
        "id": "TC_STM_17", "target": "VEHICLE", "entity_id": "VEH-003",
        "current_st": "MAINTENANCE", "event": "GET_AVAILABLE", "next_st": "FILTERED_OUT",
        "tech": "State Query", "rule": "R7 (Lọc danh sách sẵn sàng)", "type": "Query Excluded (Lọc bỏ xe bảo trì)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Phương tiện MAINTENANCE bị lọc bỏ khỏi danh sách sẵn sàng điều phối"
    },
    {
        "id": "TC_STM_18", "target": "TEAM", "entity_id": "TEAM-001",
        "current_st": "AVAILABLE", "event": "GET_AVAILABLE", "next_st": "AVAILABLE",
        "tech": "State Query", "rule": "R7 (Lọc danh sách sẵn sàng)", "type": "Query Included (Sẵn sàng)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Đội cứu hộ AVAILABLE xuất hiện trong danh sách sẵn sàng"
    },
    {
        "id": "TC_STM_19", "target": "TEAM", "entity_id": "TEAM-002",
        "current_st": "BUSY", "event": "GET_AVAILABLE", "next_st": "FILTERED_OUT",
        "tech": "State Query", "rule": "R7 (Lọc danh sách sẵn sàng)", "type": "Query Excluded (Lọc bỏ đội bận)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Đội cứu hộ BUSY bị lọc bỏ khỏi danh sách sẵn sàng điều phối"
    },
    {
        "id": "TC_STM_20", "target": "TEAM", "entity_id": "TEAM-003",
        "current_st": "MAINTENANCE", "event": "GET_AVAILABLE", "next_st": "FILTERED_OUT",
        "tech": "State Query", "rule": "R7 (Lọc danh sách sẵn sàng)", "type": "Query Excluded (Lọc bỏ đội bảo trì)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Đội cứu hộ MAINTENANCE bị lọc bỏ khỏi danh sách sẵn sàng điều phối"
    },

    # --- Nhóm 4: Cập nhật trạng thái API PUT /api/v1/vehicles/{id} ---
    {
        "id": "TC_STM_21", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "AVAILABLE", "event": "PUT_STATUS", "next_st": "MAINTENANCE",
        "tech": "API Validation", "rule": "R1 (Cập nhật chuẩn)", "type": "Valid PUT Update",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Cập nhật trạng thái phương tiện thành công: MAINTENANCE"
    },
    {
        "id": "TC_STM_22", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "AVAILABLE", "event": "PUT_STATUS", "next_st": "FLYING_BOAT",
        "tech": "API Validation", "rule": "R8 (Cập nhật lỗi)", "type": "Invalid Status Enum",
        "exp_st": "FAIL", "exp_code": 400, "exp_ex": "BadRequestException",
        "exp_msg": "Trạng thái phương tiện không hợp lệ, chỉ chấp nhận AVAILABLE, BUSY, MAINTENANCE"
    },
    {
        "id": "TC_STM_23", "target": "VEHICLE", "entity_id": "VEH-NOT-FOUND",
        "current_st": "AVAILABLE", "event": "PUT_STATUS", "next_st": "MAINTENANCE",
        "tech": "API Validation", "rule": "R8 (Cập nhật lỗi)", "type": "Resource Not Found",
        "exp_st": "FAIL", "exp_code": 404, "exp_ex": "ResourceNotFoundException",
        "exp_msg": "Không tìm thấy phương tiện ID: VEH-NOT-FOUND"
    },

    # --- Nhóm 5: Chuỗi chuyển trạng thái vòng đời liên hoàn (Round-Trip / 1-switch) ---
    {
        "id": "TC_STM_24", "target": "VEHICLE", "entity_id": "VEH-001",
        "current_st": "AVAILABLE", "event": "LIFECYCLE_ROUNDTRIP", "next_st": "AVAILABLE",
        "tech": "State Transition", "rule": "R1 (Vòng đời hoàn chỉnh)", "type": "Round-Trip 1-Switch (AV->BUSY->MAINT->AV)",
        "exp_st": "PASS", "exp_code": 200, "exp_ex": "NONE",
        "exp_msg": "Hoàn tất chu trình khép kín: AVAILABLE -> BUSY -> MAINTENANCE -> AVAILABLE"
    }
]

def export_csv():
    with open(CSV_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([
            "testCaseId", "targetType", "entityId", "currentState", "eventAction",
            "expectedNextState", "technique", "decisionRule", "transitionType",
            "expectedStatus", "expectedHttpCode", "expectedException", "expectedMessage"
        ])
        for tc in TEST_CASES:
            writer.writerow([
                tc["id"], tc["target"], tc["entity_id"], tc["current_st"], tc["event"],
                tc["next_st"], tc["tech"], tc["rule"], tc["type"], tc["exp_st"],
                tc["exp_code"], tc["exp_ex"], tc["exp_msg"]
            ])
    print(f"[OK] Da xuat CSV: {CSV_FILE}")

def export_plan_excel():
    wb = openpyxl.Workbook()

    # =========================================================================
    # SHEET 1: Phân Tích Máy Trạng Thái & Bảng Quyết Định
    # =========================================================================
    ws1 = wb.active
    ws1.title = "Phân Tích STM & Bảng QĐ"

    ws1['A1'] = "THIẾT KẾ KIỂM THỬ MÁY TRẠNG THÁI (STATE MACHINE) & BẢNG QUYẾT ĐỊNH (DECISION TABLE)"
    ws1['A1'].font = TITLE_FONT
    ws1['A2'] = "Dự án: Hệ thống Điều phối Cứu hộ Lũ lụt | Module: Đội cứu hộ & Phương tiện (Epic 3) | Subtask: KCPM-97 | APIs: GET /api/v1/vehicles/available, PUT /api/v1/vehicles/{id}, GET /api/v1/teams/available"
    ws1['A2'].font = ITALIC_FONT

    # --- Bảng 1: Đặc tả các trạng thái trong hệ thống ---
    ws1['A4'] = "1. ĐẶC TẢ CÁC TRẠNG THÁI HOẠT ĐỘNG (SYSTEM STATES DEFINITION)"
    ws1['A4'].font = SUB_FONT

    state_headers = ["Mã Trạng Thái", "Tên Trạng Thái", "Đối Tượng Áp Dụng", "Ý Nghĩa Nghiệp Vụ Vùng Lũ", "Điều Kiện Sẵn Sàng Nhận Lệnh"]
    for col_idx, h in enumerate(state_headers, 1):
        set_cell(ws1, 5, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    state_rows = [
        ["ST_01", "AVAILABLE", "Xe & Đội Cứu Hộ", "Sẵn sàng hoạt động tại kho bãi, nhân lực và nhiên liệu đầy đủ", "ĐƯỢC PHÉP điều phối nhận đơn cứu hộ mới"],
        ["ST_02", "BUSY / ASSIGNED", "Xe & Đội Cứu Hộ", "Đang trực tiếp di chuyển hoặc thực hiện cứu nạn tại điểm ngập sâu", "CHẶN TUYỆT ĐỐI không điều phối thêm đơn"],
        ["ST_03", "MAINTENANCE", "Xe & Đội Cứu Hộ", "Hỏng chân vịt, động cơ ngập nước, hoặc đội phục hồi thể lực sau ca trực", "CHẶN TUYỆT ĐỐI không gán nhiệm vụ cứu nạn"]
    ]

    for r_idx, row in enumerate(state_rows, 6):
        for c_idx, val in enumerate(row, 1):
            cell = set_cell(ws1, r_idx, c_idx, val, NORMAL_FONT)
            if c_idx in [1, 2, 3]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if c_idx == 5:
                if "ĐƯỢC PHÉP" in val:
                    cell.fill = PASS_FILL
                    cell.font = PASS_FONT
                else:
                    cell.fill = FAIL_FILL
                    cell.font = FAIL_FONT

    # --- Bảng 2: BẢNG QUYẾT ĐỊNH (DECISION TABLE) CHO QUY TẮC ĐIỀU PHỐI & TRẠNG THÁI ---
    start_sec2 = 6 + len(state_rows) + 2
    ws1.cell(row=start_sec2, column=1, value="2. BẢNG QUYẾT ĐỊNH (DECISION TABLE) - MA TRẬN CHUYỂN TRẠNG THÁI & ĐIỀU PHỐI").font = SUB_FONT

    dt_headers = [
        "Điều Kiện / Hành Động Kỳ Vọng",
        "R1 (Điều phối chuẩn)", "R2 (Xong nhiệm vụ)", "R3 (Chặn xe bận)",
        "R4 (Chặn đội bận)", "R5 (Chặn xe bảo trì)", "R6 (Chặn đội bảo trì)",
        "R7 (Lọc sẵn sàng)", "R8 (Cập nhật lỗi)"
    ]
    for col_idx, h in enumerate(dt_headers, 1):
        set_cell(ws1, start_sec2 + 1, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    dt_rows = [
        ["C1: Đối tượng kiểm tra?", "Xe / Đội", "Xe / Đội", "Xe", "Đội", "Xe", "Đội", "Xe / Đội", "Xe"],
        ["C2: Trạng thái hiện tại?", "AVAILABLE", "BUSY", "BUSY", "BUSY", "MAINTENANCE", "MAINTENANCE", "Bất kỳ", "AVAILABLE"],
        ["C3: Sự kiện tác động?", "DISPATCH", "COMPLETE", "DISPATCH", "DISPATCH", "DISPATCH", "DISPATCH", "GET_AVAILABLE", "PUT (Sai/Lạ)"],
        ["C4: Đối tượng tồn tại trong DB?", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "N (hoặc Enum sai)"],
        ["A1: HÀNH ĐỘNG KỲ VỌNG", "200 OK (Sang BUSY)", "200 OK (Về AVAIL)", "400 BadRequest", "400 BadRequest", "400 BadRequest", "400 BadRequest", "200 OK (Lọc chỉ AVAIL)", "400 / 404 Error"],
        ["A2: Đánh Giá Kết Quả Kiểm Thử", "PASS", "PASS", "FAIL (Chặn)", "FAIL (Chặn)", "FAIL (Chặn)", "FAIL (Chặn)", "PASS", "FAIL (Chặn)"]
    ]

    for r_idx, row in enumerate(dt_rows, start_sec2 + 2):
        for c_idx, val in enumerate(row, 1):
            cell = set_cell(ws1, r_idx, c_idx, val, NORMAL_FONT)
            if c_idx >= 2:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if r_idx == start_sec2 + 7: # Dòng Đánh Giá Kết Quả
                if "PASS" in val:
                    cell.fill = PASS_FILL
                    cell.font = PASS_FONT
                else:
                    cell.fill = FAIL_FILL
                    cell.font = FAIL_FONT

    # --- Bảng 3: Ma trận Chuyển đổi trạng thái (State Transition Matrix) ---
    start_sec3 = start_sec2 + len(dt_rows) + 3
    ws1.cell(row=start_sec3, column=1, value="3. MA TRẬN CHUYỂN ĐỔI TRẠNG THÁI (STATE TRANSITION MATRIX)").font = SUB_FONT

    matrix_headers = ["Trạng Thái Nguồn (Current)", "Sự Kiện Kích Hoạt (Event)", "Trạng Thái Đích (Next State)", "Hợp Lệ / Vi Phạm", "Hành Vi Xử Lý & HTTP Code"]
    for col_idx, h in enumerate(matrix_headers, 1):
        set_cell(ws1, start_sec3 + 1, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    matrix_rows = [
        ["AVAILABLE", "DISPATCH (Gán nhiệm vụ cứu hộ)", "BUSY", "Hợp lệ (Valid)", "Chuyển trạng thái sang BUSY, cấp phát phương tiện (200 OK)"],
        ["AVAILABLE", "MAINTAIN (Đưa đi bảo dưỡng định kỳ)", "MAINTENANCE", "Hợp lệ (Valid)", "Chuyển sang bảo dưỡng kỹ thuật định kỳ (200 OK)"],
        ["BUSY", "COMPLETE (Hoàn thành nhiệm vụ)", "AVAILABLE", "Hợp lệ (Valid)", "Giải phóng xe/đội về trạng thái sẵn sàng (200 OK)"],
        ["BUSY", "BREAKDOWN (Gặp sự cố hỏng hóc giữa dòng)", "MAINTENANCE", "Hợp lệ (Valid)", "Chuyển sang bảo trì dã chiến, báo cứu hộ thay thế (200 OK)"],
        ["MAINTENANCE", "REPAIRED (Sửa chữa nghiệm thu xong)", "AVAILABLE", "Hợp lệ (Valid)", "Đưa xe/đội về kho sẵn sàng ứng trực (200 OK)"],
        ["BUSY", "DISPATCH (Cố tình gán thêm đơn thứ 2)", "— (Giữ nguyên BUSY)", "Vi phạm (Invalid)", "CHẶN: Xe/Đội đang làm nhiệm vụ, từ chối điều phối (400 Bad Request)"],
        ["MAINTENANCE", "DISPATCH (Cố tình gán đơn cho xe hỏng)", "— (Giữ nguyên MAINT)", "Vi phạm (Invalid)", "CHẶN: Xe/Đội đang bảo trì, từ chối điều phối (400 Bad Request)"],
        ["AVAILABLE", "COMPLETE (Báo xong khi chưa nhận việc)", "— (Giữ nguyên AVAIL)", "Vi phạm (Invalid)", "CHẶN: Không có nhiệm vụ đang thực hiện (400 Bad Request)"],
        ["MAINTENANCE", "COMPLETE (Xe bảo trì báo xong việc)", "— (Giữ nguyên MAINT)", "Vi phạm (Invalid)", "CHẶN: Xe đang bảo trì không có nhiệm vụ cứu hộ (400 Bad Request)"]
    ]

    for r_idx, row in enumerate(matrix_rows, start_sec3 + 2):
        for c_idx, val in enumerate(row, 1):
            cell = set_cell(ws1, r_idx, c_idx, val, NORMAL_FONT)
            if c_idx in [1, 2, 3, 4]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if c_idx == 4:
                if "Hợp lệ" in val:
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

    ws2['A1'] = "MA TRẬN CA KIỂM THỬ MÁY TRẠNG THÁI & DECISION TABLE (TEST CASES)"
    ws2['A1'].font = TITLE_FONT
    ws2['A2'] = "Chi tiết 24 test cases: Bao phủ chu trình vòng đời, 8 quy tắc Decision Table (R1-R8), Chặn xe/đội BUSY & MAINTENANCE"
    ws2['A2'].font = ITALIC_FONT

    tc_headers = [
        "Mã Test Case", "Đối Tượng", "Mã Định Danh (ID)", "Trạng Thái Hiện Tại",
        "Sự Kiện Kích Hoạt", "Trạng Thái Đích Kỳ Vọng", "Kỹ Thuật", "Quy Tắc Quyết Định",
        "Phân Loại Chuyển Trạng Thái", "Kết Quả Mong Đợi", "HTTP Code Kỳ Vọng",
        "Exception Kỳ Vọng", "Thông Báo Kỳ Vọng"
    ]

    for col_idx, h in enumerate(tc_headers, 1):
        set_cell(ws2, 4, col_idx, h, HEADER_FONT, HEADER_FILL, Alignment(horizontal='center', vertical='center', wrap_text=True))

    for r_idx, tc in enumerate(TEST_CASES, 5):
        row_vals = [
            tc["id"], tc["target"], tc["entity_id"], tc["current_st"],
            tc["event"], tc["next_st"], tc["tech"], tc["rule"], tc["type"],
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
