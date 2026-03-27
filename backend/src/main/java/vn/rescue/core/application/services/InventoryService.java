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
    private final SystemManagementService systemService; // TIÊM ĐỂ GHI LOG

    @Transactional
    public InventoryResponse importStock(StockInRequest request, String userId) {
        // 1. Tìm bản ghi kho hiện có hoặc tạo mới
        Inventory inventory = inventoryRepository
                .findByWarehouseIdAndItemId(request.getWarehouseId(), request.getItemId())
                .orElse(new Inventory());

        if (inventory.getId() == null) {
            inventory.setWarehouseId(request.getWarehouseId());
            inventory.setItemId(request.getItemId());
            inventory.setQuantity(0);
            // Thiết lập ngưỡng mặc định nếu cần (ví dụ: 100)
            inventory.setMinThreshold(100);
        }

        // 2. Cập nhật số lượng
        int oldQty = inventory.getQuantity();
        inventory.setQuantity(oldQty + request.getQuantity());
        Inventory saved = inventoryRepository.save(inventory);

        // 3. LƯU GIAO DỊCH KHO (Bảng StockTransaction)
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

        // 4. GHI NHẬT KÝ HỆ THỐNG (SCRUM-54)
        String itemName = reliefItemRepository.findById(request.getItemId())
                .map(ReliefItem::getItemName).orElse("Vật phẩm");

        systemService.logAction(userId, "IMPORT_STOCK",
                String.format("Nhập kho %s: +%d %s (Tổng: %d)", itemName, request.getQuantity(), saved.getUnit(), saved.getQuantity()),
                "INVENTORY");

        return mapToResponse(saved);
    }

    // Lấy danh sách hàng hóa của kho (Dùng cho SCRUM-55 Dashboard)
    public List<InventoryResponse> getWarehouseInventory(String warehouseId) {
        return inventoryRepository.findByWarehouseId(warehouseId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    // Lấy danh sách hàng sắp hết để cảnh báo trên Dashboard
    public List<InventoryResponse> getLowStockItems(String warehouseId) {
        return inventoryRepository.findLowStockItemsByWarehouse(warehouseId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private InventoryResponse mapToResponse(Inventory inventory) {
        ReliefItem item = inventory.getItemId() != null
                ? reliefItemRepository.findById(inventory.getItemId()).orElse(null)
                : null;

        String itemName = (item != null) ? item.getItemName() : "Unknown Item";
        String unit = (item != null) ? item.getUnit() : "N/A";
        String imageUrl = (item != null) ? item.getImageUrl() : null;

        return InventoryResponse.builder()
                .id(inventory.getId())
                .warehouseId(inventory.getWarehouseId())
                .itemId(inventory.getItemId())
                .itemName(itemName)
                .unit(unit)
                .imageUrl(imageUrl)
                .quantity(inventory.getQuantity())
                .minThreshold(inventory.getMinThreshold())
                // Tính toán trạng thái để Flutter hiện màu sắc
                .status((inventory.getQuantity() != null && inventory.getMinThreshold() != null && inventory.getQuantity() <= inventory.getMinThreshold()) ? "LOW_STOCK" : "NORMAL")
                .build();
    }
}