package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.mongodb.repository.Query;
import vn.rescue.core.domain.entities.Inventory;

import java.util.List;
import java.util.Optional;

@Repository
public interface InventoryRepository extends MongoRepository<Inventory, String> {
    //1.tim tat ca hang hoa thuoc mot kho cu the
    List<Inventory> findByWarehouseId(String warehouseId);
    //2. tim chin xac mot loai mat hang trong mot kho
    Optional<Inventory> findByWarehouseIdAndItemId(String warehouseId, String itemId);

    // 3. Tìm các mặt hàng có số lượng thấp hơn hoặc bằng ngưỡng tối thiểu (Cảnh báo hết hàng)
    // Hàm này cực kỳ quan trọng để hiển thị thông báo đỏ trên Dashboard
    @Query("{ '$expr': { '$lte': [ '$quantity', '$min_threshold' ] } }")
    List<Inventory> findLowStockItems();

    // 4. Tìm các mặt hàng sắp hết theo từng kho cụ thể
    @Query("{ 'warehouse_id': ?0, '$expr': { '$lte': [ '$quantity', '$min_threshold' ] } }")
    List<Inventory> findLowStockItemsByWarehouse(String warehouseId);

    // 5. Tìm kiếm hàng hóa trong kho theo tên (Không phân biệt hoa thường)
    List<Inventory> findByItemNameContainingIgnoreCase(String itemName);

    // 6. Xóa toàn bộ hàng hóa của một kho (Dùng khi giải thể kho)
    void deleteByWarehouseId(String warehouseId);
}
