package vn.rescue.core.application.services;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import vn.rescue.core.application.dto.VehicleRequest;
import vn.rescue.core.application.dto.VehicleResponse;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;
import vn.rescue.core.presentation.exceptions.BadRequestException;
import vn.rescue.core.presentation.exceptions.ResourceNotFoundException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Đồng bộ với dữ liệu QA vehicles_management_data.csv (KCPM-96): TC_VEH_20, 22, 23, 24
 * và lỗi danh sách ẩn xe chưa gắn kho phát hiện qua E2E-04.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("Đồng bộ kiểm thử: Validate Đăng ký / Cập nhật / Danh sách phương tiện (VehiclesService)")
class VehiclesServiceValidationTest {

    @Mock private VehiclesRepository vehiclesRepository;
    @Mock private RescueRequestRepository rescueRequestRepository;
    @Mock private SystemManagementService systemManagementService;

    @InjectMocks private VehiclesService vehiclesService;

    private VehicleRequest req(String type, String plate, Integer capacity) {
        return VehicleRequest.builder().vehicleType(type).licensePlate(plate).capacity(capacity).currentLocation("Bến").build();
    }

    private Vehicles existing(String id, String type, String plate) {
        return Vehicles.builder().id(id).vehicleType(type).licensePlate(plate).status("AVAILABLE").build();
    }

    @Test
    @DisplayName("TC_VEH_20: Tạo xe với biển số để trống -> Ném 400 BadRequestException")
    void createWithBlankPlate_ShouldThrowBadRequest() {
        BadRequestException ex = assertThrows(BadRequestException.class, () -> vehiclesService.createVehicle(req("CANO", " ", 6), "admin"));
        assertEquals("Biển số xe không được để trống", ex.getMessage());
        verify(vehiclesRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_VEH_22: Cập nhật xe với ID không tồn tại -> Ném 404 ResourceNotFoundException (trước đây trả 500)")
    void updateNotExisting_ShouldThrowNotFound() {
        when(vehiclesRepository.findById("VEH-NOT-FOUND")).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> vehiclesService.updateVehicle("VEH-NOT-FOUND", req("CANO", "43A-888.88", 6), "admin"));
    }

    @Test
    @DisplayName("TC_VEH_23: Cập nhật sức chứa 25 (vượt biên 20) -> Ném 400 BadRequestException")
    void updateCapacityOverMax_ShouldThrowBadRequest() {
        when(vehiclesRepository.findById("VEH-001")).thenReturn(Optional.of(existing("VEH-001", "CANO", "43A-123.45")));
        assertThrows(BadRequestException.class, () -> vehiclesService.updateVehicle("VEH-001", req("CANO", "43A-123.45", 25), "admin"));
        verify(vehiclesRepository, never()).save(any());
    }

    @Test
    @DisplayName("TC_VEH_24: Cập nhật sang biển số đã thuộc xe khác -> Ném 400 BadRequestException")
    void updateToDuplicatePlate_ShouldThrowBadRequest() {
        when(vehiclesRepository.findById("VEH-001")).thenReturn(Optional.of(existing("VEH-001", "CANO", "43A-123.45")));
        when(vehiclesRepository.existsByLicensePlate("43A-999.99")).thenReturn(true);
        BadRequestException ex = assertThrows(BadRequestException.class, () -> vehiclesService.updateVehicle("VEH-001", req("CANO", "43A-999.99", 6), "admin"));
        assertTrue(ex.getMessage().contains("Biển số xe đã tồn tại"));
    }

    @Test
    @DisplayName("TC_VEH_21: Cập nhật giữ nguyên biển số của chính xe đó -> Không bị coi là trùng, cập nhật thành công")
    void updateKeepSamePlate_ShouldSucceed() {
        when(vehiclesRepository.findById("VEH-001")).thenReturn(Optional.of(existing("VEH-001", "CANO", "43A-123.45")));
        when(vehiclesRepository.save(any(Vehicles.class))).thenAnswer(inv -> inv.getArgument(0));

        VehicleResponse res = vehiclesService.updateVehicle("VEH-001", req("CANO", "43A-123.45", 10), "admin");

        assertEquals("43A-123.45", res.getLicensePlate());
        verify(vehiclesRepository, never()).existsByLicensePlate(any());
    }

    @Test
    @DisplayName("Cập nhật xe dữ liệu cũ có loại ngoài danh mục ('Xuồng máy') mà giữ nguyên loại -> Không bị chặn")
    void updateLegacyTypeUnchanged_ShouldSucceed() {
        when(vehiclesRepository.findById("VEH-OLD")).thenReturn(Optional.of(existing("VEH-OLD", "Xuồng máy", "43B-001")));
        when(vehiclesRepository.save(any(Vehicles.class))).thenAnswer(inv -> inv.getArgument(0));

        assertDoesNotThrow(() -> vehiclesService.updateVehicle("VEH-OLD", req("Xuồng máy", "43B-001", null), "admin"));
    }

    @Test
    @DisplayName("Danh sách xe không truyền warehouseId -> Không lọc theo kho (xe chưa gắn kho vẫn hiển thị)")
    void listWithoutWarehouseFilter_ShouldNotFilterByWarehouse() {
        PageRequest pageable = PageRequest.of(0, 10);
        Page<Vehicles> page = new PageImpl<>(List.of(existing("V-NO-WH", "CANO", "43C-001")));
        when(vehiclesRepository.findByVehicleTypeContainingIgnoreCaseAndStatusContainingIgnoreCase("", "", pageable)).thenReturn(page);

        Page<VehicleResponse> result = vehiclesService.getAllVehicles(null, null, null, pageable);

        assertEquals(1, result.getTotalElements());
        verify(vehiclesRepository, never()).findByVehicleTypeContainingIgnoreCaseAndStatusContainingIgnoreCaseAndWarehouseIdContainingIgnoreCase(any(), any(), any(), any());
    }
}
