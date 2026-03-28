# 🌊 Hệ Thống Điều Phối Cứu Hộ & Quản Lý Cứu Trợ Lũ Lụt (FRS)

[![Spring Boot](https://img.shields.io/badge/Backend-Spring%20Boot%203.2-brightgreen)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Frontend-Flutter%20Web-blue)](https://flutter.dev/)
[![MongoDB](https://img.shields.io/badge/Database-MongoDB%20Atlas-green)](https://www.mongodb.com/)
[![Docker](https://img.shields.io/badge/Orchestration-Docker%20Compose-blue)](https://www.docker.com/)

## 📖 Tổng Quan Dự Án
**Flood Rescue System (FRS)** là một nền tảng kỹ thuật số toàn diện được thiết kế để tối ưu hóa công tác ứng phó khẩn cấp trong các thảm họa lũ lụt. Bằng cách kết nối trực tiếp người dân vùng lũ với các đội cứu hộ và điều phối viên, FRS giúp tối ưu hóa việc phân bổ nguồn lực, nâng cao nhận thức tình huống và đẩy nhanh quá trình phân phối hàng cứu trợ, nhằm giảm thiểu tối đa thiệt hại về người và tài sản.

Dự án này được phát triển trong khuôn khổ môn học **Công nghệ Phần mềm**, chú trọng vào kiến trúc hệ thống bền vững, tính bảo mật và khả năng mở rộng.

---

## 🚀 Các Phân Hệ & Tính Năng Chính

### 👤 Phân Hệ Người Dân (Gửi SOS)
- **SOS Khẩn Cấp:** Gửi yêu cầu cứu hộ nhanh chóng kèm tọa độ GPS, hình ảnh hiện trường và mức độ khẩn cấp.
- **Báo Cáo An Toàn:** Cập nhật tình trạng an toàn cá nhân để thông báo cho cơ quan chức năng.
- **Theo Dõi Thời Gian Thực:** Giám sát trạng thái của yêu cầu cứu hộ (Chờ xử lý → Đã gán → Đang thực hiện → Hoàn thành).

### 🗺️ Phân Hệ Điều Phối Viên
- **Bảng Điều Khiển Vận Hành:** Cái nhìn tổng cảnh về tất cả các yêu cầu SOS đang hoạt động và nguồn lực cứu hộ.
- **Phân Bổ Thông Minh:** Điều động đội cứu hộ và phương tiện chuyên dụng (thuyền, xe tải) cho các nhiệm vụ khẩn cấp.
- **Quản Lý Nguồn Lực:** Theo dõi trạng thái sẵn sàng của các đội và phương tiện theo thời gian thực.

### 📦 Phân Hệ Cứu Trợ & Kho Vận
- **Quản Lý Kho Hàng:** Theo dõi mức tồn kho các nhu yếu phẩm thiết yếu (thực phẩm, nước uống, thuốc men).
- **Quy Trình Phân Phối:** Quản lý việc cấp phát hàng cứu trợ cho từng nhiệm vụ cứu hộ cụ thể.
- **Cập Nhật Tồn Kho:** Tự động cập nhật số lượng hàng hóa sau khi phân phối.

### 🛡️ Phân Hệ Quản Trị & Hệ Thống
- **Quản Lý Người Dùng:** Phân quyền dựa trên vai trò (RBAC) cho Admin, Điều phối viên, Nhân viên và Người dân.
- **Kiểm Soát Hệ Thống:** Ghi log chi tiết mọi thay đổi trạng thái để đảm bảo tính minh bạch và trách nhiệm.
- **Thống Kê:** Cung cấp thông tin chi tiết qua dữ liệu về hiệu quả và phạm vi cứu hộ.

---

## 🏗️ Kiến Trúc Kỹ Thuật
Hệ thống tuân thủ kiến trúc **Layered Architecture** (Kiến trúc phân tầng) kết hợp với các nguyên lý của **Clean Architecture** để đảm bảo tính dễ bảo trì và kiểm thử:

- **Lớp Presentation (Trình diễn):** 
    - **Frontend:** Sử dụng Flutter Web cho trải nghiệm người dùng phản hồi nhanh, đa nền tảng.
    - **Backend:** Các RESTful Controller được xây dựng với Spring Web.
- **Lớp Application (Ứng dụng):** 
    - Logic nghiệp vụ được đóng gói trong các Service và DTO.
    - Bảo mật được xử lý qua **Spring Security** và **JWT (JSON Web Tokens)**.
- **Lớp Domain (Nghiệp vụ cốt lõi):** 
    - Chứa các thực thể (Entities) và quy tắc nghiệp vụ chính. 
    - Tích hợp **MongoDB** thông qua Spring Data MongoDB để đạt được tính sẵn sàng cao và mô hình dữ liệu linh hoạt.
- **Lớp Infrastructure (Hạ tầng):** 
    - Quản lý cấu hình, kết nối cơ sở dữ liệu và vận hành Docker.

---

## 🛠️ Công Nghệ Sử Dụng
- **Backend:** Java 17, Spring Boot 3.2, Spring Security, JWT, Lombok.
- **Frontend:** Flutter (Web), Google Maps API.
- **Cơ sở dữ liệu:** MongoDB (Atlas/Community), cung cấp thiết kế schema linh hoạt, lý tưởng cho dữ liệu thảm họa không cố định.
- **Tài liệu API:** Swagger UI / OpenAPI 3 giúp tích hợp Frontend-Backend mượt mà.
- **DevOps:** Docker & Docker Compose để quản lý môi trường nhất quán.

---

## 📦 Hướng Dẫn Cài Đặt (Docker)

Toàn bộ môi trường đã được đóng gói bằng Docker để triển khai "một chạm".

### Yêu Cầu Tiên Quyết
- Máy tính đã cài đặt và đang chạy Docker Desktop.

### Các Bước Cài Đặt
1. **Clone repository:**
   ```bash
   git clone <repository-url>
   cd Flood-Rescue-Coordination-and-Relief-Management-System
   ```
2. **Khởi chạy với Docker Compose:**
   ```bash
   docker compose up --build -d
   ```

### Địa Chỉ Truy Cập
- **Frontend:** [http://localhost:8081](http://localhost:8081)
- **Tài liệu API (Swagger):** [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
- **API Base URL:** `http://localhost:8080`

---

## 🔐 Tài Khoản Mặc Định (Để Kiểm Thử)

| Vai Trò | Email | Mật Khẩu |
| :--- | :--- | :--- |
| **Quản trị viên (Admin)** | `admin@rescue.vn` | `admin123` |
| **Điều phối viên** | `coordinator@rescue.vn` | `admin123` |
| **Nhân viên cứu hộ** | `staff@rescue.vn` | `admin123` |

> [!IMPORTANT]
> Vui lòng thay đổi mật khẩu mặc định ngay sau khi đăng nhập lần đầu trong môi trường thực tế.

---

## 📂 Cấu Trúc Thư Mục
```text
├── backend                 # Spring Boot API
│   ├── src/main/java/vn/rescue/core
│   │   ├── application     # Logic nghiệp vụ (Service/DTO)
│   │   ├── domain          # Thực thể & Repository (Entity/Repo)
│   │   ├── infrastructure  # Cấu hình & Bảo mật (Config/Security)
│   │   └── presentation    # REST Controllers
│   └── Dockerfile
├── frontend                # Flutter Web App
│   ├── lib/screens          # Giao diện & Các màn hình
│   └── Dockerfile
└── docker-compose.yml       # Điều phối hệ thống (Orchestration)
```

---
*Phát triển cho môn học Công nghệ Phần mềm - 2024.*
