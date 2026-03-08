package vn.rescue.core.domain.entities;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "distributions")
public class Distribution {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "distribution_id")
    private Long distributionId;

    @Column(name = "warehouse_id", nullable = false)
    private Integer warehouseId;

    @Column(name = "request_id")
    private Long requestId;

    @Column(name = "distributed_by", nullable = false)
    private Integer distributedBy;

    @Column(name = "distributed_at", insertable = false, updatable = false)
    private LocalDateTime distributedAt;
}
