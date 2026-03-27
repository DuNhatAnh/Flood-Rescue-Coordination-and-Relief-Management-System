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
        
        // New fields
        distribution.setType(request.getType() != null ? request.getType() : "EXPORT");
        distribution.setDestinationWarehouseId(request.getDestinationWarehouseId());
        
        if ("TRANSFER".equals(distribution.getType())) {
            distribution.setStatus("IN_TRANSIT");
        } else {
            distribution.setStatus("COMPLETED");
        }
        
        Distribution savedDistribution = distributionRepository.save(distribution);

        for (DistributionRequest.ItemQuantity itemReq : request.getItems()) {
            Inventory inventory = inventoryRepository.findByWarehouseIdAndItemId(
                    request.getWarehouseId(), itemReq.getItemId()
            ).orElseThrow(() -> new RuntimeException("Item not found in warehouse"));

            if (inventory.getQuantity() < itemReq.getQuantity()) {
                throw new RuntimeException("Insufficient stock in source warehouse");
            }

            // Deduct from source
            inventory.setQuantity(inventory.getQuantity() - itemReq.getQuantity());
            inventoryRepository.save(inventory);

            // If EXPORT, items are gone.
            // If TRANSFER, they are in transit (already deducted from source).
            // They will be added to destination in a separate step or automatically if simplicity is preferred.
            // For now, let's handle the destination addition ONLY when status becomes COMPLETED.

            DistributionDetail detail = new DistributionDetail();
            detail.setDistributionId(savedDistribution.getId());
            detail.setItemId(itemReq.getItemId());
            detail.setQuantity(itemReq.getQuantity());
            detailRepository.save(detail);
        }

        return savedDistribution;
    }

    @Transactional
    public Distribution completeTransfer(String distributionId) {
        Distribution distribution = distributionRepository.findById(distributionId)
                .orElseThrow(() -> new RuntimeException("Transfer not found"));
        
        if (!"TRANSFER".equals(distribution.getType()) || !"IN_TRANSIT".equals(distribution.getStatus())) {
            throw new RuntimeException("Invalid transfer status");
        }

        List<DistributionDetail> details = detailRepository.findAllByDistributionId(distribution.getId());
        
        for (DistributionDetail detail : details) {
            Inventory destInventory = inventoryRepository.findByWarehouseIdAndItemId(
                    distribution.getDestinationWarehouseId(), detail.getItemId()
            ).orElse(new Inventory());
            
            if (destInventory.getId() == null) {
                destInventory.setWarehouseId(distribution.getDestinationWarehouseId());
                destInventory.setItemId(detail.getItemId());
                destInventory.setQuantity(0);
            }
            
            destInventory.setQuantity(destInventory.getQuantity() + detail.getQuantity());
            inventoryRepository.save(destInventory);
        }

        distribution.setStatus("COMPLETED");
        return distributionRepository.save(distribution);
    }

    public List<Distribution> getHistory() {
        return distributionRepository.findAll();
    }
}
