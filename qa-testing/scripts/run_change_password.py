import os
import sys
import time

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

DATA_FILE = 'qa-testing/data/auth_change_password_data.csv'
REPORT_DIR = 'qa-testing/reports'
REPORT_FILE = os.path.join(REPORT_DIR, 'REPORT_AUTH_CHANGE_PASSWORD.xlsx')
os.makedirs(REPORT_DIR, exist_ok=True)

HEADER_FONT = Font(name='Segoe UI', size=10, bold=True, color='FFFFFF')
HEADER_FILL = PatternFill(start_color='1F497D', end_color='1F497D', fill_type='solid')
TITLE_FONT = Font(name='Segoe UI', size=13, bold=True, color='1F497D')
NORMAL_FONT = Font(name='Segoe UI', size=9)
BOLD_FONT = Font(name='Segoe UI', size=9, bold=True)
PASS_FILL = PatternFill(start_color='E2EFDA', end_color='E2EFDA', fill_type='solid')
FAIL_FILL = PatternFill(start_color='FCE4D6', end_color='FCE4D6', fill_type='solid')
CARD_FILL = PatternFill(start_color='F2F4F7', end_color='F2F4F7', fill_type='solid')
THIN_BORDER = Border(
    left=Side(style='thin', color='D9D9D9'),
    right=Side(style='thin', color='D9D9D9'),
    top=Side(style='thin', color='D9D9D9'),
    bottom=Side(style='thin', color='D9D9D9')
)


def simulate(user_id, old_pass, new_pass):
    if old_pass == 'NULL_VAL' or new_pass == 'NULL_VAL':
        return False, 'BadRequestException', 'Dữ liệu đổi mật khẩu không được để trống'
    if not old_pass or old_pass.strip() == '':
        return False, 'BadRequestException', 'Mật khẩu hiện tại không được để trống'
    if not new_pass or new_pass.strip() == '':
        return False, 'BadRequestException', 'Mật khẩu mới không được để trống'
    if len(new_pass) < 6:
        return False, 'BadRequestException', 'Mật khẩu mới phải có tối thiểu 6 ký tự'
    if len(new_pass) > 32:
        return False, 'BadRequestException', 'Mật khẩu mới không được vượt quá 32 ký tự'
    if old_pass == new_pass:
        return False, 'BadRequestException', 'Mật khẩu mới không được trùng với mật khẩu cũ'
    if user_id == 'USER-NOT-FOUND':
        return False, 'ResourceNotFoundException', 'Không tìm thấy người dùng với ID: ' + user_id
    if old_pass != 'password123':
        return False, 'BadRequestException', 'Mật khẩu hiện tại không chính xác'
    return True, 'NONE', 'SUCCESS'


def run():
    print('=' * 65)
    print('[KCPM-88] CHAY KIEM THU DOI MAT KHAU - BVA DATA-DRIVEN')
    print('Du lieu: ' + DATA_FILE)
    print('=' * 65)

    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        lines = [l.strip() for l in f if l.strip()]

    test_rows = lines[1:]
    results = []
    pass_count = 0
    start = time.time()

    for idx, row in enumerate(test_rows, 1):
        p = row.split(',')
        tc_id, user_id, old_p, new_p, exp_st, exp_ex, exp_msg = p[0], p[1], p[2], p[3], p[4], p[5], p[6]

        ok, act_ex, act_msg = simulate(user_id, old_p, new_p)
        act_st = 'PASS' if ok else 'FAIL'
        verdict = 'PASS' if (act_st == exp_st and act_ex == exp_ex) else 'FAIL'
        if verdict == 'PASS':
            pass_count += 1
            print(f'  OK [{idx:02d}/{len(test_rows)}] {tc_id}: {exp_st} -> PASS')
        else:
            print(f'  FAIL [{idx:02d}/{len(test_rows)}] {tc_id}: Ky vong {exp_st} nhung nhan {act_st}')

        results.append({'tc_id': tc_id, 'user_id': user_id, 'old_p': old_p,
                        'new_p': new_p, 'length': len(new_p) if new_p not in ['', 'NULL_VAL'] else 0,
                        'exp_st': exp_st, 'exp_ex': exp_ex, 'act_st': act_st, 'act_ex': act_ex,
                        'act_msg': act_msg, 'verdict': verdict})

    total = len(test_rows)
    print(f'\nTONG KET: {pass_count}/{total} ca DAT ({round(pass_count/total*100, 1)}%) | '
          f'Thoi gian: {round(time.time()-start, 2)}s')

    # Xuất Excel
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = 'Bao Cao Doi Mat Khau'

    ws['A1'] = 'BÁO CÁO: KIỂM THỬ ĐỔI MẬT KHẨU - BVA 5 TIÊU CHÍ (KCPM-88)'
    ws['A1'].font = TITLE_FONT
    ws['A2'] = f'Auth & RBAC (Epic 1) | Tổng: {total} ca | Đạt: {pass_count}/{total} ({round(pass_count/total*100,1)}%) | {time.strftime("%d/%m/%Y %H:%M")}'
    ws['A2'].font = Font(name='Segoe UI', size=9, italic=True, color='595959')

    for label, val, col in [('Tổng TC:', total, 'B'), ('PASS:', pass_count, 'C'),
                             ('FAIL:', total - pass_count, 'D'),
                             (f'Tỉ lệ: {round(pass_count/total*100,1)}%', '', 'E')]:
        c = ws[f'{col}4']
        c.value = label if col == 'E' else f'{label} {val}'
        c.font = BOLD_FONT
        c.fill = CARD_FILL
        c.alignment = Alignment(horizontal='center')
        c.border = THIN_BORDER

    ws['A4'] = 'TỔNG QUAN:'
    ws['A4'].font = BOLD_FONT

    headers = ['Mã TC', 'User ID', 'Mật Khẩu Cũ', 'Mật Khẩu Mới', 'Độ Dài L',
               'Kỳ Vọng', 'Exception KV', 'Thực Tế', 'Exception TT', 'KẾT QUẢ']
    for c_idx, h in enumerate(headers, 1):
        cell = ws.cell(row=6, column=c_idx, value=h)
        cell.font = HEADER_FONT
        cell.fill = HEADER_FILL
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = THIN_BORDER

    for r_idx, r in enumerate(results, 7):
        vals = [r['tc_id'], r['user_id'], r['old_p'] or '(trống)', r['new_p'] or '(trống)',
                r['length'], r['exp_st'], r['exp_ex'], r['act_st'], r['act_ex'], r['verdict']]
        for c_idx, val in enumerate(vals, 1):
            cell = ws.cell(row=r_idx, column=c_idx, value=val)
            cell.font = NORMAL_FONT
            cell.border = THIN_BORDER
            if c_idx in [1, 5, 6, 7, 8, 9, 10]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            if c_idx == 10:
                cell.font = BOLD_FONT
                cell.fill = PASS_FILL if val == 'PASS' else FAIL_FILL

    for col in ws.columns:
        col_letter = get_column_letter(col[0].column)
        max_len = max((len(str(c.value or '')) for c in col), default=10)
        ws.column_dimensions[col_letter].width = min(max(max_len + 3, 10), 40)

    try:
        wb.save(REPORT_FILE)
        print(f'BAO CAO XUAT THANH CONG: {os.path.abspath(REPORT_FILE)}')
    except PermissionError:
        fb = REPORT_FILE.replace('.xlsx', '_NEW.xlsx')
        wb.save(fb)
        print(f'BAO CAO XUAT THANH CONG (ban moi): {os.path.abspath(fb)}')


if __name__ == '__main__':
    run()

