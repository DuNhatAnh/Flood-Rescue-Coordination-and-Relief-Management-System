package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.InventoryResponse;
import vn.rescue.core.application.dto.StockInRequest;
import vn.rescue.core.application.dto.StockOutRequest;
import vn.rescue.core.domain.entities.Inventory;
import vn.rescue.core.domain.entities.MissionItem;
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
        // 0. Lấy thông tin Item từ danh mục để đồng bộ dữ liệu (tránh bị null/Vật phẩm)
        ReliefItem item = reliefItemRepository.findById(request.getItemId()).orElse(null);
        String itemName = (item != null) ? item.getItemName() : "Vật phẩm";
        String unit = (item != null) ? item.getUnit() : "N/A";

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

        // Đồng bộ lại tên và đơn vị để đảm bảo dữ liệu trong bảng Inventory luôn đầy đủ
        inventory.setItemName(itemName);
        inventory.setUnit(unit);

        // 2. Cập nhật số lượng
        int oldQty = inventory.getQuantity() != null ? inventory.getQuantity() : 0;
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

        // 4. GHI NHẬT KÝ HỆ THỐNG (SCRUM-54) - Sử dụng biến đã lấy ở bước 0
        systemService.logAction(userId, "IMPORT_STOCK",
                String.format("Nhập kho %s: +%d %s (Tổng: %d)", itemName, request.getQuantity(), unit, saved.getQuantity()),
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

    @Transactional
    public int exportStock(StockOutRequest request, String userId) {
        // 1. Tìm bản ghi kho
        Inventory inventory = inventoryRepository
                .findByWarehouseIdAndItemId(request.getWarehouseId(), request.getItemId())
                .orElse(null);

        if (inventory == null) {
            return 0; // Không có hàng này trong kho
        }

        // 2. Kiểm tra tồn kho và trừ số lượng (Auto-cap tại mức tồn kho hiện có)
        int available = inventory.getQuantity() != null ? inventory.getQuantity() : 0;
        int toExport = Math.min(available, request.getQuantity());

        if (toExport > 0) {
            inventory.setQuantity(available - toExport);
            inventoryRepository.save(inventory);

            // 3. LƯU GIAO DỊCH KHO
            StockTransaction transaction = StockTransaction.builder()
                    .warehouseId(request.getWarehouseId())
                    .itemId(request.getItemId())
                    .quantity(toExport)
                    .transactionType("EXPORT")
                    .reason(request.getReason())
                    .assignmentId(request.getAssignmentId())
                    .staffId(userId)
                    .timestamp(LocalDateTime.now())
                    .build();
            stockTransactionRepository.save(transaction);

            // 4. GHI NHẬT KÝ HỆ THỐNG
            systemService.logAction(userId, "EXPORT_STOCK",
                    String.format("Xuất kho %s: -%d %s cho nhiệm vụ #%s",
                            inventory.getItemName(), toExport, inventory.getUnit(), 
                            request.getAssignmentId() != null ? request.getAssignmentId().substring(0, 8) : "N/A"),
                    "INVENTORY");
            
            // CẢNH BÁO NẾU THIẾU HÀNG (Vấn đề 5 - Đã nâng cấp thành thông báo khẩn cấp)
            if (toExport < request.getQuantity()) {
                systemService.logAction(userId, "INVENTORY_SHORTAGE",
                    String.format("KHO KHÔNG ĐỦ HÀNG: %s cho nhiệm vụ #%s. Yêu cầu: %d, Thực tế: %d. Cần điều chuyển hàng (TRANSFER) gấp!",
                        inventory.getItemName(), request.getAssignmentId() != null ? request.getAssignmentId().substring(0, 8) : "N/A", request.getQuantity(), toExport),
                    "INVENTORY");
            }
        }
        return toExport;
    }

    @Transactional
    public void batchExport(String warehouseId, String assignmentId, List<MissionItem> items, String userId) {
        if (items == null) return;
        for (MissionItem item : items) {
            StockOutRequest request = StockOutRequest.builder()
                    .warehouseId(warehouseId)
                    .itemId(item.getItemId())
                    .quantity(item.getQuantity())
                    .reason("RESCUE_MISSION")
                    .assignmentId(assignmentId)
                    .build();
            int actualExported = exportStock(request, userId);
            // Cập nhật lại số lượng thực tế đã mang đi nếu bị hụt kho (Auto-cap)
            item.setQuantity(actualExported);
        }
    }

    @Transactional
    public void batchReturn(String warehouseId, String assignmentId, List<MissionItem> items, String userId) {
        if (items == null || items.isEmpty()) return;
        
        for (MissionItem item : items) {
            if (item.getQuantity() != null && item.getQuantity() > 0) {
                StockInRequest request = StockInRequest.builder()
                        .warehouseId(warehouseId)
                        .itemId(item.getItemId())
                        .quantity(item.getQuantity())
                        .source("MISSION_RETURN")
                        .referenceNumber(assignmentId)
                        .condition("GOOD") // Mặc định hàng tốt, team leader phân loại sau
                        .build();
                importStock(request, userId);
            }
        }
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