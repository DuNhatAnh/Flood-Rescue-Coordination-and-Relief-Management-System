# -*- coding: utf-8 -*-
"""
Module hỗ trợ xuất báo cáo Excel chuẩn hóa cho toàn bộ suite kiểm thử (KCPM QA Testing).
Dùng chung cho tất cả các thành viên trong nhóm (Epic 1 -> Epic 5).
"""

import os
import sys
import time
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter


def init_console_utf8():
    """Đảm bảo console in đúng tiếng Việt UTF-8 trên Windows PowerShell/CMD."""
    if sys.stdout.encoding != 'utf-8':
        try:
            sys.stdout.reconfigure(encoding='utf-8')
        except Exception:
            pass


# ── STYLING CONSTANTS (Chuẩn màu sắc & Font chữ thống nhất) ──────────────────
FONT_NAME    = 'Segoe UI'

HEADER_FONT  = Font(name=FONT_NAME, size=10, bold=True, color='FFFFFF')
HEADER_FILL  = PatternFill(start_color='1F497D', end_color='1F497D', fill_type='solid') # Xanh Navy đậm

TITLE_FONT   = Font(name=FONT_NAME, size=13, bold=True, color='1F497D')
SUB_FONT     = Font(name=FONT_NAME, size=11, bold=True, color='1F497D')
NORMAL_FONT  = Font(name=FONT_NAME, size=9)
BOLD_FONT    = Font(name=FONT_NAME, size=9, bold=True)
ITALIC_FONT  = Font(name=FONT_NAME, size=9, italic=True, color='595959')

PASS_FILL    = PatternFill(start_color='E2EFDA', end_color='E2EFDA', fill_type='solid') # Xanh lá nhạt
FAIL_FILL    = PatternFill(start_color='FCE4D6', end_color='FCE4D6', fill_type='solid') # Cam đỏ nhạt
CARD_FILL    = PatternFill(start_color='F2F4F7', end_color='F2F4F7', fill_type='solid')

PASS_FONT    = Font(name=FONT_NAME, size=9, bold=True, color='276A3C') # Chữ xanh đậm
FAIL_FONT    = Font(name=FONT_NAME, size=9, bold=True, color='9C0006') # Chữ đỏ đậm

THIN_BORDER  = Border(
    left=Side(style='thin', color='D9D9D9'),  right=Side(style='thin', color='D9D9D9'),
    top=Side(style='thin', color='D9D9D9'),   bottom=Side(style='thin', color='D9D9D9')
)


# ── CÁC HÀM TIỆN ÍCH CƠ BẢN ──────────────────────────────────────────────────
def set_cell(ws, row, col, val, font=None, fill=None, align=None, border=True):
    """Ghi giá trị và áp dụng style cho một ô Excel."""
    cell = ws.cell(row=row, column=col, value=val)
    if font:   cell.font = font
    if fill:   cell.fill = fill
    if align:  cell.alignment = align
    if border: cell.border = THIN_BORDER
    return cell


def auto_fit_columns(ws, min_w=12, max_w=50):
    """Tự động canh chỉnh độ rộng các cột cho đẹp mắt."""
    for col in ws.columns:
        max_len = max((len(str(c.value or '')) for c in col if c.row > 2), default=10)
        col_letter = get_column_letter(col[0].column)
        ws.column_dimensions[col_letter].width = min(max(max_len + 3, min_w), max_w)


# ── CÁC HÀM XUẤT SHEET CHUẨN ĐỊNH DẠNG ───────────────────────────────────────
def create_dashboard_sheet(wb, title, module_info, metrics, rubrics):
    """
    Tạo Sheet 1: Dashboard Tổng Quan
    - Bảng 1: Thống kê tổng quan thực thi (Executive Summary)
    - Bảng 2: Đánh giá tiêu chí kiểm thử (Rubric)
    """
    ws = wb.active
    ws.title = 'Dashboard Tổng Quan'

    # Tiêu đề & Subtitle
    ws['A1'] = title
    ws['A1'].font = TITLE_FONT
    ws['A2'] = f'{module_info} | Thời gian chạy: {time.strftime("%d/%m/%Y %H:%M:%S")}'
    ws['A2'].font = ITALIC_FONT

    # Bảng 1: Thống kê tổng quan
    ws['A4'] = '1. THỐNG KÊ TỔNG QUAN THỰC THI (EXECUTIVE SUMMARY)'
    ws['A4'].font = SUB_FONT

    for r_idx, row in enumerate(metrics, start=5):
        for c_idx, val in enumerate(row, start=1):
            cell = set_cell(ws, r_idx, c_idx, val)
            if r_idx == 5:
                cell.font = HEADER_FONT
                cell.fill = HEADER_FILL
                cell.alignment = Alignment(horizontal='center', vertical='center')
            else:
                cell.font = NORMAL_FONT
                if c_idx == 2:
                    cell.font = BOLD_FONT
                    cell.alignment = Alignment(horizontal='center')
                    if 'ĐẠT' in str(val) or (isinstance(val, int) and val > 0 and r_idx == 7): # PASS row
                        cell.fill = PASS_FILL

    # Bảng 2: Rubrics
    start_rubric_row = 5 + len(metrics) + 2
    ws.cell(row=start_rubric_row, column=1, value='2. ĐÁNH GIÁ MỨC ĐỘ ĐÁP ỨNG TIÊU CHÍ KIỂM THỬ (RUBRIC)').font = SUB_FONT

    for r_idx, row in enumerate(rubrics, start=start_rubric_row + 1):
        for c_idx, val in enumerate(row, start=1):
            cell = set_cell(ws, r_idx, c_idx, val)
            if r_idx == start_rubric_row + 1:
                cell.font = HEADER_FONT
                cell.fill = HEADER_FILL
                cell.alignment = Alignment(horizontal='center', vertical='center')
            else:
                cell.font = NORMAL_FONT
                if c_idx in [1, 3, 4]:
                    cell.alignment = Alignment(horizontal='center')
                if c_idx == 4:
                    cell.font = BOLD_FONT
                    cell.fill = PASS_FILL

    auto_fit_columns(ws)
    return ws


def create_detail_sheet(wb, title, subtitle, headers, data_rows, center_col_indices=None):
    """
    Tạo Sheet 2: Chi Tiết Kết Quả
    - Headers nền navy chữ trắng
    - Cột kết quả (cột cuối) tự động tô màu xanh (PASS) hoặc đỏ (FAIL)
    """
    ws = wb.create_sheet(title='Chi Tiết Kết Quả')

    ws['A1'] = title
    ws['A1'].font = TITLE_FONT
    ws['A2'] = subtitle
    ws['A2'].font = ITALIC_FONT

    # Header hàng 4
    for c_idx, h in enumerate(headers, 1):
        cell = set_cell(ws, 4, c_idx, h)
        cell.font = HEADER_FONT
        cell.fill = HEADER_FILL
        cell.alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)

    center_cols = center_col_indices or []
    last_col_idx = len(headers)

    # Data từ hàng 5
    for r_idx, row_vals in enumerate(data_rows, 5):
        for c_idx, val in enumerate(row_vals, 1):
            cell = set_cell(ws, r_idx, c_idx, val)
            cell.font = NORMAL_FONT
            if c_idx in center_cols:
                cell.alignment = Alignment(horizontal='center', vertical='center')

            # Cột cuối cùng là Verdict (KẾT QUẢ)
            if c_idx == last_col_idx:
                cell.alignment = Alignment(horizontal='center', vertical='center')
                if val == 'PASS':
                    cell.fill = PASS_FILL
                    cell.font = PASS_FONT
                else:
                    cell.fill = FAIL_FILL
                    cell.font = FAIL_FONT

    auto_fit_columns(ws)
    return ws


def save_report(wb, report_path):
    """Lưu file Excel an toàn (fallback sang _NEW.xlsx nếu đang bị mở lock)."""
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    try:
        wb.save(report_path)
        print(f'BAO CAO XUAT THANH CONG: {os.path.abspath(report_path)}')
    except PermissionError:
        fallback = report_path.replace('.xlsx', '_NEW.xlsx')
        wb.save(fallback)
        print(f'BAO CAO XUAT THANH CONG (ban moi vi file cu dang mo): {os.path.abspath(fallback)}')
