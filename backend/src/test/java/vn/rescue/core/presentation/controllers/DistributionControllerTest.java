package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import vn.rescue.core.application.dto.CancelDistributionRequest;
import vn.rescue.core.application.dto.DistributionRequest;
import vn.rescue.core.application.services.DistributionService;
import vn.rescue.core.domain.entities.Distribution;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-103: Unit Test cho Controller POST /api/v1/distributions/{id}/cancel")
class DistributionControllerTest {

    @Mock
    private DistributionService distributionService;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private DistributionController distributionController;

    @Test
    @DisplayName("KCPM-103: Gọi POST /api/v1/distributions/{id}/cancel thành công -> Trả về HTTP 200 OK và CANCELLED")
    void testCancelDistribution_Success() {
        String distId = "DIST-001";
        CancelDistributionRequest request = new CancelDistributionRequest("Nước rút, đổi tuyến đường");

        Distribution cancelledDist = new Distribution();
        cancelledDist.setId(distId);
        cancelledDist.setStatus("CANCELLED");
        cancelledDist.setCancelReason("Nước rút, đổi tuyến đường");
        cancelledDist.setCancelledAt(LocalDateTime.now());
        cancelledDist.setCancelledBy("warehouse_manager");

        when(authentication.getName()).thenReturn("warehouse_manager");
        when(distributionService.cancelDistribution(distId, "Nước rút, đổi tuyến đường", "warehouse_manager"))
                .thenReturn(cancelledDist);

        ResponseEntity<Distribution> response = distributionController.cancelDistribution(
                distId, request, null, authentication
        );

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("CANCELLED", response.getBody().getStatus());
        assertEquals("Nước rút, đổi tuyến đường", response.getBody().getCancelReason());
        verify(distributionService, times(1))
                .cancelDistribution(distId, "Nước rút, đổi tuyến đường", "warehouse_manager");
    }

    @Test
    @DisplayName("KCPM-103: Gọi POST /api/v1/distributions/{id}/cancel không kèm body -> Dùng lý do mặc định và trả về 200 OK")
    void testCancelDistribution_WithoutBody_ShouldUseDefaultReason() {
        String distId = "DIST-002";

        Distribution cancelledDist = new Distribution();
        cancelledDist.setId(distId);
        cancelledDist.setStatus("CANCELLED");
        cancelledDist.setCancelReason("Hủy theo yêu cầu điều phối");

        when(authentication.getName()).thenReturn("admin");
        when(distributionService.cancelDistribution(distId, "Hủy theo yêu cầu điều phối", "admin"))
                .thenReturn(cancelledDist);

        ResponseEntity<Distribution> response = distributionController.cancelDistribution(
                distId, null, null, authentication
        );

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("CANCELLED", response.getBody().getStatus());
        verify(distributionService, times(1))
                .cancelDistribution(distId, "Hủy theo yêu cầu điều phối", "admin");
    }
}
