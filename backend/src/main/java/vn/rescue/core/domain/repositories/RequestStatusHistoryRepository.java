package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import java.util.List;
@Repository
public interface RequestStatusHistoryRepository extends MongoRepository<RequestStatusHistory, String> {

    // Tìm lịch sử thay đổi của một nhiệm vụ cụ thể
    List<RequestStatusHistory> findByRequestId(String requestId);

}
