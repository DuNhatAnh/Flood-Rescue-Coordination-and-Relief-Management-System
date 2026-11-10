package vn.rescue.core.application.services;

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
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

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
    @Autowired
    private WarehouseRepository warehouseRepository;

    @Transactional
    public Distribution createDistribution(DistributionRequest request, String userId) {
        if (request == null) {
            throw new BadRequestException("Dữ liệu phân phối hàng không được để trống");
        }
        if (request.getWarehouseId() == null || request.getWarehouseId().trim().isEmpty()) {
            throw new BadRequestException("Mã kho (warehouseId) không được để trống");
        }
        if (!warehouseRepository.existsById(request.getWarehouseId())) {
            throw new ResourceNotFoundException("Không tìm thấy kho hàng với ID: " + request.getWarehouseId());
        }
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new BadRequestException("Danh sách mặt hàng phân phối không được để trống");
        }

        // Kiểm tra tồn kho trước khi phân phối (BUG-DIST-01)
        for (DistributionRequest.ItemQuantity itemReq : request.getItems()) {
            if (itemReq.getItemId() == null || itemReq.getQuantity() == null || itemReq.getQuantity() <= 0) {
                throw new BadRequestException("Mặt hàng và số lượng phân phối không hợp lệ");
            }
            Inventory inventory = inventoryRepository.findByWarehouseIdAndItemId(request.getWarehouseId(), itemReq.getItemId()).orElse(null);
            int available = (inventory != null && inventory.getQuantity() != null) ? inventory.getQuantity() : 0;
            if (itemReq.getQuantity() > available) {
                String itemName = (inventory != null && inventory.getItemName() != null) ? inventory.getItemName() : itemReq.getItemId();
                throw new BadRequestException("Số lượng tồn kho không đủ cho mặt hàng '" + itemName + "' (Hiện có: " + available + ", Yêu cầu xuất: " + itemReq.getQuantity() + ")");
            }
        }

        Distribution distribution = new Distribution();
        distribution.setWarehouseId(request.getWarehouseId());
        distribution.setRequestId(request.getRequestId());
        distribution.setDistributedBy(userId);
        distribution.setDistributedAt(LocalDateTime.now());
        
        // New fields
        distribution.setType(request.getType() != null ? request.getType() : "EXPORT");
        distribution.setDestinationWarehouseId(request.getDestinationWarehouseId());
        
        if (request.getStatus() != null && !request.getStatus().trim().isEmpty()) {
            distribution.setStatus(request.getStatus().toUpperCase());
        } else if ("TRANSFER".equals(distribution.getType())) {
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
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu điều chuyển với ID: " + distributionId));
        
        if (!"TRANSFER".equals(distribution.getType()) || !"IN_TRANSIT".equals(distribution.getStatus())) {
            throw new BadRequestException("Trạng thái điều chuyển không hợp lệ để hoàn tất");
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

    /**
     * KCPM-103: Hủy đợt phân phối hàng cứu trợ và tự động hoàn kho (Rollback Inventory)
     * - Chỉ cho phép hủy khi trạng thái đơn chưa chuyển sang COMPLETED
     * - Duyệt các item đã xuất, cộng ngược số lượng vào bảng Inventory tương ứng
     * - Đổi trạng thái sang CANCELLED, lưu log thời gian cùng lý do hủy
     */
    @Transactional(rollbackFor = Exception.class)
    public Distribution cancelDistribution(String distributionId, String reason, String userId) {
        if (distributionId == null || distributionId.trim().isEmpty()) {
            throw new BadRequestException("Mã đợt phân phối (id) không được để trống");
        }

        Distribution distribution = distributionRepository.findById(distributionId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đợt phân phối với ID: " + distributionId));

        // 2. Kiểm tra điều kiện: chỉ cho phép hủy khi trạng thái đơn chưa chuyển sang COMPLETED
        if ("COMPLETED".equalsIgnoreCase(distribution.getStatus())) {
            throw new BadRequestException("Không thể hủy đợt phân phối đã hoàn thành (COMPLETED)");
        }

        if ("CANCELLED".equalsIgnoreCase(distribution.getStatus())) {
            throw new BadRequestException("Đợt phân phối này đã bị hủy trước đó");
        }

        // 3. Đặt trong @Transactional(rollbackFor = Exception.class):
        // Duyệt các item đã xuất, cộng ngược số lượng vào bảng Inventory tương ứng (Rollback Inventory)
        List<DistributionDetail> details = detailRepository.findAllByDistributionId(distribution.getId());
        for (DistributionDetail detail : details) {
            if (detail.getItemId() != null && detail.getQuantity() != null && detail.getQuantity() > 0) {
                Inventory inventory = inventoryRepository.findByWarehouseIdAndItemId(
                        distribution.getWarehouseId(), detail.getItemId()
                ).orElse(null);

                if (inventory != null) {
                    int currentQty = inventory.getQuantity() != null ? inventory.getQuantity() : 0;
                    inventory.setQuantity(currentQty + detail.getQuantity());
                    inventoryRepository.save(inventory);
                } else {
                    Inventory newInventory = new Inventory();
                    newInventory.setWarehouseId(distribution.getWarehouseId());
                    newInventory.setItemId(detail.getItemId());
                    newInventory.setQuantity(detail.getQuantity());
                    newInventory.setMinThreshold(100);
                    inventoryRepository.save(newInventory);
                }
            }
        }

        // Nếu phân phối gắn với nhiệm vụ (Assignment/requestId), cập nhật lại itemsExported = false
        if (distribution.getRequestId() != null) {
            assignmentRepository.findById(distribution.getRequestId()).ifPresent(assignment -> {
                assignment.setItemsExported(false);
                assignmentRepository.save(assignment);
            });
        }

        // 4. Đổi trạng thái Distribution sang CANCELLED và lưu log thời gian cùng lý do hủy
        distribution.setStatus("CANCELLED");
        distribution.setCancelledAt(LocalDateTime.now());
        distribution.setCancelledBy(userId);
        distribution.setCancelReason(reason != null && !reason.trim().isEmpty() ? reason : "Hủy theo yêu cầu điều phối");

        return distributionRepository.save(distribution);
    }

    public List<Distribution> getHistory() {
        return distributionRepository.findAll();
    }
}
