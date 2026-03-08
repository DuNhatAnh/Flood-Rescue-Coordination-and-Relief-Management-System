package vn.rescue.core.domain.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Inventory;

@Repository
public interface InventoryRepository extends JpaRepository<Inventory, Integer> {
}
