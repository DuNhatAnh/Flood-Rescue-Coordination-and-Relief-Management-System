package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Distribution;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface DistributionRepository extends MongoRepository<Distribution, String> {

    // 1. Lấy toàn bộ lịch sử sắp xếp theo thời gian mới nhất (Dùng cho danh sách Timeline)
    List<Distribution> findAllByOrderByDistributedAtDesc();

    // 2. Lọc lịch sử theo loại (Chỉ xem XUẤT CỨU TRỢ hoặc Chỉ xem ĐIỀU CHUYỂN)
    List<Distribution> findByTypeOrderByDistributedAtDesc(String type);

    // 3. Tìm các giao dịch trong một khoảng thời gian (Dùng để làm báo cáo Theo Tuần/Tháng)
    List<Distribution> findByDistributedAtBetween(LocalDateTime start, LocalDateTime end);

    // 4. Đếm số lượng giao dịch theo trạng thái (Dùng cho các thẻ con số ở trên cùng)
    long countByStatus(String status);

    // 5. Tìm các giao dịch liên quan đến một kho cụ thể
    List<Distribution> findByWarehouseId(String warehouseId);

    // 6. Truy vấn nâng cao: Tìm các giao dịch COMPLETED của một nhân viên cụ thể
    @Query("{ 'distributed_by': ?0, 'status': 'COMPLETED' }")
    List<Distribution> findCompletedByStaff(String staffId);
}