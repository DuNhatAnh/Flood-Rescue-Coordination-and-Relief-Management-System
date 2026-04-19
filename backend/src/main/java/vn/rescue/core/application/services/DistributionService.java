package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.rescue.core.application.dto.DistributionRequest;
import vn.rescue.core.domain.entities.Distribution;
import vn.rescue.core.domain.entities.DistributionDetail;
import vn.rescue.core.domain.entities.Inventory;
import vn.rescue.core.domain.entities.MissionItem;
import vn.rescue.core.domain.repositories.DistributionDetailRepository;
import vn.rescue.core.domain.repositories.DistributionRepository;
import vn.rescue.core.domain.repositories.InventoryRepository;
import vn.rescue.core.domain.repositories.AssignmentRepository;
import vn.rescue.core.domain.repositories.ReliefItemRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class DistributionService {

    @Autowired
    private DistributionRepository distributionRepository;
    @Autowired
    private DistributionDetailRepository detailRepository;
    @Autowired
    private InventoryRepository inventoryRepository;
    @Autowired
    private AssignmentRepository assignmentRepository;
    @Autowired
    private RescueCoordinationService rescueCoordinationService;
    @Autowired
    private InventoryService inventoryService;
    @Autowired
    private ReliefItemRepository reliefItemRepository;

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

        // Thông báo cho kho đích nếu là điều chuyển hàng
        if ("TRANSFER".equals(distribution.getType()) && distribution.getDestinationWarehouseId() != null) {
            rescueCoordinationService.notifyWarehouse(
                distribution.getDestinationWarehouseId(), 
                "Yêu cầu điều phối hàng", 
                "Có yêu cầu điều phối hàng từ kho khác đến kho của bạn. Vui lòng kiểm tra mục 'Nhập kho'.", 
                "WARNING"
            );
        }

        for (DistributionRequest.ItemQuantity itemReq : request.getItems()) {
            // Sử dụng InventoryService để xuất kho (đảm bảo ghi log và lịch sử)
            vn.rescue.core.application.dto.StockOutRequest stockOutRequest = vn.rescue.core.application.dto.StockOutRequest.builder()
                    .warehouseId(request.getWarehouseId())
                    .itemId(itemReq.getItemId())
                    .quantity(itemReq.getQuantity())
                    .reason("MISSION_EXPORT")
                    .assignmentId(request.getRequestId()) // requestId ở đây là ID của Assignment
                    .build();

            inventoryService.exportStock(stockOutRequest, userId);

            DistributionDetail detail = new DistributionDetail();
            detail.setDistributionId(savedDistribution.getId());
            detail.setItemId(itemReq.getItemId());
            detail.setQuantity(itemReq.getQuantity());
            detailRepository.save(detail);
        }

        // Logic bổ sung: Cập nhật Assignment nếu tìm thấy theo requestId
        if (request.getRequestId() != null) {
            assignmentRepository.findById(request.getRequestId()).ifPresent(assignment -> {
                assignment.setItemsExported(true);
                
                // Đồng bộ danh sách mặt hàng thực tế đã được chuẩn bị
                List<MissionItem> actualMissionItems = new ArrayList<>();
                for (DistributionRequest.ItemQuantity itemReq : request.getItems()) {
                    Inventory inventory = inventoryRepository.findByWarehouseIdAndItemId(
                            request.getWarehouseId(), itemReq.getItemId()
                    ).orElse(null);
                    
                    if (inventory == null || inventory.getItemName() == null || inventory.getItemName().isEmpty()) {
                        final String itemId = itemReq.getItemId();
                        vn.rescue.core.domain.entities.ReliefItem globalItem = reliefItemRepository.findById(itemId).orElse(null);
                        actualMissionItems.add(MissionItem.builder()
                            .itemId(itemId)
                            .itemName(globalItem != null ? globalItem.getItemName() : (inventory != null ? inventory.getItemName() : "Vật phẩm"))
                            .unit(globalItem != null ? globalItem.getUnit() : (inventory != null ? inventory.getUnit() : "-"))
                            .quantity(itemReq.getQuantity())
                            .build());
                    } else {
                        actualMissionItems.add(MissionItem.builder()
                            .itemId(itemReq.getItemId())
                            .itemName(inventory.getItemName())
                            .unit(inventory.getUnit())
                            .quantity(itemReq.getQuantity())
                            .build());
                    }
                }
                assignment.setMissionItems(actualMissionItems);
                assignmentRepository.save(assignment);
            });
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
