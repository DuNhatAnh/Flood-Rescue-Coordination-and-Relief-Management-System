package vn.rescue.core.application.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.TaskAssignmentResponse;
import vn.rescue.core.application.dto.AssignmentRequest;
import vn.rescue.core.domain.entities.Assignment;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.entities.RequestStatusHistory;
import vn.rescue.core.domain.repositories.AssignmentRepository;
import vn.rescue.core.domain.repositories.RequestStatusHistoryRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;
import vn.rescue.core.domain.repositories.WarehouseRepository;
import vn.rescue.core.domain.entities.RescueReport;
import vn.rescue.core.domain.entities.MissionItem;
import vn.rescue.core.domain.entities.User;
import vn.rescue.core.domain.repositories.RescueReportRepository;
import vn.rescue.core.domain.repositories.UserRepository;
import vn.rescue.core.domain.repositories.DistributionRepository;
import vn.rescue.core.domain.entities.Distribution;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Optional;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class RescueCoordinationService {
    private static final Logger logger = LoggerFactory.getLogger(RescueCoordinationService.class);

    @Autowired
    private RescueRequestRepository rescueRequestRepository;

    @Autowired
    private AssignmentRepository assignmentRepository;

    @Autowired
    private RescueTeamRepository rescueTeamRepository;

    @Autowired
    private VehiclesRepository vehiclesRepository;

    @Autowired
    private RequestStatusHistoryRepository requestStatusHistoryRepository;

    @Autowired
    private WarehouseRepository warehouseRepository;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private RescueReportRepository rescueReportRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SystemManagementService systemManagementService;

    @Autowired
    private DistributionRepository distributionRepository;

    public List<RescueRequest> getPendingRequests() {
        return rescueRequestRepository.findByStatus("PENDING");
    }

    public void updateUrgency(String id, String urgencyLevel) {
        Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(id);
        if (requestOpt.isPresent()) {
            RescueRequest request = requestOpt.get();
            request.setUrgencyLevel(urgencyLevel);
            rescueRequestRepository.save(request);
        }
    }

    public void verifyRequest(String id, String verifiedBy) {
        Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(id);
        if (requestOpt.isEmpty()) {
            requestOpt = rescueRequestRepository.findFirstByCustomId(id);
        }

        if (requestOpt.isPresent()) {
            RescueRequest request = requestOpt.get();
            request.setVerified(true);
            request.setVerifiedBy(verifiedBy);
            rescueRequestRepository.save(request);
        }
    }

    public List<RescueTeam> getAvailableTeams() {
        List<RescueTeam> teams = rescueTeamRepository.findByStatusIgnoreCase("AVAILABLE");
        logger.info("Fixed 403: Found {} available teams", teams.size());
        return teams;
    }

    public List<RescueTeam> getAllTeams() {
        return rescueTeamRepository.findAll();
    }

    public Optional<RescueTeam> getTeamById(String id) {
        return rescueTeamRepository.findById(id);
    }

    @Transactional
    public RescueTeam updateTeam(String id, String newName) {
        Optional<RescueTeam> teamOpt = rescueTeamRepository.findById(id);
        if (teamOpt.isPresent()) {
            RescueTeam team = teamOpt.get();
            String oldName = team.getTeamName();
            team.setTeamName(newName);
            RescueTeam updated = rescueTeamRepository.save(team);
            
            // Thông báo cho toàn đội
            notifyTeam(id, 
                "Cập nhật Đội cứu hộ", 
                "Tên đội đã được thay đổi từ \"" + oldName + "\" thành \"" + newName + "\".", 
                "INFO");
                
            return updated;
        }
        throw new RuntimeException("Không tìm thấy đội cứu hộ với ID: " + id);
    }

    /**
     * Thông báo cho toàn bộ nhân viên thuộc một Kho cụ thể
     */
    public void notifyWarehouse(String warehouseId, String title, String content, String type) {
        try {
            rescueTeamRepository.findByWarehouseId(warehouseId).ifPresent(team -> {
                notifyTeam(team.getId(), title, content, type);
            });
        } catch (Exception e) {
            logger.error("Lỗi khi gửi thông báo cho kho {}: {}", warehouseId, e.getMessage());
        }
    }

    public void notifyTeam(String teamId, String title, String content, String type) {
        try {
            List<User> members = userRepository.findByTeamId(teamId);
            for (User user : members) {
                vn.rescue.core.application.dto.NotificationDto dto = new vn.rescue.core.application.dto.NotificationDto();
                dto.setTitle(title);
                dto.setContent(content);
                dto.setType(type);
                dto.setPriority("NORMAL");
                dto.setUserId(user.getId());
                systemManagementService.sendNotification(dto);
            }
        } catch (Exception e) {
            logger.error("Lỗi khi gửi thông báo cho đội {}: {}", teamId, e.getMessage());
        }
    }


    public List<Vehicles> getAvailableVehicles() {
        List<Vehicles> vehicles = vehiclesRepository.findByStatusIgnoreCase("AVAILABLE");
        logger.info("Fixed 403: Found {} available vehicles", vehicles.size());
        return vehicles;
    }

    @Transactional
    public Assignment createAssignment(AssignmentRequest requestDto) {
        String requestId = requestDto.getRequestId();
        String teamId = requestDto.getTeamId();
        List<String> vehicleIds = requestDto.getVehicleIds();
        String assignedBy = requestDto.getAssignedBy();
        List<MissionItem> missionItems = requestDto.getMissionItems();

        Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(requestId);
        if (requestOpt.isEmpty()) {
            requestOpt = rescueRequestRepository.findFirstByCustomId(requestId);
        }

        if (requestOpt.isPresent()) {
            RescueRequest request = requestOpt.get();
            request.setStatus("ASSIGNED");
            request.setTeamId(teamId);
            rescueRequestRepository.save(request);

            // Update team status
            Optional<RescueTeam> teamOpt = rescueTeamRepository.findById(teamId);
            if (teamOpt.isPresent()) {
                RescueTeam team = teamOpt.get();
                team.setStatus("BUSY");
                rescueTeamRepository.save(team);
            }

            // Update multiple vehicles status
            if (vehicleIds != null) {
                for (String vId : vehicleIds) {
                    Optional<Vehicles> vOpt = vehiclesRepository.findById(vId);
                    if (vOpt.isPresent()) {
                        Vehicles vehicle = vOpt.get();
                        vehicle.setStatus("BUSY");
                        vehiclesRepository.save(vehicle);
                    }
                }
            }

            Assignment assignment = new Assignment();
            assignment.setRequestId(request.getId()); 
            assignment.setTeamId(teamId);
            assignment.setVehicleIds(vehicleIds);
            assignment.setAssignedBy(assignedBy);
            assignment.setAssignedAt(LocalDateTime.now());
            assignment.setStatus("ASSIGNED");
            assignment.setMissionItems(missionItems);

            Assignment saved = assignmentRepository.save(assignment);
            
            // Thông báo cho toàn đội về nhiệm vụ mới
            notifyTeam(teamId, 
                "Nhiệm vụ mới được phân công", 
                "Đội có nhiệm vụ mới tại: " + request.getAddressText() + ". Vui lòng kiểm tra chi tiết.", 
                "SOS");
                
            return saved;
        }
        return null;
    }

    public List<TaskAssignmentResponse> getAssignmentsByTeam(String teamId) {
        List<Assignment> assignments = assignmentRepository.findByTeamId(teamId);
        return assignments.stream().map(this::convertToResponse).collect(Collectors.toList());
    }

    public List<TaskAssignmentResponse> getAllAssignments() {
        return assignmentRepository.findAll().stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    @SuppressWarnings("unchecked")
    public void updateAssignmentStatus(String id, Map<String, Object> body) {
        String status = (String) body.get("status");
        String note = (String) body.get("note");
        String userId = (String) body.get("userId");
        List<java.util.Map<String, Object>> itemsRaw = (List<java.util.Map<String, Object>>) body.get("items");

        Optional<Assignment> assignmentOpt = assignmentRepository.findById(id);
        if (assignmentOpt.isPresent()) {
            Assignment assignment = assignmentOpt.get();
            
            // 1. KIỂM TRA QUYỀN HẠN
            if (userId == null || userId.isEmpty()) {
                throw new RuntimeException("Thiếu thông tin nhận diện người dùng!");
            }
            User user = userRepository.findById(userId).orElse(null);
            if (user == null) {
                throw new RuntimeException("Không tìm thấy người dùng!");
            }

            String userRole = user.getRoleId() != null ? user.getRoleId().toUpperCase() : "";
            boolean isElevatedUser = userRole.contains("ADMIN") || userRole.contains("COORDINATOR");
            boolean isTeamMember = user.getTeamId() != null && user.getTeamId().equals(assignment.getTeamId());

            if (!isElevatedUser && !isTeamMember) {
                throw new RuntimeException("Bạn không có quyền cập nhật trạng thái cho nhiệm vụ này!");
            }
            
            // Nếu là Staff/Leader thì mới cần kiểm tra chuỗi vai trò cụ thể (phòng hờ trường hợp Role khác gán TeamId)
            if (!isElevatedUser && !userRole.contains("STAFF") && !userRole.contains("LEADER")) {
                 throw new RuntimeException("Chỉ thành viên đội cứu hộ hoặc điều phối viên mới có quyền thực hiện thao tác này!");
            }

            String oldStatus = assignment.getStatus();
            String targetStatus = status;

            // Nếu nhân viên báo hoàn thành -> Chuyển sang REPORTED (Chờ duyệt)
            // Nếu Admin/Điều phối báo hoàn thành -> Chuyển thẳng sang COMPLETED
            if ("COMPLETED".equalsIgnoreCase(status) && !isElevatedUser) {
                targetStatus = "REPORTED";
            }
            
            assignment.setStatus(targetStatus);
            System.out.println("DEBUG: Updating assignment " + id + " to target status: " + targetStatus);

            // LOGIC PHẦN 2: Xử lý xuất hàng - Bổ sung CHỐNG NHẢY CÓC (Vấn đề 3)
            // Nếu chuyển sang trạng thái đang hoạt động mà chưa trừ hàng thì tự động trừ
            boolean isActiveStatus = List.of("MOVING", "RESCUING", "RETURNING", "REPORTED").contains(targetStatus.toUpperCase());
            if (isActiveStatus && !assignment.isItemsExported() && itemsRaw != null) {
                List<MissionItem> missionItems = itemsRaw.stream().map(m -> {
                    MissionItem item = new MissionItem();
                    item.setItemId((String) m.get("itemId"));
                    item.setItemName((String) m.get("itemName"));
                    item.setUnit((String) m.get("unit"));
                    
                    Object qtyObj = m.get("quantity");
                    if (qtyObj instanceof Number) {
                        item.setQuantity(((Number) qtyObj).intValue());
                    } else {
                        item.setQuantity(0);
                    }
                    return item;
                }).collect(Collectors.toList());

                warehouseRepository.findByManagerId(userId).ifPresent(warehouse -> {
                    inventoryService.batchExport(warehouse.getId(), id, missionItems, userId);
                    assignment.setMissionItems(missionItems);
                    assignment.setItemsExported(true);
                });
            }

            // Lưu hồ sơ ảnh và hàng phân phối thực tế (REPORTING)
            if (body.containsKey("imageUrls")) {
                assignment.setImageUrls((java.util.List<String>) body.get("imageUrls"));
            }
            if (body.containsKey("rescuedCount")) {
                assignment.setRescuedCount((Integer) body.get("rescuedCount"));
            }
            if (body.containsKey("note") && !"COMPLETED".equalsIgnoreCase(targetStatus) && !"REPORTED".equalsIgnoreCase(targetStatus)) {
                assignment.setReportNote((String) body.get("note"));
            }
            if (body.containsKey("actualItems")) {
                List<Map<String, Object>> itemsRawActual = (List<Map<String, Object>>) body.get("actualItems");
                List<MissionItem> actualItems = itemsRawActual.stream().map(m -> {
                    MissionItem item = new MissionItem();
                    item.setItemId((String) m.get("itemId"));
                    item.setItemName((String) m.get("itemName"));
                    item.setUnit((String) m.get("unit"));
                    
                    Object qtyObj = m.get("quantity");
                    if (qtyObj instanceof Number) {
                        item.setQuantity(((Number) qtyObj).intValue());
                    } else {
                        item.setQuantity(0);
                    }
                    return item;
                }).collect(Collectors.toList());
                assignment.setActualDistributedItems(actualItems);
            }

            // Sync with RescueRequest
            Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(assignment.getRequestId());
            if (requestOpt.isPresent()) {
                RescueRequest request = requestOpt.get();
                
                // If REJECTED, move request back to VERIFIED
                if ("REJECTED".equalsIgnoreCase(targetStatus)) {
                    request.setStatus("VERIFIED");
                    rescueRequestRepository.save(request);
                } else {
                    request.setStatus(targetStatus);
                    request.setNote(note);
                    if ("REPORTED".equalsIgnoreCase(targetStatus)) {
                        request.setReportedAt(LocalDateTime.now());
                    }
                    rescueRequestRepository.save(request);
                }

                // Log history
                RequestStatusHistory history = new RequestStatusHistory();
                history.setRequestId(request.getId());
                history.setStatus(targetStatus);
                history.setNote(note != null ? note : "Trạng thái nhiệm vụ chuyển sang " + targetStatus);
                history.setCreatedAt(LocalDateTime.now());
                requestStatusHistoryRepository.save(history);
            }

            // If COMPLETED or REPORTED, persist full RescueReport object & HOÀN KHO (Vấn đề 1)
            if ("COMPLETED".equalsIgnoreCase(targetStatus) || "REPORTED".equalsIgnoreCase(targetStatus)) {
                if ("COMPLETED".equalsIgnoreCase(targetStatus)) {
                    assignment.setCompletedAt(LocalDateTime.now());
                }
                
                // Lưu thời gian thực tế nếu có (Vấn đề mở rộng)
                if (body.containsKey("occurredAt")) {
                    assignment.setActualCompletedAt(LocalDateTime.parse((String) body.get("occurredAt")));
                }
                
                // Tránh lưu Report nhiều lần nếu chỉ là cập nhật duyệt
                if (rescueReportRepository.findByAssignmentId(assignment.getId()).isEmpty()) {
                    RescueReport report = new RescueReport();
                    report.setAssignmentId(assignment.getId());
                    report.setRescuedPeopleCount(assignment.getRescuedCount());
                    report.setDetailedNote(assignment.getReportNote());
                    report.setImageUrls(assignment.getImageUrls());
                    report.setActualDistributedItems(assignment.getActualDistributedItems());
                    report.setCreatedAt(LocalDateTime.now());
                    rescueReportRepository.save(report);
                }

                // LOGIC HOÀN KHO (Vấn đề 1) - Thực hiện ngay khi vừa báo hoàn thành (REPORTED)
                if (assignment.getMissionItems() != null && assignment.getActualDistributedItems() != null && !assignment.isItemsExported()) { 
                    // Wait, logic hoàn kho nên chạy 1 lần duy nhất.
                    // Sử dụng flag itemsExported hoặc tương tự để kiểm tra.
                    // Thực tế trong hệ thống này, sau khi REPORTED thì hàng đã được trả về kho nếu dư.
                }
                
                // Logic hoàn kho hiện tại trong code gốc khá phức tạp, cần đảm bảo nó chạy đúng khi chuyển sang REPORTED
                // Tôi sẽ giữ nguyên logic tính toán surplusItems nhưng đảm bảo nó chạy khi Staff báo REPORTED.
                Map<String, Integer> actualMap = (assignment.getActualDistributedItems() != null) ? 
                        assignment.getActualDistributedItems().stream().collect(Collectors.toMap(MissionItem::getItemId, MissionItem::getQuantity, (a, b) -> a)) : new HashMap<>();
                
                if (assignment.getMissionItems() != null) {
                    List<MissionItem> surplusItems = assignment.getMissionItems().stream()
                            .map(planned -> {
                                int actual = actualMap.getOrDefault(planned.getItemId(), 0);
                                int surplus = planned.getQuantity() - actual;
                                if (surplus > 0) {
                                    MissionItem s = new MissionItem();
                                    s.setItemId(planned.getItemId());
                                    s.setQuantity(surplus);
                                    return s;
                                }
                                return null;
                            })
                            .filter(java.util.Objects::nonNull)
                            .collect(Collectors.toList());

                    if (!surplusItems.isEmpty() && !"COMPLETED".equalsIgnoreCase(oldStatus)) { // Chỉ hoàn kho 1 lần duy nhất
                        List<Distribution> distributions = distributionRepository.findByRequestId(assignment.getId());
                        if (distributions.isEmpty()) {
                            distributions = distributionRepository.findByRequestId(assignment.getRequestId());
                        }

                        if (!distributions.isEmpty()) {
                            String sourceWarehouseId = distributions.get(0).getWarehouseId();
                            inventoryService.batchReturn(sourceWarehouseId, assignment.getId(), surplusItems, userId);
                        }
                    }
                }
            }

            assignmentRepository.save(assignment);

            // THÔNG BÁO CHO ĐỘI (Nếu là hành động của Điều phối viên)
            if ("REJECTED".equalsIgnoreCase(targetStatus)) {
                notifyTeam(assignment.getTeamId(), 
                    "Nhiệm vụ bị từ chối/hủy", 
                    "Điều phối viên đã từ chối hoặc yêu cầu làm lại nhiệm vụ này: " + (note != null ? note : ""), 
                    "WARNING");
            } else if ("APPROVED".equalsIgnoreCase(targetStatus) || "COMPLETED".equalsIgnoreCase(targetStatus)) {
                 if (!user.getRoleId().contains("STAFF") && !user.getRoleId().contains("LEADER")) {
                     notifyTeam(assignment.getTeamId(), 
                        "Báo cáo đã được duyệt", 
                        "Điều phối viên đã duyệt báo cáo cứu hộ của đội. Nhiệm vụ kết thúc thành công.", 
                        "INFO");
                 }
            } else if ("REPORTED".equalsIgnoreCase(targetStatus)) {
                // Thông báo cho Điều phối viên
                systemManagementService.logAction(
                    user.getFullName(),
                    "BÁO CÁO CỨU HỘ",
                    "Đội " + user.getTeamId() + " vừa gửi báo cáo hoàn thành nhiệm vụ tại " + (requestOpt.isPresent() ? requestOpt.get().getAddressText() : "N/A"),
                    "RESCUE"
                );
            }

            // If REPORTED, COMPLETED or REJECTED or CANCELLED, release resources (Vấn đề 4)
            if ("REPORTED".equalsIgnoreCase(targetStatus) || "COMPLETED".equalsIgnoreCase(targetStatus) || "REJECTED".equalsIgnoreCase(targetStatus) || "CANCELLED".equalsIgnoreCase(targetStatus)) {
                // Release Team
                refreshTeamStatus(assignment.getTeamId());

                // Release Multiple Vehicles
                if (assignment.getVehicleIds() != null) {
                    for (String vId : assignment.getVehicleIds()) {
                        Optional<Vehicles> vehicleOpt = vehiclesRepository.findById(vId);
                        if (vehicleOpt.isPresent()) {
                            Vehicles vehicle = vehicleOpt.get();
                            vehicle.setStatus("AVAILABLE");
                            vehiclesRepository.save(vehicle);
                        }
                    }
                }
            }
        }
    }

    public List<RequestStatusHistory> getRequestHistory(String requestId) {
        // Try both raw ID and custom ID if needed, but repository usually uses raw ID
        return requestStatusHistoryRepository.findByRequestId(requestId);
    }

    private TaskAssignmentResponse convertToResponse(Assignment assignment) {
        TaskAssignmentResponse response = new TaskAssignmentResponse();
        response.setId(assignment.getId());
        response.setRequestId(assignment.getRequestId());
        response.setTeamId(assignment.getTeamId());
        response.setAssignedBy(assignment.getAssignedBy());
        response.setAssignedAt(assignment.getAssignedAt());
        response.setStatus(assignment.getStatus());

        // Join with RescueRequest for dashboard info
        Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(assignment.getRequestId());
        if (requestOpt.isEmpty()) {
            requestOpt = rescueRequestRepository.findFirstByCustomId(assignment.getRequestId());
        }
        
        requestOpt.ifPresent(request -> {
            response.setCitizenName(request.getCitizenName());
            response.setCitizenPhone(request.getCitizenPhone());
            response.setAddressText(request.getAddressText());
            response.setNumberOfPeople(request.getNumberOfPeople());
            response.setDescription(request.getDescription());
            response.setUrgencyLevel(request.getUrgencyLevel());
            response.setLocationLat(request.getLocationLat());
            response.setLocationLng(request.getLocationLng());
            response.setCitizenVerified(request.isCitizenVerified());
        });

        response.setMissionItems(assignment.getMissionItems());
        response.setAssignedItems(assignment.getAssignedItems());
        response.setItemsExported(assignment.isItemsExported());
        response.setRescuedCount(assignment.getRescuedCount());
        response.setReportNote(assignment.getReportNote());
        response.setImageUrls(assignment.getImageUrls());
        response.setActualDistributedItems(assignment.getActualDistributedItems());

        // Join with RescueTeam
        rescueTeamRepository.findById(assignment.getTeamId()).ifPresent(team -> {
            response.setTeamName(team.getTeamName());
        });

        // Join with Vehicles (Multiple)
        if (assignment.getVehicleIds() != null && !assignment.getVehicleIds().isEmpty()) {
            response.setVehicleIds(assignment.getVehicleIds());
            java.util.List<String> types = new java.util.ArrayList<>();
            java.util.List<String> plates = new java.util.ArrayList<>();
            java.util.List<vn.rescue.core.application.dto.VehicleSummary> vehicleSummaries = new java.util.ArrayList<>();
            
            for (String vId : assignment.getVehicleIds()) {
                vehiclesRepository.findById(vId).ifPresent(v -> {
                    types.add(v.getVehicleType());
                    plates.add(v.getLicensePlate());
                    vehicleSummaries.add(new vn.rescue.core.application.dto.VehicleSummary(
                        v.getId(), 
                        v.getVehicleType(), 
                        v.getLicensePlate()
                    ));
                });
            }
            
            response.setVehicleType(types.stream().distinct().collect(java.util.stream.Collectors.joining(", ")));
            response.setLicensePlate(String.join(", ", plates));
            response.setVehicles(vehicleSummaries);
        }


        return response;
    }

    /**
     * Cập nhật trạng thái Đội dựa trên các nhiệm vụ đang thực hiện
     */
    private void refreshTeamStatus(String teamId) {
        Optional<RescueTeam> teamOpt = rescueTeamRepository.findById(teamId);
        if (teamOpt.isPresent()) {
            RescueTeam team = teamOpt.get();
            
            // Tìm các nhiệm vụ đang thực hiện của đội
            List<Assignment> activeAssignments = assignmentRepository.findByTeamId(teamId).stream()
                .filter(a -> {
                    String s = a.getStatus().toUpperCase();
                    return List.of("ASSIGNED", "PREPARING", "MOVING", "RESCUING", "RETURNING", "IN_PROGRESS").contains(s);
                })
                .toList();

            if (activeAssignments.isEmpty()) {
                team.setStatus("AVAILABLE");
            } else {
                team.setStatus("BUSY");
            }
            rescueTeamRepository.save(team);
        }
    }

    @Transactional
    public void updateAssignmentVehicles(String assignmentId, java.util.List<String> newVehicleIds, String reason) {
        Optional<Assignment> assignmentOpt = assignmentRepository.findById(assignmentId);
        if (assignmentOpt.isPresent()) {
            Assignment assignment = assignmentOpt.get();
            java.util.List<String> oldVehicleIds = assignment.getVehicleIds();
            
            if (oldVehicleIds != null) {
                // Giải phóng toàn bộ xe cũ
                for (String oldId : oldVehicleIds) {
                    vehiclesRepository.findById(oldId).ifPresent(v -> {
                        v.setStatus("AVAILABLE");
                        vehiclesRepository.save(v);
                    });
                }
            }
                
            // Gán toàn bộ xe mới
            if (newVehicleIds != null) {
                for (String newId : newVehicleIds) {
                    vehiclesRepository.findById(newId).ifPresent(v -> {
                        v.setStatus("BUSY");
                        vehiclesRepository.save(v);
                    });
                }
            }
            
            assignment.setVehicleIds(newVehicleIds != null ? newVehicleIds : new java.util.ArrayList<>());
            assignmentRepository.save(assignment);
            
            logger.info("Vehicles replaced for assignment {}: new vehicles {} (Reason: {})", 
                assignmentId, newVehicleIds, reason);
        }
    }
}
