"""
SINH FILE TỔNG HỢP TEST CASE CHO TOÀN DỰ ÁN — docs/TEST_CASES_TONG_HOP.xlsx

Gom toàn bộ test case của 4 dạng kiểm thử, kèm KẾT QUẢ CHẠY THẬT gần nhất:
  1. White-box  : JUnit 5 (backend/src/test)          -> kết quả: backend/target/surefire-reports/*.xml
  2. Bruno API  : collection Bruno (YAML)              -> kết quả: qa-testing/reports/bruno_results.json
  3. QA hộp đen : qa-testing/data/*.csv (BVA/EP/DT)    -> kết quả: chạy lại các script run_*.py
  4. E2E        : CodeceptJS test-automation/epic-*    -> kết quả: test-automation/output/codeceptjs-report.json

Mỗi test case được gắn vào mục chức năng (1.1 -> 6.4) của docs/TEST_MATRIX.md để truy vết.

Chạy đầy đủ (backend phải đang bật):
  cd backend && mvn test && cd ..
  node qa-testing/scripts/bruno_runner.js "Flood Rescue Coordination & Relief Management API" qa-testing/reports/bruno_results.json
  (cd test-automation && npx codeceptjs run --reporter mochawesome)
  python3 qa-testing/scripts/generate_master_testcases.py
"""
import csv
import glob
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import Counter, OrderedDict
from datetime import datetime

import openpyxl
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BRUNO_DIR = os.path.join(ROOT, 'Flood Rescue Coordination & Relief Management API')
OUT_FILE = os.path.join(ROOT, 'docs', 'TEST_CASES_TONG_HOP.xlsx')

# ============================================================================
# DANH MỤC CHỨC NĂNG (đồng bộ docs/TEST_MATRIX.md)
# ============================================================================
FEATURES = OrderedDict([
    ('1.1', ('EPIC 01 - Dư Nhật Anh', 'Đăng nhập hệ thống & Cấp JWT Token')),
    ('1.2', ('EPIC 01 - Dư Nhật Anh', 'Đổi mật khẩu (BVA Min 6, Max 32)')),
    ('1.3', ('EPIC 01 - Dư Nhật Anh', 'Quản lý người dùng (Danh sách, Chi tiết, Tạo, Sửa)')),
    ('1.4', ('EPIC 01 - Dư Nhật Anh', 'Khóa / Mở khóa tài khoản')),
    ('1.5', ('EPIC 01 - Dư Nhật Anh', 'Gán / Đổi vai trò tài khoản')),
    ('1.6', ('EPIC 01 - Dư Nhật Anh', 'Quản lý vai trò & Ma trận phân quyền RBAC')),
    ('1.7', ('EPIC 01 - Dư Nhật Anh', 'Cấu hình & Dashboard hệ thống quản trị')),
    ('2.1', ('EPIC 02 - Lâm Khiêm', 'Gửi yêu cầu cứu nạn SOS')),
    ('2.2', ('EPIC 02 - Lâm Khiêm', 'Tra cứu tiến độ cứu hộ qua mã Tracking')),
    ('2.3', ('EPIC 02 - Lâm Khiêm', 'Lọc danh sách cứu nạn theo khu vực & trạng thái')),
    ('2.4', ('EPIC 02 - Lâm Khiêm', 'Hủy đơn / Cập nhật trạng thái đơn cứu nạn')),
    ('2.5', ('EPIC 02 - Lâm Khiêm', 'Báo an toàn công dân')),
    ('2.6', ('EPIC 02 - Lâm Khiêm', 'Nộp báo cáo cứu nạn hiện trường')),
    ('2.7', ('EPIC 02 - Lâm Khiêm', 'Upload ảnh hiện trường')),
    ('3.1', ('EPIC 03 - Phạm Minh Dũng', 'Điểm ngập trên radar (Danger Point)')),
    ('3.2', ('EPIC 03 - Phạm Minh Dũng', 'Xác minh & Gán độ khẩn cấp')),
    ('3.3', ('EPIC 03 - Phạm Minh Dũng', 'Lập lệnh phân công nhiệm vụ')),
    ('3.4', ('EPIC 03 - Phạm Minh Dũng', 'Cập nhật trạng thái nhiệm vụ')),
    ('3.5', ('EPIC 03 - Phạm Minh Dũng', 'Thay đổi phương tiện cho nhiệm vụ')),
    ('3.6', ('EPIC 03 - Phạm Minh Dũng', 'Đính kèm tệp hiện trường')),
    ('4.1', ('EPIC 04 - Nguyễn Bảo', 'Quản lý đội cứu nạn')),
    ('4.2', ('EPIC 04 - Nguyễn Bảo', 'Đăng ký & Cập nhật phương tiện cứu hộ')),
    ('4.3', ('EPIC 04 - Nguyễn Bảo', 'Máy trạng thái xe & đội')),
    ('4.4', ('EPIC 04 - Nguyễn Bảo', 'Lọc phương tiện sẵn sàng / danh sách xe')),
    ('4.5', ('EPIC 04 - Nguyễn Bảo', 'Lệnh xuất kích điều phối xe')),
    ('5.1', ('EPIC 05 - Phan Quốc Danh', 'Quản lý kho hàng')),
    ('5.2', ('EPIC 05 - Phan Quốc Danh', 'Danh mục nhu yếu phẩm')),
    ('5.3', ('EPIC 05 - Phan Quốc Danh', 'Nhập kho nhu yếu phẩm')),
    ('5.4', ('EPIC 05 - Phan Quốc Danh', 'Thẻ kho & Cảnh báo tồn kho thấp')),
    ('5.5', ('EPIC 05 - Phan Quốc Danh', 'Xuất kho cứu trợ (chặn âm kho)')),
    ('5.6', ('EPIC 05 - Phan Quốc Danh', 'Hủy phiếu xuất & Hoàn kho')),
    ('6.1', ('EPIC 06 - Dùng chung', 'Gửi thông báo khẩn cấp')),
    ('6.2', ('EPIC 06 - Dùng chung', 'Đọc & quản lý thông báo')),
    ('6.3', ('EPIC 06 - Dùng chung', 'Báo cáo thống kê & phân tích')),
    ('6.4', ('EPIC 06 - Dùng chung', 'Upload tập tin hệ thống chung')),
])

TYPE_WB, TYPE_BRUNO, TYPE_QA, TYPE_E2E = 'White-box (JUnit 5)', 'API (Bruno)', 'Black-box (QA Data-Driven)', 'E2E (CodeceptJS)'
ST_PASS, ST_FAIL, ST_NA = 'PASS', 'FAIL', 'CHƯA CHẠY'

rows = []  # mỗi phần tử là dict một test case


def add(**kw):
    kw.setdefault('note', '')
    kw.setdefault('jira', '')
    rows.append(kw)


def technique_of(text):
    t = text.upper()
    if 'BVA' in t or 'BIÊN' in t.upper():
        return 'BVA (Giá trị biên)'
    if re.search(r'\bEP\b', t) or 'PHÂN VÙNG' in t:
        return 'EP (Phân vùng tương đương)'
    if 'DECISION' in t or 'BẢNG QUYẾT ĐỊNH' in t:
        return 'Decision Table'
    if 'STATE' in t or 'MÁY TRẠNG THÁI' in t:
        return 'State Transition'
    if 'RBAC' in t or '401' in t or '403' in t:
        return 'Phân quyền (RBAC)'
    if 'WORKFLOW' in t:
        return 'Luồng nghiệp vụ'
    if 'NEGATIVE' in t or re.search(r'\b(400|404|409|500)\b', t) or 'CHẶN' in t or 'THẤT BẠI' in t:
        return 'Ca lỗi (Negative)'
    return 'Ca hợp lệ (Positive)'


# ============================================================================
# 1. WHITE-BOX — JUnit 5
# ============================================================================
JUNIT_FEATURE = {
    'AuthControllerTest': '1.1', 'UserServiceTest': '1.2', 'RoleServiceTest': '1.6',
    'RbacAuthorizationTest': '1.6', 'AccessDeniedStatusTest': '1.6', 'AdminSystemControllerTest': '1.7',
    'RescueRequestValidationTest': '2.1', 'RescueRequestFilterAndCancelTest': '2.3',
    'ReportAndSafetyReportValidationTest': '2.5', 'RescueReportControllerTest': '2.6', 'FileUploadControllerTest': '2.7',
    'DangerPointServiceTest': '3.1', 'RescueCoordinationServiceTest': '3.3', 'VehiclesServiceValidationTest': '4.2',
    'WarehouseServiceTest': '5.1', 'ReliefItemServiceTest': '5.2', 'InventoryServiceTest': '5.3',
    'DistributionServiceTest': '5.5', 'DistributionControllerTest': '5.6', 'NotificationControllerTest': '6.1',
}


def junit_feature(cls, name):
    n = name.upper()
    if cls == 'UserAccountManagementTest':
        return '1.4' if 'LOCK' in n else '1.5'
    if cls == 'Sprint2ModuleFixesTest':
        if 'TEAM' in n:
            return '4.1'
        if 'ASSIGNMENT' in n:
            return '4.3'
        if 'BVA-06' in n:
            return '4.4'
        return '4.2'
    if cls == 'RescueRequestFilterAndCancelTest' and ('HỦY' in n or 'CANCEL' in n):
        return '2.4'
    if cls == 'ReportAndSafetyReportValidationTest' and ('REPORT' in n and 'SAFETY' not in n or 'BÁO CÁO' in n):
        return '6.3'
    if cls == 'DistributionServiceTest' and ('KCPM-103' in n or 'HỦY' in n):
        return '5.6'
    if cls == 'InventoryServiceTest' and ('LOW' in n or 'THẺ KHO' in n or 'CẠN' in n):
        return '5.4'
    if cls == 'NotificationControllerTest' and ('ĐỌC' in n or 'UNREAD' in n or 'READ' in n):
        return '6.2'
    if cls == 'RescueCoordinationServiceTest':
        if 'TC_ASSIGN' in n:
            return '3.3'
        if 'TC_STATUS' in n:
            return '3.4'
        if 'URGENCY' in n or 'KHẨN CẤP' in n or 'XÁC MINH' in n or 'VERIFY' in n:
            return '3.2'
        if 'STATUS' in n or 'TRẠNG THÁI' in n:
            return '3.4'
        if 'VEHICLE' in n or 'ĐỔI XE' in n or 'PHƯƠNG TIỆN' in n:
            return '3.5'
    return JUNIT_FEATURE.get(cls, '')


def load_junit():
    # DisplayName của từng method lấy trực tiếp từ mã nguồn test
    display = {}
    for path in glob.glob(os.path.join(ROOT, 'backend', 'src', 'test', 'java', '**', '*.java'), recursive=True):
        src = open(path, encoding='utf-8').read()
        cls = os.path.splitext(os.path.basename(path))[0]
        for m in re.finditer(r'@DisplayName\("((?:[^"\\]|\\.)*)"\)\s*(?:@\w+\s*)*void\s+(\w+)\s*\(', src):
            display[(cls, m.group(2))] = m.group(1).replace('\\"', '"')
    results = {}
    for xml_path in glob.glob(os.path.join(ROOT, 'backend', 'target', 'surefire-reports', 'TEST-*.xml')):
        for tc in ET.parse(xml_path).getroot().iter('testcase'):
            cls = tc.get('classname').split('.')[-1]
            failed = tc.find('failure') is not None or tc.find('error') is not None
            results[(cls, tc.get('name'))] = (ST_FAIL if failed else ST_PASS, tc.get('time'))
    for (cls, method), name in sorted(display.items()):
        status, _ = results.get((cls, method), (ST_NA, None))
        expected = name.split('->', 1)[1].strip() if '->' in name else name
        jira = ', '.join(sorted(set(re.findall(r'KCPM-\d+', name))))
        add(type=TYPE_WB, feature=junit_feature(cls, name), tc_id=f'{cls}.{method}', name=name,
            technique=technique_of(name), input=f'Gọi trực tiếp {cls} (Mockito mock repository)',
            expected=expected, actual='Đúng như kỳ vọng' if status == ST_PASS else ('Sai kỳ vọng' if status == ST_FAIL else ''),
            status=status, source=f'backend/src/test/.../{cls}.java', jira=jira)


# ============================================================================
# 2. BRUNO API
# ============================================================================
BRUNO_FEATURE = {
    'AdminSystem': '1.7', 'Role': '1.6', 'RescueRequest': '2.1', 'SafetyReport': '2.5', 'RescueReport': '2.6',
    'FileUpload': '2.7', 'DangerPoint': '3.1', 'RescueCoordination': '3.2', 'Attachment': '3.6', 'Team': '4.1',
    'Vehicles': '4.2', 'VehicleAssignment': '4.5', 'Warehouse': '5.1', 'ReliefItem': '5.2', 'Inventory': '5.3',
    'Distribution': '5.5', 'Notification': '6.1', 'Report': '6.3', 'File': '6.4',
}


def bruno_feature(folder, name, url):
    n, u = name.upper(), (url or '')
    if folder == 'Auth':
        if 'KCPM-100' in n:
            return '1.4'
        return '1.2' if 'change-password' in u or 'MẬT KHẨU' in n else '1.1'
    if folder == 'AdminUser':
        if '/status' in u:
            return '1.4'
        if '/role' in u:
            return '1.5'
        return '1.3'
    if folder == 'Assignment':
        if '/status' in u:
            return '3.4'
        if '/vehicle' in u:
            return '3.5'
        return '3.3'
    if folder == 'RescueRequest':
        if '/track' in u:
            return '2.2'
        if '/cancel' in u or '/status' in u or 'confirm-safety' in u:
            return '2.4'
        if 'GET' in n and '?' in u:
            return '2.3'
    if folder == 'Inventory' and ('low-stock' in u or '/warehouse/' in u):
        return '5.4'
    if folder == 'Distribution' and ('cancel' in u or 'complete' in u):
        return '5.6'
    if folder == 'Vehicles' and ('available' in u or ('GET' in n and 'statistics' not in u)):
        return '4.4'
    if folder == 'Notification' and 'POST' not in n:
        return '6.2'
    return BRUNO_FEATURE.get(folder, '')


def _load_yaml(path):
    """Đọc YAML của Bruno bằng js-yaml qua Node (không cần cài PyYAML)."""
    js = ("const y=require(process.argv[1]);const fs=require('fs');"
          "process.stdout.write(JSON.stringify(y.load(fs.readFileSync(process.argv[2],'utf8'))))")
    nm = os.path.join(ROOT, 'test-automation', 'node_modules', 'js-yaml')
    return json.loads(subprocess.check_output(['node', '-e', js, nm, path]))


def load_bruno_all():
    result_file = os.path.join(ROOT, 'qa-testing', 'reports', 'bruno_results.json')
    results = {}
    if os.path.exists(result_file):
        for r in json.load(open(result_file, encoding='utf-8')):
            failed = r.get('netErr') or any(not t['ok'] for t in r['tests'])
            status = ST_FAIL if failed else (ST_PASS if r['tests'] else 'KHÔNG CÓ ASSERT')
            results[(r['folder'], r['file'])] = (status, r.get('status'), r.get('message'))
    files = []
    for folder in sorted(os.listdir(BRUNO_DIR)):
        fdir = os.path.join(BRUNO_DIR, folder)
        if not os.path.isdir(fdir) or folder == 'environments':
            continue
        for fn in os.listdir(fdir):
            if fn.endswith('.yml') and fn != 'folder.yml':
                files.append((folder, fn))
    docs = json.loads(subprocess.check_output(
        ['node', '-e',
         "const y=require(process.argv[1]);const fs=require('fs');const path=require('path');"
         "const out=JSON.parse(process.argv[3]).map(([d,f])=>{const doc=y.load(fs.readFileSync(path.join(process.argv[2],d,f),'utf8'));return [d,f,doc]});"
         "process.stdout.write(JSON.stringify(out))",
         os.path.join(ROOT, 'test-automation', 'node_modules', 'js-yaml'), BRUNO_DIR, json.dumps(files)]))
    folder_seq = {}
    for folder in {d for d, _, _ in docs}:
        meta = _load_yaml(os.path.join(BRUNO_DIR, folder, 'folder.yml'))
        folder_seq[folder] = meta.get('info', {}).get('seq', 99)
    docs.sort(key=lambda x: (folder_seq.get(x[0], 99), (x[2].get('info') or {}).get('seq', 99)))
    for folder, fn, doc in docs:
        info, http = doc.get('info') or {}, doc.get('http') or {}
        name, url = info.get('name', fn), (http.get('url') or '').replace('{{baseUrl}}', '')
        code = ''.join(s.get('code', '') for s in (doc.get('runtime') or {}).get('scripts', []) if s.get('type') == 'after-response')
        exp = re.findall(r'getStatus\(\)\)\.to\.equal\((\d+)\)', code)
        one_of = re.findall(r'getStatus\(\)\)\.to\.be\.oneOf\(\[([^\]]+)\]', code)
        expected = f'HTTP {exp[0]}' if exp else (f'HTTP thuộc [{one_of[0]}]' if one_of else 'Không có assert')
        checks = re.findall(r'test\("([^"]+)"', code)
        if checks:
            expected += ' | ' + '; '.join(checks)[:250]
        body = ((http.get('body') or {}).get('data') or '').strip()
        status, act_code, act_msg = results.get((folder, fn), (ST_NA, None, None))
        note = ''
        if 'Chuẩn bị' in name:
            note = 'Request chuẩn bị dữ liệu cho các ca phía sau'
        elif one_of:
            note = 'Assert lỏng (chỉ kiểm tra 2xx) - nên bổ sung kiểm tra dữ liệu trả về'
        jira = ', '.join(sorted(set(re.findall(r'KCPM-\d+', name))))
        add(type=TYPE_BRUNO, feature=bruno_feature(folder, name, url), tc_id=f'{folder}/{fn[:-4]}', name=name,
            technique=technique_of(name + ' ' + expected), input=f'{http.get("method", "")} {url}' + (f'\nBody: {body[:300]}' if body else ''),
            expected=expected, actual=(f'HTTP {act_code}' + (f' - {act_msg}' if act_msg else '')) if act_code else '',
            status=status, source=f'Bruno/{folder}/{fn}', jira=jira, note=note)


# ============================================================================
# 3. QA HỘP ĐEN — CSV + script run_*.py
# ============================================================================
QA_FILES = [
    # (csv, script, mục mặc định, kỹ thuật, gọi backend thật?, mã Jira)
    ('auth_login_data.csv', 'run_login.py', '1.1', 'EP (Phân vùng tương đương)', True, 'KCPM-89'),
    ('auth_change_password_data.csv', 'run_change_password.py', '1.2', 'BVA (Giá trị biên)', True, 'KCPM-88'),
    ('auth_rbac_data.csv', 'run_rbac.py', '1.6', 'Decision Table', True, 'KCPM-90'),
    ('citizen_rescue_request_data.csv', 'run_rescue_request.py', '2.1', 'BVA (Giá trị biên)', False, 'KCPM-91'),
    ('citizen_safety_report_data.csv', 'run_safety_report.py', '2.5', 'EP (Phân vùng tương đương)', False, 'KCPM-94'),
    ('danger_point_radar_data.csv', 'run_danger_point.py', '3.1', 'BVA (Giá trị biên)', False, 'KCPM-93'),
    ('coordination_dispatch_data.csv', 'run_coordination_dispatch.py', '3.2', 'Decision Table', False, 'KCPM-95'),
    ('teams_availability_data.csv', 'run_teams.py', '4.3', 'State Transition', False, 'KCPM-97'),
    ('vehicles_management_data.csv', 'run_vehicles.py', '4.2', 'BVA (Giá trị biên)', False, 'KCPM-96'),
    ('inventory_import_data.csv', 'run_inventory.py', '5.3', 'BVA (Giá trị biên)', False, 'KCPM-98'),
    ('distribution_export_data.csv', 'run_distribution.py', '5.5', 'Decision Table', False, 'KCPM-99'),
]


def run_qa_script(script):
    """Chạy script QA và đọc kết quả từng TC từ console (OK / FAIL / -- JUnit)."""
    try:
        out = subprocess.run([sys.executable, os.path.join('qa-testing', 'scripts', script)], cwd=ROOT,
                             capture_output=True, text=True, timeout=300, encoding='utf-8').stdout
    except Exception as e:  # noqa: BLE001
        print(f'  ! Không chạy được {script}: {e}')
        return {}
    res = {}
    for line in out.splitlines():
        m = re.match(r'\s*\[?(OK|FAIL|--)\]?\s+\[\d+/\d+\]\s+(TC_\w+)', line)
        if m:
            res[m.group(2)] = {'OK': ST_PASS, 'FAIL': ST_FAIL, '--': 'JUNIT'}[m.group(1)]
    return res


def load_qa(run_scripts=True):
    for csv_name, script, feat, tech, live, jira in QA_FILES:
        path = os.path.join(ROOT, 'qa-testing', 'data', csv_name)
        if not os.path.exists(path):
            continue
        print(f'  - QA {csv_name}')
        res = run_qa_script(script) if run_scripts else {}
        with open(path, encoding='utf-8') as f:
            for r in csv.DictReader(f):
                tc = r.get('testCaseId') or next(iter(r.values()))
                exp_code = r.get('expectedHttpCode') or ''
                exp_msg = r.get('expectedMessage') or r.get('expectedNextState') or r.get('expectedUrgency') or ''
                exp_status = r.get('expectedStatus') or ''
                expected = ' | '.join(x for x in [exp_status, f'HTTP {exp_code}' if exp_code else '', exp_msg] if x)
                skip = {'testCaseId', 'expectedStatus', 'expectedHttpCode', 'expectedMessage', 'expectedException'}
                inputs = '; '.join(f'{k}={v}' for k, v in r.items() if k not in skip and not k.startswith('expected') and v != '')
                f_id = feat
                if csv_name == 'citizen_safety_report_data.csv' and tc.startswith('TC_TRK'):
                    f_id = '2.2'
                desc = r.get('boundaryType') or r.get('partitionType') or r.get('decisionRule') or r.get('ruleName') or r.get('transitionType') or ''
                status = res.get(tc, ST_NA)
                note = '' if live else 'Script mô phỏng logic bằng Python, CHƯA gọi backend thật'
                if status == 'JUNIT':
                    status, note = ST_NA, 'Không tái hiện được qua API - đã kiểm thử ở JUnit'
                add(type=TYPE_QA, feature=f_id, tc_id=tc, name=desc or tc, technique=tech, input=inputs[:400],
                    expected=expected, actual='Đúng như kỳ vọng' if status == ST_PASS else ('Sai kỳ vọng' if status == ST_FAIL else ''),
                    status=status, source=f'qa-testing/data/{csv_name}', jira=jira, note=note)


# ============================================================================
# 4. E2E — CodeceptJS
# ============================================================================
def e2e_feature(title):
    m = re.search(r'E2E-(\d\d)-(\d\d)', title)
    if m:
        epic, no = m.group(1), int(m.group(2))
        table = {
            '01': {1: '1.1', 2: '1.1', 3: '1.2', 4: '1.2', 5: '1.3', 6: '1.4', 7: '1.6'},
            '03': {1: '3.3', 2: '3.3', 3: '3.3', 4: '4.5', 5: '3.5', 6: '3.4', 7: '3.1', 8: '3.1', 9: '3.2'},
            '04': {1: '4.1', 2: '4.1', 3: '4.1', 4: '4.1', 5: '4.2', 6: '4.2', 7: '4.2', 8: '4.4', 9: '4.4',
                   10: '4.2', 11: '4.3', 12: '4.3', 13: '4.2'},
            '06': {1: '2.7', 2: '6.1', 3: '6.1', 4: '6.2', 5: '6.1', 6: '2.5', 7: '6.3', 8: '6.3', 9: '2.5', 10: '6.3', 11: '6.3'},
        }
        return table.get(epic, {}).get(no, '')
    if 'KCPM-110' in title:
        if 'Scenario 1' in title or 'Scenario 4' in title:
            return '2.1'
        if 'Scenario 3' in title:
            return '2.4'
        return '2.5'
    if 'KCPM-116' in title:
        return {'SCENARIO 1': '5.1', 'SCENARIO 2': '5.3', 'SCENARIO 3': '5.5', 'SCENARIO 4': '5.5', 'SCENARIO 5': '5.6'}.get(
            (re.search(r'SCENARIO \d', title) or [''])[0], '')
    return ''


def load_e2e():
    report = os.path.join(ROOT, 'test-automation', 'output', 'codeceptjs-report.json')
    if not os.path.exists(report):
        return
    data = json.load(open(report, encoding='utf-8'))

    def walk(suite, feature_title):
        for t in suite.get('tests', []):
            title = t['title']
            status = ST_PASS if t['state'] == 'passed' else (ST_FAIL if t['state'] == 'failed' else ST_NA)
            codes = re.findall(r'seeResponseCodeIs\((\d+)\)', t.get('code', ''))
            endpoint = (re.findall(r'\[((?:GET|POST|PUT|PATCH|DELETE)[^\]]*)\]', title) or [''])[-1]
            add(type=TYPE_E2E, feature=e2e_feature(title), tc_id=(re.search(r'E2E-\d\d-\d\d|Scenario \d|SCENARIO \d', title) or [''])[0],
                name=title, technique=technique_of(title), input=endpoint or 'Chuỗi nhiều API (xem tên kịch bản)',
                expected=('HTTP ' + ' -> '.join(dict.fromkeys(codes))) if codes else 'Theo các assert trong kịch bản',
                actual=f'{t["state"]} ({t.get("duration", 0)} ms)' + (f' - {t["err"].get("message", "")[:150]}' if t.get('err') else ''),
                status=status, source=feature_title, jira=', '.join(sorted(set(re.findall(r'KCPM-\d+', title)))))
        for s in suite.get('suites', []):
            walk(s, s.get('title') or feature_title)

    for r in data['results']:
        walk(r, r.get('file', ''))
    return data['stats']


# ============================================================================
# XUẤT EXCEL
# ============================================================================
THIN = Side(style='thin', color='BFBFBF')
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
HEAD_FILL = PatternFill('solid', fgColor='1F4E78')
HEAD_FONT = Font(bold=True, color='FFFFFF', size=11)
STATUS_FILL = {ST_PASS: PatternFill('solid', fgColor='C6EFCE'), ST_FAIL: PatternFill('solid', fgColor='FFC7CE'),
               ST_NA: PatternFill('solid', fgColor='FFEB9C'), 'KHÔNG CÓ ASSERT': PatternFill('solid', fgColor='FFEB9C')}
WRAP = Alignment(wrap_text=True, vertical='top')
CENTER = Alignment(horizontal='center', vertical='center', wrap_text=True)


def write_table(ws, start_row, headers, data, widths):
    for c, h in enumerate(headers, 1):
        cell = ws.cell(row=start_row, column=c, value=h)
        cell.fill, cell.font, cell.alignment, cell.border = HEAD_FILL, HEAD_FONT, CENTER, BORDER
    for r, values in enumerate(data, start_row + 1):
        for c, v in enumerate(values, 1):
            cell = ws.cell(row=r, column=c, value=v)
            cell.alignment, cell.border = WRAP, BORDER
    for c, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(c)].width = w
    ws.freeze_panes = ws.cell(row=start_row + 1, column=1)
    ws.auto_filter.ref = f'A{start_row}:{get_column_letter(len(headers))}{start_row + len(data)}'


def build_workbook(e2e_stats):
    wb = openpyxl.Workbook()
    by_type = Counter(r['type'] for r in rows)
    status_by_type = Counter((r['type'], r['status']) for r in rows)
    types = [TYPE_WB, TYPE_BRUNO, TYPE_QA, TYPE_E2E]

    # ---------- Sheet 1: Tổng quan ----------
    ws = wb.active
    ws.title = 'Tổng quan'
    ws['A1'] = 'TỔNG HỢP TEST CASE - HỆ THỐNG ĐIỀU PHỐI CỨU HỘ LŨ LỤT & QUẢN LÝ CỨU TRỢ'
    ws['A1'].font = Font(bold=True, size=15, color='1F4E78')
    ws['A2'] = f'Sinh tự động lúc {datetime.now():%d/%m/%Y %H:%M} bằng qa-testing/scripts/generate_master_testcases.py - kết quả lấy từ lần chạy thật gần nhất trên backend.'
    ws['A2'].font = Font(italic=True, color='595959')
    summary = []
    for t in types:
        total = by_type[t]
        p, f = status_by_type[(t, ST_PASS)], status_by_type[(t, ST_FAIL)]
        other = total - p - f
        rate = f'{p / (p + f) * 100:.1f}%' if (p + f) else '-'
        summary.append([t, total, p, f, other, rate])
    tot = [sum(x[i] for x in summary) for i in range(1, 5)]
    summary.append(['TỔNG CỘNG', *tot, f'{tot[1] / (tot[1] + tot[2]) * 100:.1f}%' if (tot[1] + tot[2]) else '-'])
    write_table(ws, 4, ['Dạng kiểm thử', 'Tổng TC', 'PASS', 'FAIL', 'Chưa chạy / N/A', 'Tỉ lệ đạt'], summary, [34, 12, 10, 10, 18, 12])
    for c in range(1, 7):
        ws.cell(row=4 + len(summary), column=c).font = Font(bold=True)
    note_row = 6 + len(summary)
    notes = [
        'Ghi chú:',
        '• Tỉ lệ đạt = PASS / (PASS + FAIL). Ca "Chưa chạy / N/A" gồm ca chỉ kiểm thử được ở JUnit và ca chưa có kết quả.',
        '• QA hộp đen Epic 01 gọi backend thật; QA các Epic khác hiện vẫn là script mô phỏng logic (cột Ghi chú).',
        '• Sheet "Ma trận truy vết" cho biết mỗi chức năng được bao phủ bởi bao nhiêu TC của từng dạng kiểm thử.',
    ]
    for i, n in enumerate(notes):
        ws.cell(row=note_row + i, column=1, value=n).font = Font(bold=(i == 0))

    # ---------- Sheet 2: Danh sách test case ----------
    ws = wb.create_sheet('Danh sách Test Case')
    headers = ['STT', 'Epic', 'Mục', 'Chức năng', 'Dạng kiểm thử', 'Mã TC', 'Tên / Mô tả test case', 'Kỹ thuật',
               'Dữ liệu vào / Request', 'Kết quả mong đợi', 'Kết quả thực tế', 'Trạng thái', 'Mã Jira', 'File nguồn', 'Ghi chú']
    order = {k: i for i, k in enumerate(FEATURES)}
    type_order = {t: i for i, t in enumerate(types)}
    data = []
    for i, r in enumerate(sorted(rows, key=lambda x: (order.get(x['feature'], 999), type_order[x['type']])), 1):
        epic, fname = FEATURES.get(r['feature'], ('Chưa phân loại', ''))
        data.append([i, epic, r['feature'], fname, r['type'], r['tc_id'], r['name'], r['technique'], r['input'],
                     r['expected'], r['actual'], r['status'], r['jira'], r['source'], r['note']])
    write_table(ws, 1, headers, data, [6, 22, 6, 30, 20, 26, 55, 20, 45, 45, 35, 12, 14, 34, 34])
    for row in range(2, len(data) + 2):
        cell = ws.cell(row=row, column=12)
        cell.alignment = CENTER
        if cell.value in STATUS_FILL:
            cell.fill = STATUS_FILL[cell.value]
    dv = DataValidation(type='list', formula1=f'"{ST_PASS},{ST_FAIL},{ST_NA}"', allow_blank=True)
    ws.add_data_validation(dv)
    dv.add(f'L2:L{len(data) + 1}')

    # ---------- Sheet 3: Ma trận truy vết ----------
    ws = wb.create_sheet('Ma trận truy vết')
    matrix = []
    for fid, (epic, fname) in FEATURES.items():
        counts = [sum(1 for r in rows if r['feature'] == fid and r['type'] == t) for t in types]
        fails = sum(1 for r in rows if r['feature'] == fid and r['status'] == ST_FAIL)
        missing = [t.split(' ')[0] for t, c in zip(types, counts) if c == 0]
        matrix.append([fid, epic, fname, *counts, sum(counts), fails, ('Thiếu: ' + ', '.join(missing)) if missing else 'Đủ 4 dạng'])
    write_table(ws, 1, ['Mục', 'Epic', 'Chức năng', 'White-box', 'Bruno', 'QA', 'E2E', 'Tổng', 'Số FAIL', 'Độ bao phủ'],
                matrix, [7, 24, 42, 11, 9, 7, 7, 8, 9, 34])
    for row in range(2, len(matrix) + 2):
        for col in range(4, 10):
            c = ws.cell(row=row, column=col)
            c.alignment = CENTER
            if col <= 7 and c.value == 0:
                c.fill = PatternFill('solid', fgColor='FFC7CE')
        cov = ws.cell(row=row, column=10)
        cov.fill = STATUS_FILL[ST_PASS] if cov.value == 'Đủ 4 dạng' else STATUS_FILL[ST_NA]

    # ---------- Sheet 4..7: mỗi dạng kiểm thử một sheet ----------
    short = {TYPE_WB: 'White-box JUnit', TYPE_BRUNO: 'Bruno API', TYPE_QA: 'QA Data-Driven', TYPE_E2E: 'E2E CodeceptJS'}
    for t in types:
        ws = wb.create_sheet(short[t])
        sub = [d for d in data if d[4] == t]
        write_table(ws, 1, headers, sub, [6, 22, 6, 30, 20, 26, 55, 20, 45, 45, 35, 12, 14, 34, 34])
        for row in range(2, len(sub) + 2):
            cell = ws.cell(row=row, column=12)
            cell.alignment = CENTER
            if cell.value in STATUS_FILL:
                cell.fill = STATUS_FILL[cell.value]
    return wb


def main():
    run_qa = '--skip-qa' not in sys.argv
    print('Đang gom test case...')
    print('  - White-box JUnit'); load_junit()
    print('  - Bruno API'); load_bruno_all()
    load_qa(run_scripts=run_qa)
    print('  - E2E CodeceptJS'); e2e_stats = load_e2e()
    unmapped = [r for r in rows if r['feature'] not in FEATURES]
    wb = build_workbook(e2e_stats)
    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    wb.save(OUT_FILE)
    c = Counter(r['type'] for r in rows)
    s = Counter(r['status'] for r in rows)
    print(f'\nĐã xuất {len(rows)} test case -> {os.path.relpath(OUT_FILE, ROOT)}')
    for t, n in c.items():
        print(f'   {t:30s} {n}')
    print(f'   Trạng thái: {dict(s)}')
    if unmapped:
        print(f'   ! {len(unmapped)} TC chưa gắn được mục chức năng: ' + ', '.join(r["tc_id"] for r in unmapped[:15]))


if __name__ == '__main__':
    main()
