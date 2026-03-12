package vn.rescue.core.application.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.ReliefItemRequest;
import vn.rescue.core.domain.entities.ReliefItem;
import vn.rescue.core.domain.repositories.ReliefItemRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ReliefItemService {

    private final ReliefItemRepository reliefItemRepository;

    public List<ReliefItem> getAllReliefItems() {
        return reliefItemRepository.findAll();
    }

    public ReliefItem createReliefItem(ReliefItemRequest request) {
        ReliefItem item = new ReliefItem();
        item.setItemName(request.getItemName());
        item.setUnit(request.getUnit());
        item.setDescription(request.getDescription());
        return reliefItemRepository.save(item);
    }

    public ReliefItem updateReliefItem(String id, ReliefItemRequest request) {
        ReliefItem item = reliefItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Relief item not found"));
        item.setItemName(request.getItemName());
        item.setUnit(request.getUnit());
        item.setDescription(request.getDescription());
        return reliefItemRepository.save(item);
    }

    public void deleteReliefItem(String id) {
        reliefItemRepository.deleteById(id);
    }
}
