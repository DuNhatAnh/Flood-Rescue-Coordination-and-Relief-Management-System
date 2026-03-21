package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.InventoryResponse;
import vn.rescue.core.application.dto.StockInRequest;
import vn.rescue.core.domain.entities.Inventory;
import vn.rescue.core.domain.entities.ReliefItem;
import vn.rescue.core.domain.entities.StockTransaction;
import vn.rescue.core.domain.repositories.InventoryRepository;
import vn.rescue.core.domain.repositories.ReliefItemRepository;
import vn.rescue.core.domain.repositories.StockTransactionRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryService {
    private final InventoryRepository inventoryRepository;
    private final ReliefItemRepository reliefItemRepository;
    private final StockTransactionRepository stockTransactionRepository;

    @Transactional
    public InventoryResponse importStock(StockInRequest request) {
        // Find existing inventory record or create new
        Inventory inventory = inventoryRepository
                .findByWarehouseIdAndItemId(request.getWarehouseId(), request.getItemId())
                .orElse(new Inventory());

        if (inventory.getId() == null) {
            inventory.setWarehouseId(request.getWarehouseId());
            inventory.setItemId(request.getItemId());
            inventory.setQuantity(0);
        }

        // Add quantity
        inventory.setQuantity(inventory.getQuantity() + request.getQuantity());
        Inventory saved = inventoryRepository.save(inventory);

        // LOG TRANSACTION (Import Slip)
        StockTransaction transaction = StockTransaction.builder()
                .warehouseId(request.getWarehouseId())
                .itemId(request.getItemId())
                .quantity(request.getQuantity())
                .transactionType("IMPORT")
                .source(request.getSource())
                .referenceNumber(request.getReferenceNumber())
                .expiryDate(request.getExpiryDate())
                .condition(request.getCondition())
                .timestamp(LocalDateTime.now())
                .build();
        stockTransactionRepository.save(transaction);

        return mapToResponse(saved);
    }

    public List<InventoryResponse> getWarehouseInventory(String warehouseId) {
        return inventoryRepository.findByWarehouseId(warehouseId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private InventoryResponse mapToResponse(Inventory inventory) {
        String itemName = "Unknown Item";
        String unit = "N/A";
        String imageUrl = null;
        
        ReliefItem item = null;
        if (inventory.getItemId() != null) {
            item = reliefItemRepository.findById(inventory.getItemId()).orElse(null);
        }
        
        if (item != null) {
            itemName = item.getItemName();
            unit = item.getUnit();
            imageUrl = item.getImageUrl();
        }

        return InventoryResponse.builder()
                .id(inventory.getId())
                .warehouseId(inventory.getWarehouseId())
                .itemId(inventory.getItemId())
                .itemName(itemName)
                .unit(unit)
                .imageUrl(imageUrl) // Include imageUrl in the builder
                .quantity(inventory.getQuantity())
                .build();
    }
}
