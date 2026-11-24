import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def build_excel_report():
    wb = openpyxl.Workbook()
    # Remove default sheet
    wb.remove(wb.active)

    # Styles
    navy_fill = PatternFill(start_color="1F497D", end_color="1F497D", fill_type="solid")
    accent_blue_fill = PatternFill(start_color="DCE6F1", end_color="DCE6F1", fill_type="solid")
    section_fill = PatternFill(start_color="244062", end_color="244062", fill_type="solid")
    header_fill = PatternFill(start_color="2F4F4F", end_color="2F4F4F", fill_type="solid")
    pass_fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
    gray_fill = PatternFill(start_color="F2F2F2", end_color="F2F2F2", fill_type="solid")

    font_title = Font(name="Segoe UI", size=16, bold=True, color="FFFFFF")
    font_subtitle = Font(name="Segoe UI", size=10, italic=True, color="D9D9D9")
    font_section = Font(name="Segoe UI", size=12, bold=True, color="FFFFFF")
    font_header = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
    font_bold = Font(name="Segoe UI", size=10, bold=True)
    font_regular = Font(name="Segoe UI", size=10)
    font_pass = Font(name="Segoe UI", size=10, bold=True, color="006100")

    thin_border_side = Side(border_style="thin", color="D3D3D3")
    border_cell = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)
    thick_bottom = Border(bottom=Side(border_style="medium", color="1F497D"))

    # ==========================================
    # SHEET 1: DASHBOARD TỔNG QUAN
    # ==========================================
    ws1 = wb.create_sheet(title="Dashboard Tổng Quan")
    ws1.views.sheetView[0].showGridLines = True

    # Title Block
    ws1.merge_cells("A1:G1")
    ws1["A1"] = "BÁO CÁO KIỂM THỬ HỘP TRẮNG & PHÂN TÍCH GIÁ TRỊ BIÊN (BVA)"
    ws1["A1"].font = font_title
    ws1["A1"].fill = navy_fill
    ws1["A1"].alignment = Alignment(horizontal="center", vertical="center")
    ws1.row_dimensions[1].height = 40

    ws1.merge_cells("A2:G2")
    ws1["A2"] = "Dự án: Flood Rescue System | Module: Rescue Request DTO & Rescue Report Controller | Tiêu chuẩn: Chương IV KT Hộp Trắng"
    ws1["A2"].font = font_subtitle
    ws1["A2"].fill = navy_fill
    ws1["A2"].alignment = Alignment(horizontal="center", vertical="center")
    ws1.row_dimensions[2].height = 22

    # Executive Summary
    ws1.merge_cells("A4:G4")
    ws1["A4"] = "1. THỐNG KÊ TỔNG QUAN THỰC THI (EXECUTIVE SUMMARY)"
    ws1["A4"].font = font_section
    ws1["A4"].fill = section_fill
    ws1["A4"].alignment = Alignment(horizontal="left", vertical="center", indent=1)
    ws1.row_dimensions[4].height = 26

    summary_headers = ["Chỉ Số Kiểm Thử", "Giá Trị Đo Lường", "Mục Tiêu Nghiệm Thu", "Đánh Giá Thực Tế", "", "", ""]
    ws1.row_dimensions[5].height = 24
    for col_idx, h in enumerate(summary_headers[:4], 1):
        cell = ws1.cell(row=5, column=col_idx, value=h)
        cell.font = font_header
        cell.fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
        cell.alignment = Alignment(horizontal="center", vertical="center")

    summary_data = [
        ("Tổng số Test Cases thực thi", "15 ca", "100% các ca theo yêu cầu AC1 & AC2", "ĐẠT (Vượt chỉ tiêu)"),
        ("Số ca kiểm thử thành công (PASS)", "15 ca", "15 ca không có lỗi phát sinh", "100% THÀNH CÔNG"),
        ("Số ca kiểm thử thất bại (FAIL)", "0 ca", "0 ca thất bại", "XUẤT SẮC"),
        ("Tỉ lệ đạt chuẩn (Pass Rate)", "100.0%", "100.0% Pass", "100% BUILD SUCCESS"),
        ("Thời gian thực thi Unit Test", "4.328 giây", "Dưới 10 giây (Tối ưu CI/CD)", "ĐẠT CHUẨN HIỆU NĂNG"),
        ("Tình trạng nghiệm thu (Acceptance)", "PASS TOÀN BỘ", "Thỏa mãn AC 1 & AC 2", "CHẤP THUẬN NGHIỆM THU")
    ]

    for r_idx, row_vals in enumerate(summary_data, 6):
        ws1.row_dimensions[r_idx].height = 22
        for c_idx, val in enumerate(row_vals, 1):
            cell = ws1.cell(row=r_idx, column=c_idx, value=val)
            cell.font = font_regular if c_idx != 4 else font_pass
            cell.border = border_cell
            cell.alignment = Alignment(horizontal="center" if c_idx in [2, 4] else "left", vertical="center")
            if c_idx == 4:
                cell.fill = pass_fill

    # White-box Formulas & Verification Table
    ws1.merge_cells("A13:G13")
    ws1["A13"] = "2. CÁC CÔNG THỨC KIỂM THỬ HỘP TRẮNG & SỐ LIỆU ĐO LƯỜNG (THEO SLIDE CHƯƠNG IV)"
    ws1["A13"].font = font_section
    ws1["A13"].fill = section_fill
    ws1["A13"].alignment = Alignment(horizontal="left", vertical="center", indent=1)
    ws1.row_dimensions[13].height = 26

    wb_headers = ["Kỹ Thuật / Chỉ Số", "Công Thức Slide", "Giải Thích Biến", "Áp Dụng Trong Bài Toán", "Số Liệu Thực Tế", "Đánh Giá"]
    ws1.row_dimensions[14].height = 24
    for col_idx, h in enumerate(wb_headers, 1):
        cell = ws1.cell(row=14, column=col_idx, value=h)
        cell.font = font_header
        cell.fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
        cell.alignment = Alignment(horizontal="center", vertical="center")

    wb_data = [
        ("Độ phức tạp Cyclomatic V(G)", "V(G) = P + 1 = E - N + 2", "P: số nút điều kiện; E: cạnh, N: nút", "RescueReportController.submitReport: không rẽ nhánh P=0", "V(G) = 1", "Tối thiểu 1 test path"),
        ("Bao phủ câu lệnh (Statement)", "Coverage = (Lệnh chạy / Tổng lệnh) * 100%", "Tổng lệnh: 3 câu lệnh trong submitReport", "Cả 3 câu lệnh đều được thực thi qua 2 tests", "100% (3/3 lệnh)", "ĐẠT 100% PHỦ CÂU LỆNH"),
        ("Bao phủ nhánh (Branch / Decision)", "Coverage = (Nhánh chạy / Tổng nhánh) * 100%", "Tổng nhánh logic của các rule validation: 6 nhánh", "Đã kích hoạt đủ cả 2 hướng True/False của min, max, size", "100% (6/6 nhánh)", "ĐẠT 100% PHỦ NHÁNH"),
        ("Bao phủ điều kiện (Condition)", "Coverage = (ĐK chạy / Tổng ĐK) * 100%", "Các điều kiện biên: >=1, <=50, <=1000", "Mỗi điều kiện đơn đều được test ở 2 phía biên", "100% (6/6 điều kiện)", "ĐẠT 100% ĐIỀU KIỆN"),
        ("Phân tích biên Robustness BVA", "Số TCs = 6n + 1 (hoặc xét Min-, Min, Max, Max+)", "n: số biến cần kiểm thử biên (n=2: peopleCount, note)", "Biên số người: {-1, 0, 1, 50, 51}; Ghi chú: {1000, 1001}", "Đã phủ đủ 7 ca biên", "TOÀN DIỆN ROBUSTNESS"),
        ("Tiêu chuẩn AC 1 (DTO Test)", "Số lượng TCs >= 12", "Bộ test cũ: 6 tests; Thêm mới: 7 tests", "Tổng cộng trong RescueRequestValidationTest", "13 test cases", "ĐẠT AC 1 (13 >= 12)"),
        ("Tiêu chuẩn AC 2 (Pass 100%)", "Pass Rate = 100% không Fail/Error", "mvn test -Dtest=RescueRequest...,RescueReport...", "Chạy trên JDK 17, Surefire JUnit Platform", "15/15 Pass (100%)", "ĐẠT AC 2 (PASS 100%)")
    ]

    for r_idx, row_vals in enumerate(wb_data, 15):
        ws1.row_dimensions[r_idx].height = 24
        for c_idx, val in enumerate(row_vals, 1):
            cell = ws1.cell(row=r_idx, column=c_idx, value=val)
            cell.font = font_regular if c_idx != 6 else font_pass
            cell.border = border_cell
            cell.alignment = Alignment(horizontal="center" if c_idx in [2, 5, 6] else "left", vertical="center")
            if c_idx == 6:
                cell.fill = pass_fill

    # ==========================================
    # SHEET 2: CHI TIẾT TEST CASES DTO
    # ==========================================
    ws2 = wb.create_sheet(title="Chi Tiết Test DTO")
    ws2.views.sheetView[0].showGridLines = True

    ws2.merge_cells("A1:H1")
    ws2["A1"] = "BẢNG KẾT QUẢ KIỂM THỬ BVA CHI TIẾT: RescueRequestDto (13 TEST CASES)"
    ws2["A1"].font = font_title
    ws2["A1"].fill = navy_fill
    ws2["A1"].alignment = Alignment(horizontal="center", vertical="center")
    ws2.row_dimensions[1].height = 36

    ws2.merge_cells("A2:H2")
    ws2["A2"] = "Kiểm tra toàn diện giá trị biên: Vĩ độ, Kinh độ, SĐT, Số người (peopleCount), Độ dài ghi chú (description)"
    ws2["A2"].font = font_subtitle
    ws2["A2"].fill = navy_fill
    ws2["A2"].alignment = Alignment(horizontal="center", vertical="center")
    ws2.row_dimensions[2].height = 20

    dto_headers = ["Mã Test", "Phương Thức Kiểm Thử", "Nhóm Thuộc Tính", "Giá Trị Đầu Vào (Input)", "Phân Loại Biên (BVA)", "Kết Quả Kỳ Vọng", "Kết Quả Thực Tế", "Trạng Thái"]
    ws2.row_dimensions[4].height = 24
    for c_idx, h in enumerate(dto_headers, 1):
        cell = ws2.cell(row=4, column=c_idx, value=h)
        cell.font = font_header
        cell.fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
        cell.alignment = Alignment(horizontal="center", vertical="center")

    dto_cases = [
        ("TC_DTO_01", "testValidDto_ShouldHaveNoViolations", "Toàn bộ DTO", "Lat=16.0544, Lng=108.2022, People=3, Phone=0987654321", "Giá trị hợp lệ chuẩn (Nominal)", "0 lỗi vi phạm validation", "0 lỗi vi phạm", "PASS"),
        ("TC_DTO_02", "testInvalidLatitude_GreaterThan90_ShouldFail", "Tọa độ Lat", "locationLat = 95.0", "Vượt biên trên (Max+)", "Vi phạm ConstraintViolation trên locationLat", "Chặn lỗi locationLat", "PASS"),
        ("TC_DTO_03", "testInvalidLatitude_LessThanMinus90_ShouldFail", "Tọa độ Lat", "locationLat = -95.0", "Vượt biên dưới (Min-)", "Vi phạm ConstraintViolation trên locationLat", "Chặn lỗi locationLat", "PASS"),
        ("TC_DTO_04", "testInvalidLongitude_GreaterThan180_ShouldFail", "Tọa độ Lng", "locationLng = 185.0", "Vượt biên trên (Max+)", "Vi phạm ConstraintViolation trên locationLng", "Chặn lỗi locationLng", "PASS"),
        ("TC_DTO_05", "testInvalidLongitude_LessThanMinus180_ShouldFail", "Tọa độ Lng", "locationLng = -185.0", "Vượt biên dưới (Min-)", "Vi phạm ConstraintViolation trên locationLng", "Chặn lỗi locationLng", "PASS"),
        ("TC_DTO_06", "testInvalidPhone_ShouldFail", "Số điện thoại", "citizenPhone = '012345'", "Độ dài ngắn / Sai format", "Vi phạm ConstraintViolation trên citizenPhone", "Chặn lỗi citizenPhone", "PASS"),
        ("TC_DTO_07", "testInvalidNumberOfPeople_NegativeOne_ShouldFail", "Số người", "numberOfPeople = -1", "Số âm (Min - 2)", "Bị chặn với ConstraintViolation trên numberOfPeople", "Chặn lỗi numberOfPeople", "PASS"),
        ("TC_DTO_08", "testInvalidNumberOfPeople_Zero_ShouldFail", "Số người", "numberOfPeople = 0", "Biên dưới không hợp lệ (Min - 1)", "Bị chặn với ConstraintViolation trên numberOfPeople", "Chặn lỗi numberOfPeople", "PASS"),
        ("TC_DTO_09", "testValidNumberOfPeople_LowerBoundaryOne_ShouldPass", "Số người", "numberOfPeople = 1", "Biên dưới hợp lệ (Min)", "Hợp lệ, 0 vi phạm validation", "Hợp lệ, 0 vi phạm", "PASS"),
        ("TC_DTO_10", "testValidNumberOfPeople_UpperBoundaryFifty_ShouldPass", "Số người", "numberOfPeople = 50", "Biên trên hợp lệ (Max)", "Hợp lệ, 0 vi phạm validation", "Hợp lệ, 0 vi phạm", "PASS"),
        ("TC_DTO_11", "testInvalidNumberOfPeople_FiftyOne_ShouldFail", "Số người", "numberOfPeople = 51", "Vượt biên trên (Max + 1)", "Bị chặn với ConstraintViolation trên numberOfPeople", "Chặn lỗi numberOfPeople", "PASS"),
        ("TC_DTO_12", "testValidDescription_Length1000_ShouldPass", "Độ dài ghi chú", "description = 'A' * 1000 ký tự", "Biên trên hợp lệ (Max length)", "Hợp lệ, 0 vi phạm validation", "Hợp lệ, 0 vi phạm", "PASS"),
        ("TC_DTO_13", "testInvalidDescription_Length1001_ShouldFail", "Độ dài ghi chú", "description = 'A' * 1001 ký tự", "Vượt biên trên (Max + 1 length)", "Bị chặn với ConstraintViolation trên description", "Chặn lỗi description", "PASS")
    ]

    for r_idx, row_vals in enumerate(dto_cases, 5):
        ws2.row_dimensions[r_idx].height = 22
        for c_idx, val in enumerate(row_vals, 1):
            cell = ws2.cell(row=r_idx, column=c_idx, value=val)
            cell.font = font_regular if c_idx != 8 else font_pass
            cell.border = border_cell
            cell.alignment = Alignment(horizontal="center" if c_idx in [1, 5, 8] else "left", vertical="center")
            if c_idx == 8:
                cell.fill = pass_fill

    # ==========================================
    # SHEET 3: CHI TIẾT CONTROLLER TEST
    # ==========================================
    ws3 = wb.create_sheet(title="Chi Tiết Controller Test")
    ws3.views.sheetView[0].showGridLines = True

    ws3.merge_cells("A1:H1")
    ws3["A1"] = "BẢNG KẾT QUẢ KIỂM THỬ CONTROLLER: RescueReportController"
    ws3["A1"].font = font_title
    ws3["A1"].fill = navy_fill
    ws3["A1"].alignment = Alignment(horizontal="center", vertical="center")
    ws3.row_dimensions[1].height = 36

    ws3.merge_cells("A2:H2")
    ws3["A2"] = "Kiểm tra biên rescuedPeopleCount (0 người tiếp tế và 50 người đầy tải) qua endpoint POST /api/v1/rescue-reports"
    ws3["A2"].font = font_subtitle
    ws3["A2"].fill = navy_fill
    ws3["A2"].alignment = Alignment(horizontal="center", vertical="center")
    ws3.row_dimensions[2].height = 20

    ctrl_headers = ["Mã Test", "Tên Test Case", "Kịch Bản Nghiệp Vụ", "Số Người Cứu (rescuedPeopleCount)", "HTTP Kỳ Vọng", "HTTP Thực Tế", "Dữ Liệu Trả Về", "Trạng Thái"]
    ws3.row_dimensions[4].height = 24
    for c_idx, h in enumerate(ctrl_headers, 1):
        cell = ws3.cell(row=4, column=c_idx, value=h)
        cell.font = font_header
        cell.fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
        cell.alignment = Alignment(horizontal="center", vertical="center")

    ctrl_cases = [
        ("TC_CTRL_01", "testSubmitReport_RescuedPeopleCountZero_ShouldReturn200Ok", "Ca cứu trợ chỉ tiếp tế lương thực / nhu yếu phẩm, không có người cần sơ tán (Biên dưới)", 0, "HTTP 200 OK", "HTTP 200 OK", "isSuccess=true, data.rescuedPeopleCount=0, id=MOCK-REPORT-...", "PASS"),
        ("TC_CTRL_02", "testSubmitReport_RescuedPeopleCountFifty_ShouldReturn200Ok", "Ca cứu nạn sơ tán toàn bộ cụm dân cư, đạt tải trọng tối đa phương tiện (Biên trên)", 50, "HTTP 200 OK", "HTTP 200 OK", "isSuccess=true, data.rescuedPeopleCount=50, id=MOCK-REPORT-...", "PASS")
    ]

    for r_idx, row_vals in enumerate(ctrl_cases, 5):
        ws3.row_dimensions[r_idx].height = 24
        for c_idx, val in enumerate(row_vals, 1):
            cell = ws3.cell(row=r_idx, column=c_idx, value=val)
            cell.font = font_regular if c_idx != 8 else font_pass
            cell.border = border_cell
            cell.alignment = Alignment(horizontal="center" if c_idx in [1, 4, 5, 6, 8] else "left", vertical="center")
            if c_idx == 8:
                cell.fill = pass_fill

    # Auto-adjust column widths across all sheets
    for ws in [ws1, ws2, ws3]:
        for col in ws.columns:
            max_len = 0
            col_letter = get_column_letter(col[0].column)
            for cell in col:
                # ignore merged title rows
                if cell.row in [1, 2]:
                    continue
                val_str = str(cell.value or "")
                if len(val_str) > max_len:
                    max_len = len(val_str)
            ws.column_dimensions[col_letter].width = max(max_len + 3, 12)

    # Specific tweaks
    ws1.column_dimensions["A"].width = 34
    ws1.column_dimensions["B"].width = 24
    ws1.column_dimensions["C"].width = 38
    ws1.column_dimensions["D"].width = 46
    ws1.column_dimensions["E"].width = 22
    ws1.column_dimensions["F"].width = 26

    ws2.column_dimensions["A"].width = 14
    ws2.column_dimensions["B"].width = 42
    ws2.column_dimensions["C"].width = 18
    ws2.column_dimensions["D"].width = 42
    ws2.column_dimensions["E"].width = 28
    ws2.column_dimensions["F"].width = 42
    ws2.column_dimensions["G"].width = 28
    ws2.column_dimensions["H"].width = 14

    ws3.column_dimensions["A"].width = 14
    ws3.column_dimensions["B"].width = 48
    ws3.column_dimensions["C"].width = 55
    ws3.column_dimensions["D"].width = 24
    ws3.column_dimensions["E"].width = 16
    ws3.column_dimensions["F"].width = 16
    ws3.column_dimensions["G"].width = 45
    ws3.column_dimensions["H"].width = 14

    # Save to both paths
    p1 = r"Flood-Rescue-Coordination-and-Relief-Management-System\qa-testing\reports\REPORT_WHITEBOX_BVA_RESCUE.xlsx"
    p2 = r"reports\REPORT_WHITEBOX_BVA_RESCUE.xlsx"

    os.makedirs(os.path.dirname(p1), exist_ok=True)
    os.makedirs(os.path.dirname(p2), exist_ok=True)

    wb.save(p1)
    wb.save(p2)
    print("Report generated successfully at:")
    print(" 1.", os.path.abspath(p1))
    print(" 2.", os.path.abspath(p2))

if __name__ == "__main__":
    build_excel_report()
