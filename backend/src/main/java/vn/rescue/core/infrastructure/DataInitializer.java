package vn.rescue.core.infrastructure;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import vn.rescue.core.domain.entities.*;
import vn.rescue.core.domain.repositories.*;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final RescueRequestRepository rescueRequestRepository;
    private final RescueTeamRepository rescueTeamRepository;
    private final VehiclesRepository vehiclesRepository;
    private final WarehouseRepository warehouseRepository;
    private final ReliefItemRepository reliefItemRepository;
    private final InventoryRepository inventoryRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        log.info("Bắt đầu dọn dẹp và khởi tạo dữ liệu...");

        seedUsers();
        
        // Xóa sạch dữ liệu cũ để loại bỏ mock data theo yêu cầu
        log.info("Đang dọn dẹp các yêu cầu cứu hộ cũ (mock data)...");
        rescueRequestRepository.deleteAll();
        
        // seedRescueRequests();
        seedRescueTeamsAndVehicles();
        // seedWarehousesAndItems();
        // backfillRescueRequestIds();

        log.info("Hoàn tất quá trình dọn dẹp và khởi tạo.");
    }

    private void backfillRescueRequestIds() {
        log.info("Kiểm tra và cập nhật mã định danh (customId) cho các yêu cầu cũ...");
        List<RescueRequest> requests = rescueRequestRepository.findAll();
        long updatedCount = 0;

        for (RescueRequest request : requests) {
            if (request.getCustomId() == null) {
                // Generate ID based on existing count or order
                request.setCustomId(String.format("RES-%04d", updatedCount + 1));
                rescueRequestRepository.save(request);
                updatedCount++;
            }
        }

        if (updatedCount > 0) {
            log.info("Đã cập nhật mã định danh cho {} yêu cầu cũ.", updatedCount);
        }
    }

    private void seedUsers() {
        if (userRepository.count() == 0) {
            log.info("Nạp dữ liệu người dùng mẫu...");

            User admin = new User();
            admin.setEmail("admin@rescue.vn");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setFullName("Quản trị viên (Admin)");
            admin.setRoleId("ADMIN");
            admin.setCreatedAt(LocalDateTime.now());

            User coordinator = new User();
            coordinator.setEmail("coordinator@rescue.vn");
            coordinator.setPassword(passwordEncoder.encode("admin123"));
            coordinator.setFullName("Điều phối viên (Coordinator)");
            coordinator.setRoleId("COORDINATOR");
            coordinator.setCreatedAt(LocalDateTime.now());

            User staff = new User();
            staff.setEmail("staff@rescue.vn");
            staff.setPassword(passwordEncoder.encode("admin123"));
            staff.setFullName("Nhân viên cứu hộ (Staff)");
            staff.setRoleId("RESCUE_STAFF");
            staff.setCreatedAt(LocalDateTime.now());

            userRepository.saveAll(Arrays.asList(admin, coordinator, staff));
            log.info("Đã nạp 3 người dùng mẫu.");
        }
    }

    private void seedRescueRequests() {
        if (rescueRequestRepository.count() == 0) {
            log.info("Nạp dữ liệu yêu cầu cứu hộ mẫu...");

            RescueRequest r1 = createRequest("Nguyễn Văn A", "0905111222", 16.0678, 108.2208,
                    "123 Hùng Vương, Hải Châu, Đà Nẵng", "Nước dâng cao 1m, có người già cần di dời gấp", "HIGH", 4);
            RescueRequest r2 = createRequest("Trần Thị B", "0905333444", 16.0123, 108.1890,
                    "456 Cách Mạng Tháng 8, Cẩm Lệ, Đà Nẵng", "Nhà bị cô lập, thiếu lương thực", "MEDIUM", 2);
            RescueRequest r3 = createRequest("Lê Văn C", "0905555666", 16.0789, 108.1567,
                    "789 Tôn Đức Thắng, Liên Chiểu, Đà Nẵng", "Có 1 trẻ em đang sốt, nước ngập ngang bụng", "HIGH", 5);
            RescueRequest r4 = createRequest("Phạm Văn D", "0905777888", 16.0456, 108.2567,
                    "101 Võ Nguyên Giáp, Sơn Trà, Đà Nẵng", "Khu vực bị chia cắt, cần tiếp tế nhu yếu phẩm", "LOW", 3);
            RescueRequest r5 = createRequest("Hoàng Thị E", "0905999000", 15.9876, 108.2678,
                    "202 Lê Văn Hiến, Ngũ Hành Sơn, Đà Nẵng", "Nước đang lên nhanh, cần cứu hộ", "MEDIUM", 4);
            RescueRequest r6 = createRequest("Vũ Văn F", "0905112233", 16.0567, 108.1982,
                    "303 Điện Biên Phủ, Thanh Khê, Đà Nẵng", "Nhà cấp 4 có nguy cơ sập, nước ngập sâu", "HIGH", 3);

            rescueRequestRepository.saveAll(Arrays.asList(r1, r2, r3, r4, r5, r6));
            log.info("Đã nạp 6 yêu cầu cứu hộ mẫu.");
        }
    }

    private RescueRequest createRequest(String name, String phone, double lat, double lng, String address, String desc,
            String urgency, int people) {
        RescueRequest r = new RescueRequest();
        r.setCitizenName(name);
        r.setCitizenPhone(phone);
        r.setLocationLat(lat);
        r.setLocationLng(lng);
        r.setAddressText(address);
        r.setDescription(desc);
        r.setUrgencyLevel(urgency);
        r.setNumberOfPeople(people);
        r.setStatus("PENDING");
        r.setCreatedAt(LocalDateTime.now());
        return r;
    }

    private void seedRescueTeamsAndVehicles() {
        if (rescueTeamRepository.count() == 0) {
            log.info("Nạp dữ liệu đội cứu hộ và phương tiện mẫu...");

            RescueTeam t1 = new RescueTeam();
            t1.setTeamName("Đội Cứu Hộ 1");
            t1.setStatus("AVAILABLE");

            RescueTeam t2 = new RescueTeam();
            t2.setTeamName("Đội Cứu Hộ 2");
            t2.setStatus("AVAILABLE");

            RescueTeam t3 = new RescueTeam();
            t3.setTeamName("Đội Cứu Hộ 3");
            t3.setStatus("AVAILABLE");

            List<RescueTeam> teams = rescueTeamRepository.saveAll(Arrays.asList(t1, t2, t3));

            Vehicles v1 = createVehicle("Xuồng máy", "43A-001.23", teams.get(0).getId());
            Vehicles v2 = createVehicle("Xuồng máy", "43A-001.24", teams.get(1).getId());
            Vehicles v3 = createVehicle("Xe tải cứu trợ", "43B-005.67", teams.get(2).getId());
            Vehicles v4 = createVehicle("Xe bán tải", "43C-009.81", null);
            Vehicles v5 = createVehicle("Xe bán tải", "43C-009.82", null);

            vehiclesRepository.saveAll(Arrays.asList(v1, v2, v3, v4, v5));
            log.info("Đã nạp 3 đội và 5 phương tiện mẫu.");
        }
    }

    private Vehicles createVehicle(String type, String plate, String teamId) {
        Vehicles v = new Vehicles();
        v.setVehicleType(type);
        v.setLicensePlate(plate);
        v.setStatus("AVAILABLE");
        v.setTeamId(teamId);
        return v;
    }

    private void seedWarehousesAndItems() {
        if (warehouseRepository.count() == 0) {
            log.info("Nạp dữ liệu kho bãi và hàng hóa mẫu...");

            Warehouse w1 = new Warehouse();
            w1.setWarehouseName("Kho Hòa Xuân");
            w1.setLocation("Quận Cẩm Lệ, Đà Nẵng");
            w1.setStatus("ACTIVE");
            w1.setCreatedAt(LocalDateTime.now());

            Warehouse w2 = new Warehouse();
            w2.setWarehouseName("Kho Liên Chiểu");
            w2.setLocation("Quận Liên Chiểu, Đà Nẵng");
            w2.setStatus("ACTIVE");
            w2.setCreatedAt(LocalDateTime.now());

            List<Warehouse> warehouses = warehouseRepository.saveAll(Arrays.asList(w1, w2));

            ReliefItem i1 = createItem("Gạo", "kg", "Gạo tẻ trắng");
            ReliefItem i2 = createItem("Nước uống", "thùng", "Nước tinh khiết 500ml");
            ReliefItem i3 = createItem("Mì tôm", "thùng", "Mì hảo hảo");
            ReliefItem i4 = createItem("Áo phao", "chiếc", "Loại tiêu chuẩn cứu hộ");
            ReliefItem i5 = createItem("Thuốc men", "túi", "Sơ cứu cơ bản");

            List<ReliefItem> items = reliefItemRepository.saveAll(Arrays.asList(i1, i2, i3, i4, i5));

            // Populate Inventory
            for (Warehouse w : warehouses) {
                for (ReliefItem item : items) {
                    Inventory inv = new Inventory();
                    inv.setWarehouseId(w.getId());
                    inv.setItemId(item.getId());

                    if (item.getItemName().equals("Gạo"))
                        inv.setQuantity(5000);
                    else if (item.getItemName().equals("Nước uống"))
                        inv.setQuantity(1000);
                    else if (item.getItemName().equals("Mì tôm"))
                        inv.setQuantity(2000);
                    else if (item.getItemName().equals("Áo phao"))
                        inv.setQuantity(500);
                    else
                        inv.setQuantity(200);

                    inventoryRepository.save(inv);
                }
            }
            log.info("Đã nạp 2 kho, 5 loại hàng và nạp tồn kho mẫu.");
        }
    }

    private ReliefItem createItem(String name, String unit, String desc) {
        ReliefItem i = new ReliefItem();
        i.setItemName(name);
        i.setUnit(unit);
        i.setDescription(desc);
        return i;
    }
}
