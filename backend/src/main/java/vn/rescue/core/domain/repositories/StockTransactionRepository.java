package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import vn.rescue.core.domain.entities.StockTransaction;
import java.util.List;

public interface StockTransactionRepository extends MongoRepository<StockTransaction, String> {
    List<StockTransaction> findByWarehouseId(String warehouseId);
}
