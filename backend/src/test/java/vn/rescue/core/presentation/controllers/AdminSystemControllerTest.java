package vn.rescue.core.presentation.controllers;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import vn.rescue.core.application.dto.DashboardStatsResponse;
import vn.rescue.core.application.dto.InventoryResponse;
import vn.rescue.core.application.services.ReportService;
import vn.rescue.core.application.services.SystemManagementService;
import vn.rescue.core.domain.entities.SystemConfig;
import vn.rescue.core.domain.entities.SystemLog;
import vn.rescue.core.presentation.common.ApiResponse;
import vn.rescue.core.presentation.exceptions.BadRequestException;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("KCPM-107: Unit Test cho Module Cấu hình & Dashboard (AdminSystemController)")
class AdminSystemControllerTest {

    @Mock
    private SystemManagementService systemManagementService;

    @Mock
    private ReportService reportService;

    @InjectMocks
    private AdminSystemController adminSystemController;

    // =========================================================================
    // 1. KIỂM THỬ LẤY NHẬT KÝ HỆ THỐNG (GET /logs)
    // =========================================================================

    @Test
    @DisplayName("TC_SYS_01: Lấy danh sách nhật ký thành công -> Trả về HTTP 200 OK và danh sách SystemLog")
    void testGetAllLogs_Success() {
        SystemLog log1 = SystemLog.builder()
                .id("LOG_01")
                .userId("admin_01")
                .action("CREATE_USER")
                .module("AUTH")
                .details("Tạo tài khoản cán bộ cứu hộ")
                .createdAt(LocalDateTime.now())
                .build();

        SystemLog log2 = SystemLog.builder()
                .id("LOG_02")
                .userId("admin_01")
                .action("UPDATE_CONFIG")
                .module("SYSTEM")
                .details("Cập nhật tham số hệ thống")
                .createdAt(LocalDateTime.now())
                .build();

        when(systemManagementService.getAllLogs()).thenReturn(List.of(log1, log2));

        ResponseEntity<ApiResponse<List<SystemLog>>> response = adminSystemController.getLogs();

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(2, response.getBody().getData().size());
        assertEquals("System logs retrieved successfully", response.getBody().getMessage());
        verify(systemManagementService, times(1)).getAllLogs();
    }

    @Test
    @DisplayName("TC_SYS_02: Lấy nhật ký khi chưa có dữ liệu -> Trả về HTTP 200 OK và danh sách rỗng")
    void testGetAllLogs_WhenEmpty_ShouldReturnEmptyList() {
        when(systemManagementService.getAllLogs()).thenReturn(Collections.emptyList());

        ResponseEntity<ApiResponse<List<SystemLog>>> response = adminSystemController.getLogs();

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().getData().isEmpty());
        verify(systemManagementService, times(1)).getAllLogs();
    }

    // =========================================================================
    // 2. KIỂM THỬ THỐNG KÊ DASHBOARD THEO KHO (GET /dashboard/{warehouseId})
    // =========================================================================

    @Test
    @DisplayName("TC_SYS_03: Lấy số liệu dashboard theo kho hợp lệ -> Trả về HTTP 200 OK và DashboardStatsResponse")
    void testGetDashboardStats_ValidWarehouseId_Success() {
        String warehouseId = "WH-01";

        InventoryResponse lowStockItem = InventoryResponse.builder()
                .itemId("ITEM-01")
                .itemName("Mì tôm Hảo Hảo")
                .quantity(10)
                .unit("Thùng")
                .minThreshold(50)
                .status("LOW_STOCK")
                .build();

        DashboardStatsResponse expectedStats = DashboardStatsResponse.builder()
                .totalVehicles(5L)
                .availableVehicles(3L)
                .lowStockItems(List.of(lowStockItem))
                .build();

        when(systemManagementService.getDashboardStats(warehouseId)).thenReturn(expectedStats);

        ResponseEntity<ApiResponse<DashboardStatsResponse>> response =
                adminSystemController.getDashboardStats(warehouseId);

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(5L, response.getBody().getData().getTotalVehicles());
        assertEquals(3L, response.getBody().getData().getAvailableVehicles());
        assertEquals(1, response.getBody().getData().getLowStockItems().size());
        assertEquals("Dashboard statistics retrieved", response.getBody().getMessage());
        verify(systemManagementService, times(1)).getDashboardStats(warehouseId);
    }

    @Test
    @DisplayName("TC_SYS_04: Lấy dashboard với mã kho rỗng (chuỗi trắng) -> Ném BadRequestException (400)")
    void testGetDashboardStats_BlankWarehouseId_ShouldThrowBadRequest() {
        String blankWarehouseId = "   ";

        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            adminSystemController.getDashboardStats(blankWarehouseId);
        });

        assertTrue(exception.getMessage().contains("Mã kho (warehouseId) không được để trống"));
        verify(systemManagementService, never()).getDashboardStats(anyString());
    }

    @Test
    @DisplayName("TC_SYS_05: Lấy dashboard với mã kho null -> Ném BadRequestException (400)")
    void testGetDashboardStats_NullWarehouseId_ShouldThrowBadRequest() {
        BadRequestException exception = assertThrows(BadRequestException.class, () -> {
            adminSystemController.getDashboardStats(null);
        });

        assertTrue(exception.getMessage().contains("Mã kho (warehouseId) không được để trống"));
        verify(systemManagementService, never()).getDashboardStats(any());
    }

    // =========================================================================
    // 3. KIỂM THỬ CẤU HÌNH HỆ THỐNG (GET & PUT /config)
    // =========================================================================

    @Test
    @DisplayName("TC_SYS_06: Lấy toàn bộ cấu hình hệ thống -> Trả về HTTP 200 OK và danh sách cấu hình")
    void testGetAllConfigs_Success() {
        SystemConfig config1 = SystemConfig.builder().key("ALERT").value("ON").build();
        SystemConfig config2 = SystemConfig.builder().key("MAX_RESCUE_RADIUS").value("5000").build();

        when(systemManagementService.getAllConfigs()).thenReturn(List.of(config1, config2));

        ResponseEntity<ApiResponse<List<SystemConfig>>> response = adminSystemController.getAllConfigs();

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals(2, response.getBody().getData().size());
        assertEquals("All system configurations retrieved", response.getBody().getMessage());
        verify(systemManagementService, times(1)).getAllConfigs();
    }

    @Test
    @DisplayName("TC_SYS_07: Cập nhật cấu hình với tham số hợp lệ -> Trả về HTTP 200 OK và ghi log thành công")
    void testUpdateConfig_ValidParams_Success() {
        String key = "ALERT";
        String value = "ON";
        String adminId = "ADMIN_01";

        SystemConfig updatedConfig = SystemConfig.builder().key(key).value(value).build();

        when(systemManagementService.updateConfig(key, value)).thenReturn(updatedConfig);

        ResponseEntity<ApiResponse<SystemConfig>> response =
                adminSystemController.updateConfig(key, value, adminId);

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("ALERT", response.getBody().getData().getKey());
        assertEquals("ON", response.getBody().getData().getValue());
        assertEquals("System configuration updated", response.getBody().getMessage());

        verify(systemManagementService, times(1)).updateConfig(key, value);
        verify(systemManagementService, times(1))
                .logAction(adminId, "UPDATE_CONFIG", "Config ALERT updated to ON", "SYSTEM");
    }

    @Test
    @DisplayName("TC_SYS_08: Cập nhật cấu hình khi thiếu hoặc rỗng key -> Ném BadRequestException (400)")
    void testUpdateConfig_MissingOrBlankKey_ShouldThrowBadRequest() {
        BadRequestException exNull = assertThrows(BadRequestException.class, () -> {
            adminSystemController.updateConfig(null, "ON", "ADMIN_01");
        });
        assertTrue(exNull.getMessage().contains("Khóa cấu hình (key) không được để trống"));

        BadRequestException exBlank = assertThrows(BadRequestException.class, () -> {
            adminSystemController.updateConfig("   ", "ON", "ADMIN_01");
        });
        assertTrue(exBlank.getMessage().contains("Khóa cấu hình (key) không được để trống"));

        verify(systemManagementService, never()).updateConfig(any(), any());
        verify(systemManagementService, never()).logAction(any(), any(), any(), any());
    }

    @Test
    @DisplayName("TC_SYS_09: Cập nhật cấu hình khi thiếu hoặc rỗng adminId -> Ném BadRequestException (400)")
    void testUpdateConfig_MissingOrBlankAdminId_ShouldThrowBadRequest() {
        BadRequestException exNull = assertThrows(BadRequestException.class, () -> {
            adminSystemController.updateConfig("ALERT", "ON", null);
        });
        assertTrue(exNull.getMessage().contains("Mã quản trị viên (adminId) không được để trống"));

        BadRequestException exBlank = assertThrows(BadRequestException.class, () -> {
            adminSystemController.updateConfig("ALERT", "ON", "  ");
        });
        assertTrue(exBlank.getMessage().contains("Mã quản trị viên (adminId) không được để trống"));

        verify(systemManagementService, never()).updateConfig(any(), any());
        verify(systemManagementService, never()).logAction(any(), any(), any(), any());
    }

    // =========================================================================
    // 4. KIỂM THỬ BÁO CÁO TỔNG QUAN & PHÂN TÍCH (GET /reports/general & /analytics)
    // =========================================================================

    @Test
    @DisplayName("TC_SYS_10: Lấy báo cáo tổng hợp chung -> Trả về HTTP 200 OK và Object thống kê")
    void testGetGeneralReports_Success() {
        Map<String, Object> mockStats = Map.of(
                "totalUsers", 10,
                "totalRequests", 25,
                "totalTeams", 4
        );

        when(reportService.getGeneralStats()).thenReturn(mockStats);

        ResponseEntity<ApiResponse<Object>> response = adminSystemController.getGeneralReports();

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("General reports retrieved", response.getBody().getMessage());
        assertEquals(mockStats, response.getBody().getData());
        verify(reportService, times(1)).getGeneralStats();
    }

    @Test
    @DisplayName("TC_SYS_11: Lấy phân tích chuyên sâu hệ thống -> Trả về HTTP 200 OK và Map phân tích KPIs")
    void testGetDetailedAnalytics_Success() {
        Map<String, Object> mockAnalytics = Map.of(
                "totalRequests", 50,
                "totalPeopleRescued", 120,
                "statusDistribution", Map.of("COMPLETED", 40, "IN_PROGRESS", 10)
        );

        when(reportService.getDetailedAnalytics()).thenReturn(mockAnalytics);

        ResponseEntity<ApiResponse<Map<String, Object>>> response = adminSystemController.getDetailedAnalytics();

        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isSuccess());
        assertEquals("Detailed analytics retrieved", response.getBody().getMessage());
        assertEquals(mockAnalytics, response.getBody().getData());
        verify(reportService, times(1)).getDetailedAnalytics();
    }
}
