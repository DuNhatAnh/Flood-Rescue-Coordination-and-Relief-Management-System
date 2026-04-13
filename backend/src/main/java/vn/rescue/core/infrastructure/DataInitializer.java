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
@SuppressWarnings({ "null", "unused" })
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final RescueRequestRepository rescueRequestRepository;
    private final RescueTeamRepository rescueTeamRepository;
    private final VehiclesRepository vehiclesRepository;
    private final WarehouseRepository warehouseRepository;
    private final ReliefItemRepository reliefItemRepository;
    private final InventoryRepository inventoryRepository;
    private final AssignmentRepository assignmentRepository;
    private final RoleRepository roleRepository;
    private final DangerPointRepository dangerPointRepository;
    private final SystemConfigRepository systemConfigRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        log.info("Bắt đầu dọn dẹp và khởi tạo dữ liệu...");

        seedRoles();
        seedUsers();

        seedRescueRequests();
        seedWarehousesAndItems();
        seedRescueTeamsAndVehicles();
        seedDangerPoints();
        seedSystemConfigs();
        
        backfillRescueRequestIds();
        seedAssignments();

        log.info("Hoàn tất quá trình dọn dẹp và khởi tạo.");
    }

    private void seedRoles() {
        if (roleRepository.count() == 0) {
            log.info("Nạp dữ liệu vai trò mẫu...");

            Role admin = Role.builder()
                    .id("ADMIN")
                    .name("ADMIN")
                    .description("Administrator with full access")
                    .permissions(Arrays.asList("ALL"))
                    .build();

            Role coordinator = Role.builder()
                    .id("COORDINATOR")
                    .name("COORDINATOR")
                    .description("Coordinator for rescue operations")
                    .permissions(Arrays.asList("COORDINATE"))
                    .build();

            Role staff = Role.builder()
                    .id("RESCUE_STAFF")
                    .name("RESCUE_STAFF")
                    .description("Rescue staff member")
                    .permissions(Arrays.asList("RESCUE"))
                    .build();

            Role user = Role.builder()
                    .id("USER")
                    .name("USER")
                    .description("Regular user")
                    .permissions(Arrays.asList("REPORT"))
                    .build();

            roleRepository.saveAll(Arrays.asList(admin, coordinator, staff, user));
            log.info("Đã nạp 4 vai trò mẫu.");
        }
    }

    private void backfillRescueRequestIds() {
        log.info("Kiểm tra và cập nhật mã định danh (customId) cho các yêu cầu cũ...");
        List<RescueRequest> requests = rescueRequestRepository.findAll();
        long updatedCount = 0;

        for (RescueRequest request : requests) {
            if (request.getCustomId() == null) {
                // Generate ID based on existing count or order
                request.setCustomId(String.format("%04d", updatedCount + 1));
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

            User staff2 = new User();
            staff2.setEmail("staff2@rescue.vn");
            staff2.setPassword(passwordEncoder.encode("admin123"));
            staff2.setFullName("Nhân viên cứu hộ 2 (Staff 2)");
            staff2.setRoleId("RESCUE_STAFF");
            staff2.setCreatedAt(LocalDateTime.now());

            User staff3 = new User();
            staff3.setEmail("staff3@rescue.vn");
            staff3.setPassword(passwordEncoder.encode("admin123"));
            staff3.setFullName("Nhân viên cứu hộ 3 (Staff 3)");
            staff3.setRoleId("RESCUE_STAFF");
            staff3.setCreatedAt(LocalDateTime.now());

            userRepository.saveAll(Arrays.asList(admin, coordinator, staff, staff2, staff3));
            log.info("Đã nạp 5 người dùng mẫu.");
        }

        // Ensure all default users have correct password for testing
        updateOrCreateUser("admin@rescue.vn", "Quản trị viên (Admin)", "ADMIN");
        updateOrCreateUser("coordinator@rescue.vn", "Điều phối viên (Coordinator)", "COORDINATOR");
        updateOrCreateUser("staff@rescue.vn", "Nhân viên cứu hộ (Staff)", "RESCUE_STAFF");
        updateOrCreateUser("staff2@rescue.vn", "Nhân viên cứu hộ 2 (Staff 2)", "RESCUE_STAFF");
        updateOrCreateUser("staff3@rescue.vn", "Nhân viên cứu hộ 3 (Staff 3)", "RESCUE_STAFF");
    }

    private void updateOrCreateUser(String email, String fullName, String roleId) {
        userRepository.findByEmail(email).ifPresentOrElse(user -> {
            user.setPassword(passwordEncoder.encode("admin123"));
            user.setFullName(fullName);
            user.setRoleId(roleId);
            userRepository.save(user);
            log.info("Đã cập nhật tài khoản {} với mật khẩu admin123", email);
        }, () -> {
            User user = new User();
            user.setEmail(email);
            user.setPassword(passwordEncoder.encode("admin123"));
            user.setFullName(fullName);
            user.setRoleId(roleId);
            user.setCreatedAt(LocalDateTime.now());
            userRepository.save(user);
            log.info("Đã tạo mới tài khoản {} với mật khẩu admin123", email);
        });
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

            List<Warehouse> warehouses = warehouseRepository.findAll();
            if (warehouses.isEmpty()) {
                log.warn("Không tìm thấy kho hàng để gán cho đội cứu hộ!");
                return;
            }

            Warehouse w1 = warehouses.get(0);
            Warehouse w2 = warehouses.size() > 1 ? warehouses.get(1) : w1;
            Warehouse w3 = warehouses.size() > 2 ? warehouses.get(2) : w2;

            RescueTeam t1 = new RescueTeam();
            t1.setTeamName("Đội Cứu Hộ 1");
            t1.setStatus("AVAILABLE");
            t1.setWarehouseId(w1.getId());

            // Link to the seeded staff account
            userRepository.findByEmail("staff@rescue.vn").ifPresent(staff -> {
                t1.setLeaderId(staff.getId());
                log.info("Đã gán staff@rescue.vn làm trưởng Đội Cứu Hộ 1");
            });

            RescueTeam t2 = new RescueTeam();
            t2.setTeamName("Đội Cứu Hộ 2");
            t2.setStatus("AVAILABLE");
            t2.setWarehouseId(w2.getId());
            userRepository.findByEmail("staff2@rescue.vn").ifPresent(staff -> {
                t2.setLeaderId(staff.getId());
                log.info("Đã gán staff2@rescue.vn làm trưởng Đội Cứu Hộ 2");
            });

            RescueTeam t3 = new RescueTeam();
            t3.setTeamName("Đội Cứu Hộ 3");
            t3.setStatus("AVAILABLE");
            t3.setWarehouseId(w3.getId());
            userRepository.findByEmail("staff3@rescue.vn").ifPresent(staff -> {
                t3.setLeaderId(staff.getId());
                log.info("Đã gán staff3@rescue.vn làm trưởng Đội Cứu Hộ 3");
            });

            List<RescueTeam> teams = rescueTeamRepository.saveAll(Arrays.asList(t1, t2, t3));

            Vehicles v1 = createVehicle("Xuồng máy", "43A-001.23", teams.get(0).getId(), w1.getId());
            Vehicles v2 = createVehicle("Xuồng máy", "43A-001.24", teams.get(1).getId(), w2.getId());
            Vehicles v3 = createVehicle("Xe tải cứu trợ", "43B-005.67", teams.get(2).getId(), w3.getId());
            Vehicles v4 = createVehicle("Xe bán tải", "43C-009.81", null, w1.getId());
            Vehicles v5 = createVehicle("Xe bán tải", "43C-009.82", null, w2.getId());

            vehiclesRepository.saveAll(Arrays.asList(v1, v2, v3, v4, v5));
            log.info("Đã nạp 3 đội và 5 phương tiện mẫu với liên kết kho.");
        }
    }

    private Vehicles createVehicle(String type, String plate, String teamId, String warehouseId) {
        Vehicles v = new Vehicles();
        v.setVehicleType(type);
        v.setLicensePlate(plate);
        v.setStatus("AVAILABLE");
        v.setTeamId(teamId);
        v.setWarehouseId(warehouseId);
        return v;
    }

    private void seedWarehousesAndItems() {
        if (warehouseRepository.count() == 0) {
            log.info("Nạp dữ liệu kho bãi và hàng hóa mẫu...");

            Warehouse w1 = new Warehouse();
            w1.setWarehouseName("Kho Hòa Xuân");
            w1.setLocation("Quận Cẩm Lệ, Đà Nẵng");

            // Assign staff@rescue.vn as manager
            userRepository.findByEmail("staff@rescue.vn").ifPresent(staff -> {
                w1.setManagerId(staff.getId());
            });

            w1.setStatus("ACTIVE");
            w1.setCreatedAt(LocalDateTime.now());

            Warehouse w2 = new Warehouse();
            w2.setWarehouseName("Kho Liên Chiểu");
            w2.setLocation("Quận Liên Chiểu, Đà Nẵng");

            // Assign staff2@rescue.vn as manager
            userRepository.findByEmail("staff2@rescue.vn").ifPresent(staff -> {
                w2.setManagerId(staff.getId());
            });

            w2.setStatus("ACTIVE");
            w2.setCreatedAt(LocalDateTime.now());

            Warehouse w3 = new Warehouse();
            w3.setWarehouseName("Kho Cẩm Lệ");
            w3.setLocation("Quận Cẩm Lệ, Đà Nẵng");

            // Assign staff3@rescue.vn as manager
            userRepository.findByEmail("staff3@rescue.vn").ifPresent(staff -> {
                w3.setManagerId(staff.getId());
            });

            w3.setStatus("ACTIVE");
            w3.setCreatedAt(LocalDateTime.now());

            List<Warehouse> warehouses = warehouseRepository.saveAll(Arrays.asList(w1, w2, w3));

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
                    inv.setItemName(item.getItemName());
                    inv.setUnit(item.getUnit());

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

                    inv.setMinThreshold(100); // Đặt ngưỡng mặc định để tránh NPE
                    inventoryRepository.save(inv);
                }
            }
            log.info("Đã nạp 2 kho, 5 loại hàng và nạp tồn kho mẫu.");
        }
    }

    private void seedAssignments() {
        if (assignmentRepository.count() == 0) {
            log.info("Nạp dữ liệu Nhiệm vụ mẫu cho staff@rescue.vn...");
            
            userRepository.findByEmail("staff@rescue.vn").ifPresent(staff -> {
                String teamId = staff.getTeamId();
                if (teamId != null) {
                    // Tìm 1 request đã VERIFIED để gán
                    rescueRequestRepository.findAll().stream()
                        .filter(r -> "VERIFIED".equalsIgnoreCase(r.getStatus()) || "PENDING".equalsIgnoreCase(r.getStatus()))
                        .findFirst()
                        .ifPresent(request -> {
                            Assignment assignment = new Assignment();
                            assignment.setRequestId(request.getId());
                            assignment.setTeamId(teamId);
                            assignment.setStatus("PREPARING");
                            assignment.setAssignedAt(LocalDateTime.now());
                            assignment.setAssignedBy("Coordinator Admin");
                            
                            // Gán xe mẫu (lấy xe đầu tiên của đội)
                            vehiclesRepository.findByTeamId(teamId).stream().findFirst().ifPresent(v -> {
                                assignment.setVehicleIds(Arrays.asList(v.getId()));
                                v.setStatus("BUSY");
                                vehiclesRepository.save(v);
                            });

                            // Gán hàng hóa yêu cầu (Assigned Items)
                            List<MissionItem> assigned = new java.util.ArrayList<>();
                            
                            reliefItemRepository.findAll().forEach(item -> {
                                if (item.getItemName().contains("Gạo")) {
                                    assigned.add(new MissionItem(item.getId(), item.getItemName(), item.getUnit(), 20));
                                }
                                if (item.getItemName().contains("Nước")) {
                                    assigned.add(new MissionItem(item.getId(), item.getItemName(), item.getUnit(), 10));
                                }
                                if (item.getItemName().contains("Mì")) {
                                    assigned.add(new MissionItem(item.getId(), item.getItemName(), item.getUnit(), 5));
                                }
                            });
                            
                            assignment.setAssignedItems(assigned);
                            assignmentRepository.save(assignment);
                            
                            request.setStatus("ASSIGNED");
                            request.setTeamId(teamId);
                            rescueRequestRepository.save(request);
                            
                            log.info("Đã tạo nhiệm vụ mẫu trạng thái PREPARING cho staff@rescue.vn");
                        });
                }
            });
        }
    }

    private void seedDangerPoints() {
        if (dangerPointRepository.count() == 0) {
            log.info("Nạp dữ liệu điểm nguy hiểm mẫu tại Quảng Nam...");

            DangerPoint d1 = DangerPoint.builder()
                    .name("Khu vực ngập sâu Phú Ninh")
                    .address("Phú Ninh, Quảng Nam")
                    .latitude(15.4745)
                    .longitude(108.4321)
                    .depth(3.5)
                    .createdAt(LocalDateTime.now())
                    .build();

            DangerPoint d2 = DangerPoint.builder()
                    .name("Ngã tư trung tâm Tam Kỳ")
                    .address("Phường An Xuân, Tam Kỳ, Quảng Nam")
                    .latitude(15.5654)
                    .longitude(108.5212)
                    .depth(1.2)
                    .createdAt(LocalDateTime.now())
                    .build();

            DangerPoint d3 = DangerPoint.builder()
                    .name("Vùng thấp trũng Núi Thành")
                    .address("Núi Thành, Quảng Nam")
                    .latitude(15.4321)
                    .longitude(108.6456)
                    .depth(0.4)
                    .createdAt(LocalDateTime.now())
                    .build();

            dangerPointRepository.saveAll(Arrays.asList(d1, d2, d3));
            log.info("Đã nạp 3 điểm nguy hiểm vùng Quảng Nam.");
        }
    }

    private void seedSystemConfigs() {
        if (systemConfigRepository.count() == 0) {
            log.info("Nạp cấu hình hệ thống mặc định...");
            
            SystemConfig c1 = SystemConfig.builder().key("MAP_CENTER_LAT").value("15.5654").build();
            SystemConfig c2 = SystemConfig.builder().key("MAP_CENTER_LNG").value("108.5212").build();
            SystemConfig c3 = SystemConfig.builder().key("MAP_DEFAULT_ZOOM").value("11.0").build();
            SystemConfig c4 = SystemConfig.builder().key("HOTLINE_NUMBER").value("086.777.9427").build();
            SystemConfig c5 = SystemConfig.builder().key("SUPPORT_EMAIL").value("support@rescue.vn").build();
            SystemConfig c6 = SystemConfig.builder().key("MAINTENANCE_MODE").value("false").build();
            
            systemConfigRepository.saveAll(Arrays.asList(c1, c2, c3, c4, c5, c6));
            log.info("Đã nạp 6 cấu hình hệ thống mặc định.");
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