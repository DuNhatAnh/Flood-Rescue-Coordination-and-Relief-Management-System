# HƯỚNG DẪN DEMO ĐỘ PHỦ CÂU LỆNH (STATEMENT COVERAGE) BẰNG JACOCO

## 1. JaCoCo là gì?

**JaCoCo** (Java Code Coverage) là công cụ đo **bộ test đã chạy qua những dòng code nào**. Khi chạy `mvn test`, JaCoCo ghi lại từng câu lệnh, từng nhánh `if` mà unit test đi qua, rồi xuất ra một trang web báo cáo.

| Chỉ số trong báo cáo | Ý nghĩa |
|:---|:---|
| **Lines** (Statement coverage – C0) | Tỷ lệ câu lệnh đã được test chạy qua |
| **Branches** (Branch coverage – C1) | Tỷ lệ nhánh đúng/sai của các `if`, `&&`, `\|\|`, `?:` đã được chạy |

Màu trong trang code của báo cáo:

| Màu | Ý nghĩa |
|:---|:---|
| 🟩 Xanh lá | Dòng đã được test chạy qua |
| 🟥 Đỏ | Dòng **chưa** có test nào chạy qua → cần bổ sung test |
| 🟨 Vàng | Dòng có `if` mới chạy 1 nhánh (ví dụ chỉ nhánh sai, chưa nhánh đúng) |

---

## 2. Chuẩn bị (làm 1 lần trước buổi demo)

1. Mở **PowerShell**.
2. Khai báo Java (máy chưa có `JAVA_HOME`):
   ```powershell
   $env:JAVA_HOME = "C:\Users\nhata\.antigravity-ide\extensions\redhat.java-1.58.0-win32-x64\jre\25.0.4.1-win32-x86_64"
   ```
> `mvnw.cmd` (Maven Wrapper) chỉ có trên máy trưởng nhóm vì repo đang bỏ qua file này trong `.gitignore`. Máy đã cài Maven thì dùng `mvn test` thay cho `.\mvnw.cmd test`, kết quả như nhau.

3. Chạy thử 1 lần để máy tải Maven và thư viện (lần đầu mất vài phút, các lần sau ~30 giây):
   ```powershell
   cd C:\Users\nhata\Flood-Rescue-Coordination-and-Relief-Management-System\backend
   .\mvnw.cmd test
   ```

---

## 3. Các bước thao tác khi demo

| Bước | Thao tác | Nói với thầy |
|:---:|:---|:---|
| 1 | Mở `docs/CO_SO_TINH_SO_TESTCASE.xlsx`, sheet **Ly thuyet**, chỉ 2 dòng cuối | "Độ phủ câu lệnh C0 = số câu lệnh đã chạy / tổng câu lệnh. Nhóm đo bằng JaCoCo." |
| 2 | Sheet **Pham vi & Statement** | "Mỗi thành viên phụ trách 1 phân hệ, chọn 4 chức năng cốt lõi. Đây là độ phủ đo thật của từng chức năng." |
| 3 | Chạy trong PowerShell: `.\mvnw.cmd test` | "Chạy toàn bộ 167 unit test, JaCoCo đo độ phủ cùng lúc." |
| 4 | Chờ dòng `Tests run: 167, Failures: 0` và `BUILD SUCCESS` | "167/167 test pass." |
| 5 | Mở báo cáo: `start target\site\jacoco\index.html` | Trang tổng hợp độ phủ theo package |
| 6 | Bấm `vn.rescue.core.application.services` → `UserService` | Bảng độ phủ theo từng hàm, cột **Lines** và **Branches** |
| 7 | Bấm hàm `changePassword(...)` | Mở code: dòng xanh đã test; dòng đỏ 170, 173 chưa test |
| 8 | Quay lại Excel, chỉ cột **Dòng chưa chạy** | "Nhóm biết chính xác dòng nào thiếu test: dòng 170 là mật khẩu cũ để trống, dòng 173 là mật khẩu mới để trống. Thêm 2 unit test cho 2 trường hợp này là đạt 100%." |

**Mẹo:** chọn 1 hàm đã đạt 100% để thầy thấy toàn bộ màu xanh, ví dụ `VehiclesService.validateVehicleRequest` hoặc `UserService.updateUserStatus`, rồi so với 1 hàm còn dòng đỏ.

---

## 4. Cách đọc các cột trong báo cáo JaCoCo

| Cột | Ý nghĩa |
|:---|:---|
| **Missed Instructions / Cov.** | Tỷ lệ lệnh bytecode đã chạy (ít dùng khi trình bày) |
| **Missed Branches / Cov.** | **Branch coverage (C1)** – thanh xanh = nhánh đã chạy, đỏ = nhánh chưa chạy |
| **Missed Cxty / Cxty** | **Độ phức tạp chu trình V(G)**: Cxty = số đường đi độc lập; Missed = số đường chưa có test = số test tối thiểu còn phải viết |
| **Missed Lines / Lines** | **Statement coverage (C0)** – chỉ số "statement" thầy hỏi |
| **Missed Methods / Methods** | Số hàm chưa có test nào gọi tới |

Ví dụ `UserService.changePassword`: Lines = 20, Missed = 2 → 18/20 = **90%**; bấm vào sẽ thấy dòng 170 và 173 tô đỏ.

---

## 5. Đo độ phủ khi chạy cả 4 loại kiểm thử (tùy chọn)

`mvn test` chỉ đo **unit test**. Bruno, QA và CodeceptJS gọi API trên server nên muốn đo cả 4 loại phải gắn JaCoCo vào backend:

```powershell
cd backend
$agent = "$env:USERPROFILE\.m2\repository\org\jacoco\org.jacoco.agent\0.8.14\org.jacoco.agent-0.8.14-runtime.jar"
# 1. Chạy backend phụ ở cổng 8081 có gắn JaCoCo (để cửa sổ PowerShell này chạy)
.\mvnw.cmd spring-boot:run "-Dspring-boot.run.jvmArguments=-javaagent:$agent=output=tcpserver,port=6300,includes=vn.rescue.*" "-Dspring-boot.run.arguments=--server.port=8081"

# 2. Mở cửa sổ PowerShell khác, chạy các bộ test vào cổng 8081
cd C:\Users\nhata\Flood-Rescue-Coordination-and-Relief-Management-System\bruno
npx @usebruno/cli run -r --env Local --env-var baseUrl=http://localhost:8081
cd ..\test-automation
$env:API_BASE_URL = "http://localhost:8081"; npx codeceptjs run

# 3. Lấy dữ liệu độ phủ, gộp với unit test và xuất báo cáo
cd ..\backend
.\mvnw.cmd test
.\mvnw.cmd org.jacoco:jacoco-maven-plugin:0.8.14:dump "-Djacoco.port=6300" "-Djacoco.destFile=target/jacoco-it.exec"
cmd /c copy /b target\jacoco.exec + target\jacoco-it.exec target\jacoco-all.exec
.\mvnw.cmd org.jacoco:jacoco-maven-plugin:0.8.14:report "-Djacoco.dataFile=target/jacoco-all.exec"
start target\site\jacoco\index.html
```

---

## 6. Câu hỏi thầy có thể hỏi

**Hỏi: "Sao cột JUnit có người thấp (40–60%)?"**
Unit test Mockito chủ yếu kiểm tra các **nhánh chặn lỗi** của hàm. Luồng xử lý thành công dài (lưu DB, đổi trạng thái đội/xe, gửi thông báo) được kiểm thử bằng **Bruno và CodeceptJS gọi API thật** – `mvn test` không đo được 2 loại này. Ví dụ "Gửi đơn SOS": JUnit 0% nhưng khi chạy cả 4 loại thì 27/27 câu lệnh = 100%. Đo đủ 4 loại thì cả nhóm đạt **89,8%**.

**Hỏi: "Còn chỗ nào chưa có test?"**
Cột cuối sheet *Pham vi & Statement* ghi đúng số dòng. Hai chỗ thấp nhất: "Nghiệm thu báo cáo" (`updateAssignmentStatus` – nhiều nhánh trạng thái) và "Luân chuyển trạng thái xe/đội" (`refreshTeamStatus`).

**Hỏi: "Statement coverage với branch coverage khác nhau gì?"**
Statement chỉ cần mỗi dòng chạy ít nhất 1 lần. Branch đòi mỗi `if` chạy cả nhánh đúng lẫn sai. Đạt 100% branch thì chắc chắn 100% statement, ngược lại thì không.

---

## 7. Số liệu ngày 24/11/2026 (20 chức năng theo KE_HOACH_TOAN_DIEN_VA_DANH_SACH_TASK_JIRA_KCPM.md)

| Thành viên | Chỉ JUnit | Cả 4 loại kiểm thử |
|:---|:---:|:---:|
| Dư Nhật Anh | 93,1% | 98,9% |
| Lâm Khiêm | 64,3% | 98,8% |
| Phạm Minh Dũng | 66,0% | 79,9% |
| Nguyễn Bảo | 43,3% | 89,7% |
| Phan Quốc Danh | 80,3% | 91,9% |
| **Toàn nhóm** | **69,9%** | **89,8%** |

Chi tiết từng hàm: sheet **Pham vi & Statement** trong `docs/CO_SO_TINH_SO_TESTCASE.xlsx`.
