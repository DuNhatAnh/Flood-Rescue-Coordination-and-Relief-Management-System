package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.DistributionRequest;
import vn.rescue.core.domain.entities.Distribution;
import vn.rescue.core.domain.entities.DistributionDetail;
import vn.rescue.core.domain.entities.Inventory;
import vn.rescue.core.domain.repositories.DistributionDetailRepository;
import vn.rescue.core.domain.repositories.DistributionRepository;
import vn.rescue.core.domain.repositories.InventoryRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DistributionService {

    private final DistributionRepository distributionRepository;
    private final DistributionDetailRepository detailRepository;
    private final InventoryRepository inventoryRepository;

    @Transactional
    public Distribution createDistribution(DistributionRequest request, String userId) {
        Distribution distribution = new Distribution();
        distribution.setWarehouseId(request.getWarehouseId());
        distribution.setRequestId(request.getRequestId());
        distribution.setDistributedBy(userId);
        distribution.setDistributedAt(LocalDateTime.now());
        
        Distribution savedDistribution = distributionRepository.save(distribution);

        for (DistributionRequest.ItemQuantity itemReq : request.getItems()) {
            Inventory inventory = inventoryRepository.findByWarehouseIdAndItemId(
                    request.getWarehouseId(), itemReq.getItemId()
            ).orElseThrow(() -> new RuntimeException("Item not found in warehouse"));

            if (inventory.getQuantity() < itemReq.getQuantity()) {
                throw new RuntimeException("Insufficient stock");
            }

            inventory.setQuantity(inventory.getQuantity() - itemReq.getQuantity());
            inventoryRepository.save(inventory);

            DistributionDetail detail = new DistributionDetail();
            detail.setDistributionId(savedDistribution.getId());
            detail.setItemId(itemReq.getItemId());
            detail.setQuantity(itemReq.getQuantity());
            detailRepository.save(detail);
        }

        return savedDistribution;
    }

    public List<Distribution> getHistory() {
        return distributionRepository.findAll();
    }
}
