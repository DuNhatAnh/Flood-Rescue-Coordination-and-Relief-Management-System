# 🌊 Flood Rescue Coordination and Relief Management System (FRS)

[![Spring Boot](https://img.shields.io/badge/Backend-Spring%20Boot%203.2-brightgreen)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Frontend-Flutter%20Web-blue)](https://flutter.dev/)
[![Docker](https://img.shields.io/badge/DevOps-Docker%20Compose-blue)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL%2015-blue)](https://www.postgresql.org/)

## 📝 Giới thiệu dự án
Dự án **Flood Rescue System (FRS)** là một hệ thống quản lý và điều phối cứu hộ lũ lụt trực tuyến. Mục tiêu của hệ thống là kết nối nhanh chóng giữa người dân vùng lũ và các đơn vị cứu hộ, giúp tối ưu hóa nguồn lực và giảm thiểu thiệt hại về người và tài sản trong thiên tai.

Hệ thống được thiết kế theo các tiêu chuẩn của **Môn Công nghệ Phần mềm**, đảm bảo tính mở rộng (Scalability), tính bảo mật (Security) và quy trình phát triển chuyên nghiệp.

## 🚀 Tính năng cốt lõi
- **🔴 Gửi yêu cầu cứu hộ khẩn cấp (SOS):** Người dân có thể gửi tọa độ GPS, hình ảnh hiện trường, số lượng người gặp nạn và mức độ khẩn cấp.
- **🗺️ Bản đồ cứu trợ trực tuyến:** Hiển thị trực quan các điểm nóng cần cứu hộ trên nền tảng Google Maps/OpenStreetMap.
- **👥 Quản lý đội cứu hộ:** Điều phối các đội cứu hộ đến các vị trí cần thiết dựa trên vị trí và trạng thái sẵn sàng.
- **📦 Điều phối nhu yếu phẩm:** Quản lý kho hàng và phân phối mì tôm, nước uống, thuốc men đến các vùng bị chia cắt.
- **📊 Bảng thống kê thời gian thực:** Cung cấp cái nhìn toàn cảnh về tình hình lũ lụt cho ban điều hành.

## 🏗️ Kiến trúc hệ thống
Hệ thống được xây dựng dựa trên kiến trúc **Layered Architecture (Kiến trúc phân tầng)** kết hợp với các nguyên lý **Clean Architecture**:

- **Presentation Layer:** Flutter Web mang lại trải nghiệm mượt mà, đa nền tảng.
- **Application Layer:** Xử lý logic nghiệp vụ (Services, Use Cases, DTOs).
- **Domain Layer:** Chứa các thực thể cốt lõi (Entities) và quy tắc nghiệp vụ.
- **Infrastructure Layer:** Quản lý kết nối cơ sở dữ liệu (Spring Data JPA), migrations (Flyway) và lưu trữ tệp tin.

## 🛠️ Công nghệ sử dụng
- **Backend:** Java 17, Spring Boot 3.2, Spring Security (JWT Auth), Hibernate/JPA.
- **Frontend:** Flutter (Web), Google Maps API.
- **Database:** PostgreSQL 15.
- **DevOps:** Docker, Docker Compose, Flyway (DB Migration).
- **API Documentation:** Swagger UI / OpenAPI 3.

## 📦 Hướng dẫn cài đặt và khởi chạy (Docker)
Hệ thống đã được đóng gói hoàn toàn bằng Docker. Bạn chỉ cần 1 câu lệnh duy nhất để khởi chạy toàn bộ môi trường (DB, Backend, Frontend).

1. **Yêu cầu:** Máy tính đã cài đặt Docker & Docker Desktop.
2. **Khởi chạy:**
   ```bash
   docker compose up --build -d
   ```
3. **Truy cập:**
   - **Frontend:** [http://localhost:8081](http://localhost:8081)
   - **Backend API:** [http://localhost:8080](http://localhost:8080)
   - **Swagger Docs:** [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)

## � Tài khoản mặc định
Hệ thống cung cấp các tài khoản mặc định để kiểm thử các phân quyền khác nhau:

| Vai trò | Email | Mật khẩu |
| :--- | :--- | :--- |
| **Quản trị viên (Admin)** | `admin@rescue.vn` | `admin123` |
| **Điều phối viên (Coordinator)** | `coordinator@rescue.vn` | `admin123` |
| **Nhân viên cứu hộ (Rescue Staff)** | `staff@rescue.vn` | `admin123` |

> [!NOTE]
> Tất cả mật khẩu mặc định đều là `admin123`. Trong môi trường thực tế, vui lòng thay đổi mật khẩu ngay sau khi đăng nhập lần đầu.

## �📁 Cấu trúc thư mục
```text
├── backend                 # Spring Boot Source Code
│   ├── src/main/java/vn/rescue
│   │   ├── core/application # Services & DTOs
│   │   ├── core/domain      # Entities & Repositories
│   │   ├── core/presentation # Controllers
│   ├── src/main/resources   # Config & Flyway Migrations
│   └── Dockerfile
├── frontend                # Flutter Source Code
│   ├── lib/screens          # Màn hình giao diện
│   ├── lib/main.dart        # Điểm bắt đầu ứng dụng
│   └── Dockerfile
└── docker-compose.yml       # Cấu hình Orchestration
```

## 🛡️ Thiết kế Cơ sở dữ liệu
Hệ thống sử dụng cơ sở dữ liệu quan hệ với các bảng chính:
- `users`, `roles`: Quản lý phân quyền.
- `rescue_requests`: Lưu trữ yêu cầu SOS từ người dân.
- `attachments`: Lưu trữ hình ảnh hiện trường.
- `request_status_history`: Theo dõi quá trình cứu hộ (Pending -> Assigned -> Completed).
- `rescue_teams`, `vehicles`: Quản lý nguồn lực cứu trợ.

---
*Dự án được phát triển trong khuôn khổ môn học Công nghệ Phần mềm - 2024.*
