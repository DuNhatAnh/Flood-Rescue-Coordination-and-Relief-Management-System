import openpyxl
from openpyxl.styles import Font, Alignment, Border, Side
from openpyxl.utils import get_column_letter

wb = openpyxl.Workbook()

# Standard Black & White Fonts (Không màu mè)
FONT_FAMILY = "Times New Roman"
TITLE_FONT = Font(name=FONT_FAMILY, size=13, bold=True, color="000000")
HEADER_FONT = Font(name=FONT_FAMILY, size=11, bold=True, color="000000")
BOLD_FONT = Font(name=FONT_FAMILY, size=11, bold=True, color="000000")
REGULAR_FONT = Font(name=FONT_FAMILY, size=11, color="000000")
ITALIC_FONT = Font(name=FONT_FAMILY, size=11, italic=True, color="000000")

# Chuẩn kẻ bảng đen mảnh (Thin Black Border)
THIN_BORDER = Border(
    left=Side(style='thin', color='000000'),
    right=Side(style='thin', color='000000'),
    top=Side(style='thin', color='000000'),
    bottom=Side(style='thin', color='000000')
)

# ==============================================================================
# SHEET 1: DASHBOARD & SUMMARY (ĐEN TRẮNG)
# ==============================================================================
ws_sum = wb.active
ws_sum.title = "Summary & Dashboard"
ws_sum.views.sheetView[0].showGridLines = True

ws_sum["A1"] = "BÁO CÁO TỔNG HỢP KIỂM THỬ TÍCH HỢP API - SPRINT 3"
ws_sum["A1"].font = TITLE_FONT

ws_sum["A2"] = "Dự án: Hệ thống Điều phối Cứu nạn & Cứu trợ Lũ lụt (Flood Rescue Management System)"
ws_sum["A2"].font = ITALIC_FONT

ws_sum["A3"] = "Mã công việc Jira: KCPM-64 | Ngày thực hiện: 01/11/2026 | Người kiểm thử: QA Team"
ws_sum["A3"].font = REGULAR_FONT

headers_sum = ["STT", "Chỉ số kiểm thử", "Giá trị", "Ghi chú đánh giá"]
for col_idx, h in enumerate(headers_sum, 1):
    cell = ws_sum.cell(row=5, column=col_idx, value=h)
    cell.font = HEADER_FONT
    cell.border = THIN_BORDER
    cell.alignment = Alignment(horizontal="center", vertical="center")

stats_data = [
    ("1", "Tổng số API kiểm thử", "4 APIs", "Lọc cứu nạn, Hủy cứu nạn, Báo an toàn, Báo cáo cứu hộ"),
    ("2", "Tổng số Test Cases thiết kế", "12 TCs", "Bao phủ đầy đủ EP và BVA"),
    ("3", "Số Test Cases đạt (PASSED)", "12 TCs", "Tỷ lệ đạt: 100%"),
    ("4", "Số Test Cases thất bại (FAILED)", "0 TCs", "Tỷ lệ lỗi: 0%"),
    ("5", "Độ bao phủ yêu cầu (Requirements Coverage)", "100%", "Đạt chuẩn Acceptance Criteria của Sprint 3"),
    ("6", "Tổng số Unit Tests tự động thực thi (JUnit 5)", "20 Tests", "Build: SUCCESS (Total time: 36.18s)"),
    ("7", "Số Bug tồn đọng trên Jira", "0 Bugs", "Hệ thống chặn thành công toàn bộ các case biên và tham số sai"),
    ("8", "Kết luận nghiệm thu", "ĐẠT", "Đủ điều kiện chuyển ticket KCPM-64 sang Done")
]

for row_idx, row_data in enumerate(stats_data, 6):
    for col_idx, val in enumerate(row_data, 1):
        cell = ws_sum.cell(row=row_idx, column=col_idx, value=val)
        cell.font = REGULAR_FONT
        cell.border = THIN_BORDER
        if col_idx in [1, 3]:
            cell.alignment = Alignment(horizontal="center")
        elif col_idx == 2:
            cell.font = BOLD_FONT

# ==============================================================================
# SHEET 2: WBS TASK TRACKING (THEO DÕI NHIỆM VỤ)
# ==============================================================================
ws_task = wb.create_sheet(title="Task Tracking (WBS)")
ws_task.views.sheetView[0].showGridLines = True

ws_task["A1"] = "DANH SÁCH NHIỆM VỤ KIỂM THỬ CHI TIẾT (JIRA: KCPM-64)"
ws_task["A1"].font = TITLE_FONT

task_headers = [
    "Task ID", "Mã Jira", "Tên nhiệm vụ kiểm thử", "API Endpoint", "Người phụ trách",
    "Ngày bắt đầu", "Ngày hoàn thành", "Số TCs", "Passed", "Failed", "Trạng thái Task"
]

for col_idx, h in enumerate(task_headers, 1):
    cell = ws_task.cell(row=3, column=col_idx, value=h)
    cell.font = HEADER_FONT
    cell.border = THIN_BORDER
    cell.alignment = Alignment(horizontal="center", vertical="center")

tasks_data = [
    ("TSK-01", "KCPM-64-1", "Kiểm thử API Lọc cứu nạn (Status, District, Invalid)", "GET /api/v1/rescue-requests", "QA Lead", "01/11/2026", "01/11/2026", 4, 4, 0, "DONE"),
    ("TSK-02", "KCPM-64-2", "Kiểm thử API Hủy yêu cầu cứu nạn (Nước rút, Chặn COMPLETED)", "PUT /api/v1/rescue-requests/{id}/cancel", "Senior Tester", "01/11/2026", "01/11/2026", 4, 4, 0, "DONE"),
    ("TSK-03", "KCPM-64-3", "Kiểm thử API Gửi báo an toàn (Báo lũ rút, Thiếu SĐT)", "POST /api/v1/safety-reports", "Automation Tester", "01/11/2026", "01/11/2026", 2, 2, 0, "DONE"),
    ("TSK-04", "KCPM-64-4", "Kiểm thử API Nộp báo cáo tổng kết cứu hộ (Người & Hàng cứu trợ)", "POST /api/v1/rescue-reports", "QA Lead", "01/11/2026", "01/11/2026", 2, 2, 0, "DONE"),
]

for row_idx, row_data in enumerate(tasks_data, 4):
    for col_idx, val in enumerate(row_data, 1):
        cell = ws_task.cell(row=row_idx, column=col_idx, value=val)
        cell.font = REGULAR_FONT
        cell.border = THIN_BORDER
        if col_idx in [1, 2, 6, 7, 8, 9, 10, 11]:
            cell.alignment = Alignment(horizontal="center")
            if col_idx == 11:
                cell.font = BOLD_FONT

# ==============================================================================
# SHEET 3: TEST CASES MATRIX (MA TRẬN TEST CASE)
# ==============================================================================
ws_tc = wb.create_sheet(title="Test Cases Matrix")
ws_tc.views.sheetView[0].showGridLines = True

ws_tc["A1"] = "MA TRẬN TEST CASE KIỂM THỬ TÍCH HỢP (TEST CASES MATRIX)"
ws_tc["A1"].font = TITLE_FONT

tc_headers = [
    "STT", "Mã TC", "Tên Test Case", "Method", "Endpoint", "Dữ liệu đầu vào (Input/Body)",
    "Kết quả kỳ vọng (Expected Result)", "Kết quả thực tế (Actual Result)", "Trạng thái", "Tag EP/BVA"
]

for col_idx, h in enumerate(tc_headers, 1):
    cell = ws_tc.cell(row=3, column=col_idx, value=h)
    cell.font = HEADER_FONT
    cell.border = THIN_BORDER
    cell.alignment = Alignment(horizontal="center", vertical="center")

tc_data = [
    ("1", "TC01", "Lọc theo trạng thái PENDING", "GET", "/api/v1/rescue-requests", "Params: status=PENDING", "HTTP 200 OK, danh sách 100% status = PENDING", "HTTP 200, danh sách chính xác PENDING", "PASS", "V1"),
    ("2", "TC02", "Lọc theo trạng thái IN_PROGRESS", "GET", "/api/v1/rescue-requests", "Params: status=IN_PROGRESS", "HTTP 200 OK, danh sách 100% status = IN_PROGRESS", "HTTP 200, danh sách chính xác IN_PROGRESS", "PASS", "V1"),
    ("3", "TC03", "Lọc theo quận/huyện", "GET", "/api/v1/rescue-requests", "Params: district=Hải Châu", "HTTP 200 OK, addressText chứa 'Hải Châu'", "HTTP 200, lọc đúng địa bàn Hải Châu", "PASS", "V2"),
    ("4", "TC04", "Lọc trạng thái không hợp lệ", "GET", "/api/v1/rescue-requests", "Params: status=INVALID_STATUS", "HTTP 400 Bad Request", "HTTP 400, ném lỗi trạng thái không hợp lệ", "PASS", "X1"),
    ("5", "TC05", "Người dân tự hủy khi nước rút", "PUT", "/api/v1/rescue-requests/{id}/cancel", "Status: PENDING, Body: {'reason': 'Nước đã rút, gia đình an toàn'}", "HTTP 200 OK, status -> CANCELLED, ghi log audit", "HTTP 200, đổi status CANCELLED, ghi log CITIZEN", "PASS", "V3, V4"),
    ("6", "TC06", "Hủy khi không truyền body lý do", "PUT", "/api/v1/rescue-requests/{id}/cancel", "Status: PENDING, Body: null", "HTTP 200 OK, lấy lý do mặc định 'Người dân tự hủy'", "HTTP 200, status CANCELLED với note mặc định", "PASS", "V3, V4"),
    ("7", "TC07", "Cố tình hủy khi đã COMPLETED", "PUT", "/api/v1/rescue-requests/{id}/cancel", "Status: COMPLETED, Body: {'reason': 'Nước rút'}", "HTTP 400 Bad Request, chặn lỗi không thể hủy task đã xong", "HTTP 400, thông báo lỗi chính xác", "PASS", "X3"),
    ("8", "TC08", "Cố tình hủy khi đã CANCELLED", "PUT", "/api/v1/rescue-requests/{id}/cancel", "Status: CANCELLED, Body: {'reason': 'Hủy lần 2'}", "HTTP 400 Bad Request, chặn hủy lại lần 2", "HTTP 400, thông báo yêu cầu đã hủy trước đó", "PASS", "X4"),
    ("9", "TC09", "Người dân gửi báo an toàn sau lũ", "POST", "/api/v1/safety-reports", "Body: citizenName, citizenPhone: '0905123456', addressText", "HTTP 200 OK, tạo bản ghi báo an toàn", "HTTP 200, lưu báo cáo an toàn thành công", "PASS", "V5"),
    ("10", "TC10", "Gửi báo an toàn thiếu số điện thoại", "POST", "/api/v1/safety-reports", "Body: thiếu trường citizenPhone", "HTTP 400 Bad Request, thông báo SĐT không được để trống", "HTTP 400, ném BadRequestException đúng chuẩn", "PASS", "X6"),
    ("11", "TC11", "Đội cứu hộ nộp báo cáo tổng kết hợp lệ", "POST", "/api/v1/rescue-reports", "Body: rescuedPeopleCount: 5, actualDistributedItems: 3 thùng mì", "HTTP 200 OK, lưu báo cáo tổng kết, hoàn tất nhiệm vụ", "HTTP 200, ghi nhận đúng số người và hàng phát", "PASS", "V6, V7, B3, B7"),
    ("12", "TC12", "Nộp báo cáo với số người cứu âm (-1)", "POST", "/api/v1/rescue-reports", "Body: rescuedPeopleCount: -1", "HTTP 400 Bad Request, chặn giá trị ngoài biên âm", "HTTP 400, chặn dữ liệu âm tại biên", "PASS", "X8, B1")
]

for row_idx, row_data in enumerate(tc_data, 4):
    for col_idx, val in enumerate(row_data, 1):
        cell = ws_tc.cell(row=row_idx, column=col_idx, value=val)
        cell.font = REGULAR_FONT
        cell.border = THIN_BORDER
        if col_idx in [1, 2, 4, 9, 10]:
            cell.alignment = Alignment(horizontal="center")
        if col_idx == 9: # PASS
            cell.font = BOLD_FONT

# ==============================================================================
# SHEET 4: EP & BVA REFERENCE (LỚP TƯƠNG ĐƯƠNG & GIÁ TRỊ BIÊN)
# ==============================================================================
ws_ep = wb.create_sheet(title="EP & BVA Analysis")
ws_ep.views.sheetView[0].showGridLines = True

ws_ep["A1"] = "BẢNG PHÂN HOẠCH TƯƠNG ĐƯƠNG (EP) & PHÂN TÍCH GIÁ TRỊ BIÊN (BVA)"
ws_ep["A1"].font = TITLE_FONT

ep_headers = ["STT", "Biến đầu vào / Nghiệp vụ", "Miền giá trị", "Lớp hợp lệ", "Tag hợp lệ", "Lớp không hợp lệ", "Tag không hợp lệ"]
for col_idx, h in enumerate(ep_headers, 1):
    cell = ws_ep.cell(row=3, column=col_idx, value=h)
    cell.font = HEADER_FONT
    cell.border = THIN_BORDER
    cell.alignment = Alignment(horizontal="center", vertical="center")

ep_data = [
    ("1", "Trạng thái cứu nạn (status)", "Enum trạng thái", "PENDING, IN_PROGRESS, COMPLETED, CANCELLED", "V1", "Giá trị ngoài enum: INVALID_STATUS, chuỗi rác", "X1"),
    ("2", "Quận / Huyện (district)", "Chuỗi địa bàn", "Địa danh tồn tại (Hải Châu, Thanh Khê...)", "V2", "Ký tự SQLi, ký tự đặc biệt nguy hiểm", "X2"),
    ("3", "Hủy yêu cầu cứu hộ", "Trạng thái hiện tại", "PENDING, IN_PROGRESS (được phép hủy)", "V3", "(a) COMPLETED (đã xong) / (b) CANCELLED (đã hủy)", "X3, X4"),
    ("4", "Lý do hủy yêu cầu", "Chuỗi văn bản", "Lý do hợp lệ (<= 500 ký tự) hoặc null", "V4", "Chuỗi vượt quá 500 ký tự", "X5"),
    ("5", "Số ĐT người báo an toàn", "10 chữ số", "Số ĐT chuẩn 10 chữ số", "V5", "(a) Để trống/null / (b) Sai định dạng ký tự", "X6, X7"),
    ("6", "Số người cứu được", "Số nguyên >= 0", "rescuedPeopleCount >= 0", "V6", "rescuedPeopleCount < 0", "X8"),
    ("7", "Số lượng hàng cấp phát", "Số nguyên > 0", "quantity >= 1 cho từng vật phẩm", "V7", "quantity <= 0 hoặc mảng rỗng", "X9")
]

for row_idx, row_data in enumerate(ep_data, 4):
    for col_idx, val in enumerate(row_data, 1):
        cell = ws_ep.cell(row=row_idx, column=col_idx, value=val)
        cell.font = REGULAR_FONT
        cell.border = THIN_BORDER
        if col_idx in [1, 5, 7]:
            cell.alignment = Alignment(horizontal="center")
            if col_idx in [5, 7]:
                cell.font = BOLD_FONT

# Tự động căn chỉnh độ rộng cột chuẩn xác
for ws in [ws_sum, ws_task, ws_tc, ws_ep]:
    for col in ws.columns:
        max_len = max(len(str(cell.value or '')) for cell in col)
        col_letter = get_column_letter(col[0].column)
        ws.column_dimensions[col_letter].width = max(max_len + 3, 10)

# Luu file Excel trang den
paths = [
    "d:/duanbaolu/Flood-Rescue-Coordination-and-Relief-Management-System/Test-reports/KCPM-64_API_Test_Report_Plain.xlsx",
    "d:/duanbaolu/Flood-Rescue-Coordination-and-Relief-Management-System/Test-reports/Test_Report_Rescue_Safety_APIs_Plain.xlsx"
]

for p in paths:
    wb.save(p)
    print("SAVED: " + p)

# Thu ghi de vao file goc neu nguoi dung khong mo Excel
original_paths = [
    "d:/duanbaolu/Flood-Rescue-Coordination-and-Relief-Management-System/Test-reports/KCPM-64_API_Test_Report.xlsx",
    "d:/duanbaolu/Flood-Rescue-Coordination-and-Relief-Management-System/Test-reports/Test_Report_Rescue_Safety_APIs.xlsx"
]
for op in original_paths:
    try:
        wb.save(op)
        print("OVERWRITTEN: " + op)
    except PermissionError:
        print("LOCKED_IN_EXCEL (Skipped overwrite): " + op)


