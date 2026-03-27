package vn.rescue.core.domain.repositories;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.SystemLog;

import java.util.List;


@Repository
public interface SystemLogRepository extends MongoRepository<SystemLog, String> {

    // 1. Lấy tất cả log và sắp xếp theo thời gian mới nhất
    List<SystemLog> findAllByOrderByCreatedAtDesc();

    // 2. Lấy nhật ký của một người dùng cụ thể
    List<SystemLog> findByUserIdOrderByCreatedAtDesc(String userId);

    // 3. Lấy nhật ký theo loại hành động
    List<SystemLog> findByActionOrderByCreatedAtDesc(String action);

    // 4. Hỗ trợ phân trang (Pageable)
    Page<SystemLog> findAllByOrderByCreatedAtDesc(Pageable pageable);

    // 5. Tìm kiếm log theo từ khóa trong phần chi tiết
    List<SystemLog> findByDetailsContainingIgnoreCase(String keyword);





}
