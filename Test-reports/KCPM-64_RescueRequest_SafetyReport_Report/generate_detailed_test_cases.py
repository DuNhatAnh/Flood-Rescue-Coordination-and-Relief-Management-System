# -*- coding: utf-8 -*-
import openpyxl
from openpyxl.styles import Font, Alignment, Border, Side, PatternFill

wb = openpyxl.Workbook()

# Sheet 1: Chi tiet tung Test Case
ws1 = wb.active
ws1.title = "Chi Tiet Tung Test Case"
ws1.views.sheetView[0].showGridLines = True

FONT_NAME = "Times New Roman"
TITLE_FONT = Font(name=FONT_NAME, size=14, bold=True, color="000000")
SUB_FONT = Font(name=FONT_NAME, size=11, italic=True, color="333333")
HEADER_FONT = Font(name=FONT_NAME, size=11, bold=True, color="FFFFFF")
REGULAR_FONT = Font(name=FONT_NAME, size=10, color="000000")
BOLD_FONT = Font(name=FONT_NAME, size=10, bold=True, color="000000")
PASS_FONT = Font(name=FONT_NAME, size=10, bold=True, color="006100")

HEADER_FILL = PatternFill(start_color="1F4E78", end_color="1F4E78", fill_type="solid")
ZEBRA_FILL = PatternFill(start_color="F2F5F9", end_color="F2F5F9", fill_type="solid")
PASS_FILL = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")

THIN_BORDER = Border(
    left=Side(style='thin', color='B0B0B0'),
    right=Side(style='thin', color='B0B0B0'),
    top=Side(style='thin', color='B0B0B0'),
    bottom=Side(style='thin', color='B0B0B0')
)

ws1["A1"] = "BẢNG ĐẶC TẢ CHI TIẾT TỪNG TEST CASE KIỂM THỬ TÍCH HỢP API (SPRINT 3)"
ws1["A1"].font = TITLE_FONT
ws1["A2"] = "Dự án: Hệ thống Điều phối Cứu nạn & Cứu trợ Lũ lụt (Flood Rescue Management System) | Mã Jira: KCPM-64"
ws1["A2"].font = SUB_FONT

headers = [
    "STT", "Mã TC", "Phân loại Tag (EP/BVA)", "Module / Nhóm API", "Tên Test Case",
    "Mức ưu tiên", "Điều kiện tiên quyết (Pre-conditions)", "Các bước thực hiện (Test Steps)",
    "Phương thức & Endpoint", "Dữ liệu kiểm thử (Test Data / Payload)",
    "Kết quả mong đợi (Expected Result)", "Kết quả thực tế (Actual Result)",
    "Trạng thái", "Ghi chú kiểm thử"
]

for col_idx, h in enumerate(headers, 1):
    cell = ws1.cell(row=4, column=col_idx, value=h)
    cell.font = HEADER_FONT
    cell.fill = HEADER_FILL
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    cell.border = THIN_BORDER
ws1.row_dimensions[4].height = 30

test_cases = [
    (
        "1", "TC_RES_01", "V1 (Hợp lệ)", "RescueRequest", "Lọc danh sách yêu cầu cứu nạn theo trạng thái PENDING",
        "P1 - High", "Hệ thống có sẵn các yêu cầu cứu hộ ở trạng thái PENDING trong DB.",
        "1. Gửi request GET tới /api/v1/rescue-requests\n2. Truyền tham số status=PENDING\n3. Kiểm tra mã phản hồi và thuộc tính status của từng phần tử",
        "GET /api/v1/rescue-requests?status=PENDING", "Query param: status=PENDING",
        "HTTP 200 OK. Danh sách trả về không rỗng, 100% bản ghi có status = PENDING.",
        "HTTP 200 OK. Lọc chính xác 100% bản ghi PENDING.", "PASS", "Kiểm tra lọc đơn trạng thái hợp lệ"
    ),
    (
        "2", "TC_RES_02", "V1 (Hợp lệ)", "RescueRequest", "Lọc danh sách yêu cầu cứu nạn theo trạng thái IN_PROGRESS",
        "P1 - High", "Có ít nhất 1 đội cứu hộ đang thực hiện nhiệm vụ (status = IN_PROGRESS).",
        "1. Gửi request GET tới /api/v1/rescue-requests\n2. Truyền tham số status=IN_PROGRESS\n3. Xác minh trường status",
        "GET /api/v1/rescue-requests?status=IN_PROGRESS", "Query param: status=IN_PROGRESS",
        "HTTP 200 OK. Toàn bộ danh sách trả về có status = IN_PROGRESS.",
        "HTTP 200 OK. Lọc đúng các ca đang xử lý.", "PASS", "Kiểm tra trạng thái đang thực hiện"
    ),
    (
        "3", "TC_RES_03", "V2 (Hợp lệ)", "RescueRequest", "Lọc danh sách cứu nạn theo địa bàn quận/huyện",
        "P2 - Medium", "Đã có dữ liệu yêu cầu cứu hộ tại địa bàn quận Hải Châu.",
        "1. Gửi request GET tới /api/v1/rescue-requests\n2. Truyền param district=Hải Châu\n3. Kiểm tra địa chỉ addressText",
        "GET /api/v1/rescue-requests?district=Hải Châu", "Query param: district=Hải Châu",
        "HTTP 200 OK. Danh sách trả về có trường addressText chứa từ khóa Hải Châu.",
        "HTTP 200 OK. Trả về đúng các yêu cầu thuộc quận Hải Châu.", "PASS", "Kiểm tra lọc theo vị trí địa lý"
    ),
    (
        "4", "TC_RES_04", "X1 (Không hợp lệ)", "RescueRequest", "Lọc yêu cầu cứu nạn với trạng thái không hợp lệ",
        "P2 - Medium", "Hệ thống backend Spring Boot đang hoạt động.",
        "1. Gửi request GET tới /api/v1/rescue-requests\n2. Truyền param status=INVALID_STATUS\n3. Kiểm tra mã lỗi và thông điệp",
        "GET /api/v1/rescue-requests?status=INVALID_STATUS", "Query param: status=INVALID_STATUS",
        "HTTP 400 Bad Request. Báo lỗi giá trị trạng thái không hợp lệ nằm ngoài enum cho phép.",
        "HTTP 400 Bad Request. Bắt lỗi enum chính xác.", "PASS", "Chặn tham số rác ngoài danh mục"
    ),
    (
        "5", "TC_RES_05", "V3, V4 (Hợp lệ)", "RescueRequest", "Người dân tự hủy yêu cầu cứu trợ khi nước lũ đã rút",
        "P1 - Critical", "Tồn tại yêu cầu cứu nạn có ID req-01 đang ở trạng thái PENDING.",
        "1. Gửi request PUT tới /api/v1/rescue-requests/req-01/cancel\n2. Kèm body JSON lý do hủy\n3. Kiểm tra cập nhật trạng thái và bảng Audit Log",
        "PUT /api/v1/rescue-requests/req-01/cancel", 'Body: {"reason": "Nước đã rút, gia đình đã an toàn"}',
        "HTTP 200 OK. Status chuyển thành CANCELLED, lưu lý do và ghi log đối tượng hủy là CITIZEN.",
        "HTTP 200 OK. Cập nhật CANCELLED và ghi audit log thành công.", "PASS", "Quyền tự hủy của người dân"
    ),
    (
        "6", "TC_RES_06", "V3, V4 (Hợp lệ)", "RescueRequest", "Hủy yêu cầu cứu nạn không truyền body lý do (null/empty)",
        "P2 - Medium", "Tồn tại yêu cầu cứu nạn ID req-02 ở trạng thái PENDING.",
        "1. Gửi request PUT tới /api/v1/rescue-requests/req-02/cancel\n2. Body rỗng {}\n3. Kiểm tra lý do mặc định được gán",
        "PUT /api/v1/rescue-requests/req-02/cancel", "Body: null hoặc {}",
        "HTTP 200 OK. Status đổi thành CANCELLED, hệ thống tự động gán lý do mặc định Người dân tự hủy.",
        "HTTP 200 OK. Ghi nhận lý do mặc định chuẩn xác.", "PASS", "Fallback lý do mặc định"
    ),
    (
        "7", "TC_RES_07", "X3 (Không hợp lệ)", "RescueRequest", "Cố tình gửi yêu cầu hủy khi task cứu hộ đã hoàn thành (COMPLETED)",
        "P1 - High", "Yêu cầu cứu hộ req-03 đã ở trạng thái COMPLETED.",
        "1. Gửi request PUT tới /api/v1/rescue-requests/req-03/cancel\n2. Body {'reason': 'Nước rút'}\n3. Kiểm tra cơ chế chặn nghiệp vụ",
        "PUT /api/v1/rescue-requests/req-03/cancel", 'Body: {"reason": "Nước rút"}',
        "HTTP 400 Bad Request. Thông báo lỗi: Không thể hủy yêu cầu cứu hộ đã ở trạng thái COMPLETED!.",
        "HTTP 400 Bad Request. Chặn thành công thao tác sai quy trình.", "PASS", "Bảo vệ toàn vẹn trạng thái"
    ),
    (
        "8", "TC_RES_08", "X4 (Không hợp lệ)", "RescueRequest", "Cố tình gửi lệnh hủy lần 2 cho yêu cầu đã hủy trước đó (CANCELLED)",
        "P1 - High", "Yêu cầu cứu hộ req-04 đã có trạng thái CANCELLED.",
        "1. Gửi request PUT tới /api/v1/rescue-requests/req-04/cancel\n2. Body {'reason': 'Hủy lần 2'}\n3. Kiểm tra phản hồi từ backend",
        "PUT /api/v1/rescue-requests/req-04/cancel", 'Body: {"reason": "Hủy lần 2"}',
        "HTTP 400 Bad Request. Báo lỗi: Yêu cầu này đã ở trạng thái CANCELLED trước đó!.",
        "HTTP 400 Bad Request. Chặn hủy trùng lặp thành công.", "PASS", "Chặn thao tác lặp (Idempotent check)"
    ),
    (
        "9", "TC_RES_09", "V5 (Hợp lệ)", "SafetyReport", "Người dân gửi báo cáo an toàn thành công sau bão lũ",
        "P1 - High", "Người dân truy cập giao diện gửi báo an toàn.",
        "1. Gửi POST tới /api/v1/safety-reports\n2. Body chứa họ tên, SĐT 10 chữ số, địa chỉ, ghi chú\n3. Xác nhận tạo bản ghi mới",
        "POST /api/v1/safety-reports", 'Body: {"citizenName": "Nguyễn Văn A", "citizenPhone": "0905123456", "addressText": "Hải Châu, Đà Nẵng", "note": "An toàn"}',
        "HTTP 200 OK (hoặc 201). Bản ghi báo an toàn được tạo, lưu chính xác số điện thoại.",
        "HTTP 200 OK. Lưu dữ liệu báo an toàn thành công.", "PASS", "Khảo sát tình hình an toàn dân cư"
    ),
    (
        "10", "TC_RES_10", "X6, X7 (Không hợp lệ)", "SafetyReport", "Gửi báo cáo an toàn nhưng bỏ trống số điện thoại",
        "P1 - High", "Hệ thống áp dụng validation kiểm tra trường bắt buộc.",
        "1. Gửi POST tới /api/v1/safety-reports\n2. Body không có citizenPhone\n3. Kiểm tra ngoại lệ validation",
        "POST /api/v1/safety-reports", 'Body: {"citizenName": "Nguyễn Văn B", "note": "Không có SĐT"}',
        "HTTP 400 Bad Request. Báo lỗi: Số điện thoại người báo không được để trống.",
        "HTTP 400 Bad Request. Bắt lỗi thiếu trường bắt buộc chuẩn xác.", "PASS", "Kiểm tra Validation trường bắt buộc"
    ),
    (
        "11", "TC_RES_11", "V6, V7, B3, B7 (Hợp lệ)", "RescueReport", "Đội cứu hộ nộp báo cáo tổng kết hoàn thành nhiệm vụ",
        "P1 - Critical", "Nhiệm vụ cứu hộ as-01 đang ở trạng thái IN_PROGRESS cần hoàn tất.",
        "1. Gửi POST tới /api/v1/rescue-reports\n2. Body gồm số người cứu (5 người) và danh sách vật phẩm đã phát (3 thùng mì)\n3. Kiểm tra đóng nhiệm vụ",
        "POST /api/v1/rescue-reports", 'Body: {"assignmentId": "as-01", "rescuedPeopleCount": 5, "actualDistributedItems": [{"itemName": "Mì tôm", "quantity": 3}]}',
        "HTTP 200 OK. Lưu báo cáo tổng kết, cập nhật nhiệm vụ thành COMPLETED, khấu trừ hàng hóa.",
        "HTTP 200 OK. Ghi nhận đầy đủ số người và hàng cứu trợ.", "PASS", "Nghiệm thu tổng kết ca cứu hộ"
    ),
    (
        "12", "TC_RES_12", "X8, B1 (Không hợp lệ)", "RescueReport", "Nộp báo cáo cứu hộ với số người được cứu là số âm (-1)",
        "P1 - High", "Backend áp dụng kiểm tra giá trị biên dưới cho trường số người.",
        "1. Gửi POST tới /api/v1/rescue-reports\n2. Body có rescuedPeopleCount = -1\n3. Kiểm tra chặn lỗi số âm",
        "POST /api/v1/rescue-reports", 'Body: {"assignmentId": "as-01", "rescuedPeopleCount": -1}',
        "HTTP 400 Bad Request. Báo lỗi số người được cứu phải lớn hơn hoặc bằng 0.",
        "HTTP 400 Bad Request. Chặn vi phạm biên âm (BVA min-) thành công.", "PASS", "Kiểm soát giá trị biên min-"
    )
]

for row_idx, tc in enumerate(test_cases, 5):
    ws1.row_dimensions[row_idx].height = 48
    is_zebra = (row_idx % 2 == 0)
    for col_idx, val in enumerate(tc, 1):
        cell = ws1.cell(row=row_idx, column=col_idx, value=val)
        cell.font = REGULAR_FONT
        cell.border = THIN_BORDER
        cell.alignment = Alignment(vertical="center", wrap_text=True)
        if is_zebra:
            cell.fill = ZEBRA_FILL
        
        # Center align specific columns
        if col_idx in [1, 2, 3, 4, 6, 13]:
            cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
            if col_idx in [2, 3]:
                cell.font = BOLD_FONT
        
        if col_idx == 13: # Trạng thái PASS
            cell.font = PASS_FONT
            cell.fill = PASS_FILL

# Sheet 2: Danh muc quy uoc EP & BVA
ws2 = wb.create_sheet(title="Danh Muc Quy Uoc EP & BVA")
ws2.views.sheetView[0].showGridLines = True
ws2["A1"] = "BẢNG QUY ƯỚC PHÂN HOẠCH TƯƠNG ĐƯƠNG (EP) & PHÂN TÍCH GIÁ TRỊ BIÊN (BVA)"
ws2["A1"].font = TITLE_FONT
ws2["A2"] = "Giải thích ý nghĩa chi tiết các Tag V1, V2, V3... và X1, X2, X3... được áp dụng trong Test Cases"
ws2["A2"].font = SUB_FONT

ep_headers = ["Mã Tag", "Phân loại", "Trường dữ liệu / Nghiệp vụ", "Điều kiện / Miền giá trị", "Mô tả chi tiết & Ý nghĩa", "Áp dụng tại Test Case"]
for col_idx, h in enumerate(ep_headers, 1):
    cell = ws2.cell(row=4, column=col_idx, value=h)
    cell.font = HEADER_FONT
    cell.fill = HEADER_FILL
    cell.alignment = Alignment(horizontal="center", vertical="center")
    cell.border = THIN_BORDER
ws2.row_dimensions[4].height = 25

ep_rules = [
    ("V1", "Hợp lệ (Valid)", "status (Trạng thái)", "PENDING, IN_PROGRESS, COMPLETED, CANCELLED", "Các giá trị hợp lệ trong Enum trạng thái cứu nạn", "TC_RES_01, TC_RES_02"),
    ("V2", "Hợp lệ (Valid)", "district (Quận/Huyện)", "Địa danh có thật (Hải Châu, Cẩm Lệ, Thanh Khê...)", "Tên quận huyện có dữ liệu trong hệ thống", "TC_RES_03"),
    ("V3", "Hợp lệ (Valid)", "Trạng thái được hủy", "PENDING, IN_PROGRESS", "Chỉ các yêu cầu chưa xong mới được phép hủy", "TC_RES_05, TC_RES_06"),
    ("V4", "Hợp lệ (Valid)", "Lý do hủy yêu cầu", "Chuỗi văn bản <= 500 ký tự hoặc null", "Lý do người dân hủy cứu nạn (tự động lấy mặc định nếu để trống)", "TC_RES_05, TC_RES_06"),
    ("V5", "Hợp lệ (Valid)", "citizenPhone (SĐT)", "10 chữ số chuẩn đầu số viễn thông Việt Nam", "Số điện thoại hợp lệ để đội cứu nạn liên hệ xác minh", "TC_RES_09"),
    ("V6", "Hợp lệ (Valid)", "rescuedPeopleCount", "Số nguyên >= 0", "Số người được đội cứu hộ giải cứu thực tế", "TC_RES_11"),
    ("V7", "Hợp lệ (Valid)", "quantity (Hàng cứu trợ)", "Số nguyên > 0 cho từng loại vật phẩm", "Số lượng lương thực, thuốc men, áo phao cấp phát", "TC_RES_11"),
    ("X1", "Không hợp lệ (Invalid)", "status (Trạng thái)", "Giá trị ngoài Enum (INVALID_STATUS, chuỗi rác)", "Hệ thống phải chặn bằng HTTP 400 Bad Request", "TC_RES_04"),
    ("X2", "Không hợp lệ (Invalid)", "district (Quận/Huyện)", "Ký tự tấn công SQLi, ký tự đặc biệt nguy hiểm", "Hệ thống phải làm sạch và từ chối xử lý", "Bộ lọc bảo mật"),
    ("X3", "Không hợp lệ (Invalid)", "Trạng thái khi hủy", "COMPLETED (Đã hoàn thành)", "Cấm người dùng hủy nhiệm vụ đã hoàn tất", "TC_RES_07"),
    ("X4", "Không hợp lệ (Invalid)", "Trạng thái khi hủy", "CANCELLED (Đã hủy trước đó)", "Cấm lặp lại thao tác hủy cho một yêu cầu", "TC_RES_08"),
    ("X6", "Không hợp lệ (Invalid)", "citizenPhone (SĐT)", "Để trống, null, chuỗi rỗng", "Báo an toàn bắt buộc phải có SĐT để đối chiếu", "TC_RES_10"),
    ("X7", "Không hợp lệ (Invalid)", "citizenPhone (SĐT)", "Chứa chữ cái, ký tự đặc biệt, không đủ 10 số", "Vi phạm định dạng chuẩn số điện thoại", "TC_RES_10"),
    ("X8", "Không hợp lệ (Invalid)", "rescuedPeopleCount", "Số âm (< 0, ví dụ: -1)", "Vi phạm biên dưới (min-) số người cứu", "TC_RES_12"),
    ("B1-B10", "Giá trị biên (BVA)", "rescuedPeopleCount, quantity", "min- (-1), min (0, 1), nominal (5, 10), max (1000)", "Kiểm thử các điểm chuyển tiếp biên nghiệp vụ", "TC_RES_11, TC_RES_12")
]

for row_idx, r in enumerate(ep_rules, 5):
    ws2.row_dimensions[row_idx].height = 25
    is_zebra = (row_idx % 2 == 0)
    for col_idx, val in enumerate(r, 1):
        cell = ws2.cell(row=row_idx, column=col_idx, value=val)
        cell.font = REGULAR_FONT
        cell.border = THIN_BORDER
        cell.alignment = Alignment(vertical="center")
        if is_zebra:
            cell.fill = ZEBRA_FILL
        if col_idx in [1, 2, 6]:
            cell.alignment = Alignment(horizontal="center", vertical="center")
            if col_idx == 1:
                cell.font = BOLD_FONT

col_widths_ws1 = {
    'A': 6, 'B': 14, 'C': 18, 'D': 16, 'E': 35,
    'F': 14, 'G': 32, 'H': 38, 'I': 35, 'J': 35,
    'K': 35, 'L': 32, 'M': 12, 'N': 25
}
for col_l, w in col_widths_ws1.items():
    ws1.column_dimensions[col_l].width = w

col_widths_ws2 = {
    'A': 12, 'B': 22, 'C': 26, 'D': 35, 'E': 45, 'F': 25
}
for col_l, w in col_widths_ws2.items():
    ws2.column_dimensions[col_l].width = w

out_paths = [
    "d:/duanbaolu/Flood-Rescue-Coordination-and-Relief-Management-System/Test-reports/KCPM-64_RescueRequest_SafetyReport_Report/Chi_Tiet_Tung_Test_Case_V1_V2_V3.xlsx",
    "d:/duanbaolu/Flood-Rescue-Coordination-and-Relief-Management-System/Test-reports/Chi_Tiet_Tung_Test_Case_V1_V2_V3.xlsx"
]

for p in out_paths:
    wb.save(p)
    print(f"SUCCESSFULLY_CREATED: {p}")

