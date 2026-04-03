package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.StockTransaction;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface StockTransactionRepository extends MongoRepository<StockTransaction, String> {


    List<StockTransaction> findByWarehouseId(String warehouseId);
    
    List<StockTransaction> findByTimestampBetweenOrderByTimestampAsc(LocalDateTime start, LocalDateTime end);

    List<StockTransaction> findByTransactionType(String transactionType);

    List<StockTransaction> findByStaffId(String staffId);
}