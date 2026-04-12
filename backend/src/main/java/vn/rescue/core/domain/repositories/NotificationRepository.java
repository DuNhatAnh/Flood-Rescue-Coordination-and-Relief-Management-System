package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.mongodb.repository.Query;
import vn.rescue.core.domain.entities.Notification;
import java.util.List;

@Repository
public interface NotificationRepository extends MongoRepository<Notification, String> {

    // --- 1. TRUY VẤN CHO NGƯỜI DÙNG (MOBILE APP) ---

    // Tìm thông báo của 1 user hoặc thông báo chung toàn hệ thống, sắp xếp mới nhất
    List<Notification> findByUserIdOrUserIdIsNullOrderByCreatedAtDesc(String userId);

    // Đếm số thông báo CHƯA ĐỌC của một user bao gồm cả thông báo chung
    long countByUserIdOrUserIdIsNullAndIsReadFalse(String userId);

    // Lấy danh sách thông báo chưa đọc (Để lọc nhanh trên UI)
    List<Notification> findByUserIdAndIsReadFalseOrderByCreatedAtDesc(String userId);


    // --- 2. TRUY VẤN CHO ADMIN (DASHBOARD & LOGS) ---

    // QUAN TRỌNG: Phương thức này để sửa lỗi "cannot find symbol" ở Controller/Service
    List<Notification> findAllByOrderByCreatedAtDesc();

    // Lọc thông báo theo mức độ ưu tiên (Ví dụ: Chỉ lấy các thông báo SOS/Khẩn cấp)
    List<Notification> findByPriorityOrderByCreatedAtDesc(String priority);

    // Tìm kiếm thông báo theo từ khóa trong tiêu đề hoặc nội dung (Regex không phân biệt hoa thường)
    @Query("{ '$or': [ { 'title': { '$regex': ?0, '$options': 'i' } }, { 'content': { '$regex': ?0, '$options': 'i' } } ] }")
    List<Notification> searchNotifications(String keyword);

    // Xóa tất cả thông báo của một user (Tính năng dọn dẹp)
    // Tìm thông báo riêng cho 1 user và sắp xếp mới nhất lên đầu
    List<Notification> findByUserIdOrderByCreatedAtDesc(String userId);

    long countByUserIdAndIsReadFalse(String userId);

    // Kiểm tra xem đã có thông báo chưa đọc với tiêu đề cụ thể chưa (để tránh lặp)
    List<Notification> findByUserIdAndTitleAndIsReadFalseOrderByCreatedAtDesc(String userId, String title);

    void deleteByUserId(String userId);
}