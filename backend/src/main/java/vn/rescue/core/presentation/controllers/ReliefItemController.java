package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.dto.ReliefItemRequest;
import vn.rescue.core.application.services.ReliefItemService;
import vn.rescue.core.domain.entities.ReliefItem;

import java.util.List;

@RestController
@RequestMapping("/api/relief-items")
@RequiredArgsConstructor
public class ReliefItemController {

    private final ReliefItemService reliefItemService;

    @GetMapping
    public List<ReliefItem> getAllReliefItems() {
        return reliefItemService.getAllReliefItems();
    }

    @PostMapping
    public ReliefItem createReliefItem(@RequestBody ReliefItemRequest request) {
        return reliefItemService.createReliefItem(request);
    }

    @PutMapping("/{id}")
    public ReliefItem updateReliefItem(@PathVariable("id") String id, @RequestBody ReliefItemRequest request) {
        return reliefItemService.updateReliefItem(id, request);
    }

    @DeleteMapping("/{id}")
    public void deleteReliefItem(@PathVariable("id") String id) {
        reliefItemService.deleteReliefItem(id);
    }
}
