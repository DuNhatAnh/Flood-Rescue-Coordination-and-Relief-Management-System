package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.ReliefItemRequest;
import vn.rescue.core.domain.entities.ReliefItem;
import vn.rescue.core.domain.repositories.ReliefItemRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ReliefItemService {

    private final ReliefItemRepository reliefItemRepository;

    public List<ReliefItem> getAllReliefItems() {
        return reliefItemRepository.findAll();
    }

    public ReliefItem createReliefItem(ReliefItemRequest request) {
        if (request == null || request.getItemName() == null || request.getItemName().trim().isEmpty()) {
            throw new BadRequestException("Tên mặt hàng cứu trợ không được để trống");
        }
        if (request.getUnit() == null || request.getUnit().trim().isEmpty()) {
            throw new BadRequestException("Đơn vị tính không được để trống");
        }
        ReliefItem item = new ReliefItem();
        item.setItemName(request.getItemName().trim());
        item.setUnit(request.getUnit().trim());
        item.setDescription(request.getDescription());
        item.setImageUrl(request.getImageUrl());
        return reliefItemRepository.save(item);
    }

    public ReliefItem updateReliefItem(String id, ReliefItemRequest request) {
        if (request == null) {
            throw new BadRequestException("Dữ liệu cập nhật mặt hàng không được để trống");
        }
        ReliefItem item = reliefItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mặt hàng cứu trợ với ID: " + id));
        if (request.getItemName() != null && !request.getItemName().trim().isEmpty()) {
            item.setItemName(request.getItemName().trim());
        }
        if (request.getUnit() != null && !request.getUnit().trim().isEmpty()) {
            item.setUnit(request.getUnit().trim());
        }
        item.setDescription(request.getDescription());
        item.setImageUrl(request.getImageUrl());
        return reliefItemRepository.save(item);
    }

    public void deleteReliefItem(String id) {
        if (!reliefItemRepository.existsById(id)) {
            throw new ResourceNotFoundException("Không tìm thấy mặt hàng cứu trợ với ID: " + id);
        }
        reliefItemRepository.deleteById(id);
    }
}
