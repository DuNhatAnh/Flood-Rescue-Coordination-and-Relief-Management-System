package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.Aggregation;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.DistributionDetail;
import vn.rescue.core.application.dto.ItemConsumptionDTO;

import java.util.List;

@Repository
public interface DistributionDetailRepository extends MongoRepository<DistributionDetail, String> {

    List<DistributionDetail> findAllByDistributionId(String distributionId);

    // Sửa lại pipeline để chắc chắn mapping đúng với cấu trúc DB (item_id)
    @Aggregation(pipeline = {
            "{ '$group': { '_id': '$item_id', 'totalQuantity': { '$sum': '$quantity' } } }",
            "{ '$sort': { 'totalQuantity': -1 } }",
            "{ '$limit': 10 }"
    })
    List<ItemConsumptionDTO> aggregateItemConsumption();

    void deleteAllByDistributionId(String distributionId);

    long countByItemId(String itemId);
}