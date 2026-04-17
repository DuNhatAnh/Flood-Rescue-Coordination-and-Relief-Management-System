package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RescueRequest;
import org.springframework.data.mongodb.repository.Query;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Collection;

@Repository
public interface RescueRequestRepository extends MongoRepository<RescueRequest, String> {
    List<RescueRequest> findByStatus(String status);
    long countByStatus(String status);
    Optional<RescueRequest> findFirstByCustomId(String customId);
    long countByCustomIdIsNotNull();
    List<RescueRequest> findByCitizenPhone(String citizenPhone);

    boolean existsByTeamIdAndStatusIn(String teamId, Collection<String> statuses);

    boolean existsByTeamIdAndStatus(String teamId, String status);

    List<RescueRequest> findByStatusOrderByCreatedAtDesc(String status);

    List<RescueRequest> findByCreatedAtBetweenOrderByCreatedAtAsc(LocalDateTime start, LocalDateTime end);

    List<RescueRequest> findByStatusIn(Collection<String> statuses);

    long countByUrgencyLevel(String urgencyLevel);

    /**
     * 4. Cho Bộ lọc & Tìm kiếm nâng cao:
     * Tìm kiếm theo tên người dân hoặc địa chỉ (Không phân biệt hoa thường).
     */
    @Query("{ '$or': [ " +
            "{ 'citizen_name': { '$regex': ?0, '$options': 'i' } }, " +
            "{ 'address_text': { '$regex': ?0, '$options': 'i' } }, " +
            "{ 'custom_id': { '$regex': ?0, '$options': 'i' } } " +
            "] }")
    List<RescueRequest> searchRequests(String keyword);

    /**
     * 5. Cho Thống kê hiệu suất:
     * Đếm tổng số người cần cứu trợ trong một khoảng thời gian.
     */
    @Query(value = "{ 'created_at' : { '$gte' : ?0, '$lte' : ?1 } }", count = true)
    long countTotalPeopleInPeriod(LocalDateTime start, LocalDateTime end);

    /**
     * 6. Lấy các yêu cầu cứu trợ theo mức độ khẩn cấp và trạng thái
     * Ưu tiên xử lý các ca cấp bách trước.
     */
    List<RescueRequest> findByUrgencyLevelAndStatus(String urgencyLevel, String status);

}
