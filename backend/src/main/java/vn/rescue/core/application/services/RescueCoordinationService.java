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
import vn.rescue.core.domain.repositories.RescueReportRepository;
import vn.rescue.core.domain.entities.RescueReport;
import vn.rescue.core.domain.entities.MissionItem;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
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

    public List<Vehicles> getAvailableVehicles() {
        List<Vehicles> vehicles = vehiclesRepository.findByStatusIgnoreCase("AVAILABLE");
        logger.info("Fixed 403: Found {} available vehicles", vehicles.size());
        return vehicles;
    }

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

            return assignmentRepository.save(assignment);
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
    public void updateAssignmentStatus(String id, java.util.Map<String, Object> body) {
        String status = (String) body.get("status");
        String note = (String) body.get("note");
        String userId = (String) body.get("userId"); // Extra field from App
        List<java.util.Map<String, Object>> itemsRaw = (List<java.util.Map<String, Object>>) body.get("items");

        Optional<Assignment> assignmentOpt = assignmentRepository.findById(id);
        if (assignmentOpt.isPresent()) {
            Assignment assignment = assignmentOpt.get();
            String oldStatus = assignment.getStatus();
            assignment.setStatus(status);
            System.out.println("DEBUG: Updating assignment " + id + " to status: " + status);

            // LOGIC PHẦN 2: Xử lý xuất hàng khi bắt đầu di chuyển (PREPARING -> MOVING)
            if ("MOVING".equalsIgnoreCase(status) && "PREPARING".equalsIgnoreCase(oldStatus) && itemsRaw != null) {
                List<MissionItem> missionItems = itemsRaw.stream().map(m -> {
                    MissionItem item = new MissionItem();
                    item.setItemId((String) m.get("itemId"));
                    item.setItemName((String) m.get("itemName"));
                    item.setUnit((String) m.get("unit"));
                    item.setQuantity((Integer) m.get("quantity"));
                    return item;
                }).collect(Collectors.toList());

                // Tìm kho của Team Leader để trừ hàng
                warehouseRepository.findByManagerId(userId).ifPresent(warehouse -> {
                    inventoryService.batchExport(warehouse.getId(), id, missionItems, userId);
                    // Cập nhật lại danh sách hàng sau khi đã bị "Auto-Cap" bởi InventoryService
                    assignment.setMissionItems(missionItems);
                    assignment.setItemsExported(true); // Đánh dấu đã xuất hàng
                });
            }

            // Lưu hồ sơ ảnh và hàng phân phối thực tế (REPORTING)
            if (body.containsKey("imageUrls")) {
                assignment.setImageUrls((java.util.List<String>) body.get("imageUrls"));
            }
            if (body.containsKey("actualItems")) {
                List<Map<String, Object>> itemsRawActual = (List<Map<String, Object>>) body.get("actualItems");
                List<MissionItem> actualItems = itemsRawActual.stream().map(m -> {
                    MissionItem item = new MissionItem();
                    item.setItemId((String) m.get("itemId"));
                    item.setItemName((String) m.get("itemName"));
                    item.setUnit((String) m.get("unit"));
                    item.setQuantity((Integer) m.get("quantity"));
                    return item;
                }).collect(Collectors.toList());
                assignment.setActualDistributedItems(actualItems);
            }

            // Sync with RescueRequest
            Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(assignment.getRequestId());
            if (requestOpt.isPresent()) {
                RescueRequest request = requestOpt.get();
                
                // If REJECTED, move request back to VERIFIED
                if ("REJECTED".equalsIgnoreCase(status)) {
                    request.setStatus("VERIFIED");
                    rescueRequestRepository.save(request);
                } else {
                    request.setStatus(status);
                    rescueRequestRepository.save(request);
                }

                // Log history
                RequestStatusHistory history = new RequestStatusHistory();
                history.setRequestId(request.getId());
                history.setStatus(status);
                history.setNote(note != null ? note : "Trạng thái nhiệm vụ chuyển sang " + status);
                history.setCreatedAt(LocalDateTime.now());
                requestStatusHistoryRepository.save(history);
            }

            // If COMPLETED, persist full RescueReport object
            if ("COMPLETED".equalsIgnoreCase(status)) {
                assignment.setCompletedAt(LocalDateTime.now());
                
                RescueReport report = new RescueReport();
                report.setAssignmentId(assignment.getId());
                report.setRescuedPeopleCount(assignment.getRescuedCount());
                report.setDetailedNote(assignment.getReportNote());
                report.setImageUrls(assignment.getImageUrls());
                report.setActualDistributedItems(assignment.getActualDistributedItems());
                report.setCreatedAt(LocalDateTime.now());
                rescueReportRepository.save(report);
            }

            assignmentRepository.save(assignment);

            // If COMPLETED or REJECTED or CANCELLED, release resources
            // REPORTED status does NOT release resources yet - Coordinator must confirm (COMPLETED)
            if ("COMPLETED".equalsIgnoreCase(status) || "REJECTED".equalsIgnoreCase(status) || "CANCELLED".equalsIgnoreCase(status)) {
                // Release Team
                Optional<RescueTeam> teamOpt = rescueTeamRepository.findById(assignment.getTeamId());
                teamOpt.ifPresent(team -> {
                    team.setStatus("AVAILABLE");
                    rescueTeamRepository.save(team);
                });

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
            
            for (String vId : assignment.getVehicleIds()) {
                vehiclesRepository.findById(vId).ifPresent(v -> {
                    types.add(v.getVehicleType());
                    plates.add(v.getLicensePlate());
                });
            }
            
            response.setVehicleType(types.stream().distinct().collect(java.util.stream.Collectors.joining(", ")));
            response.setLicensePlate(String.join(", ", plates));
        }

        return response;
    }

    @Transactional
    public void updateAssignmentVehicle(String assignmentId, String newVehicleId, String reason) {
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
                
            // Gán xe mới
            vehiclesRepository.findById(newVehicleId).ifPresent(v -> {
                v.setStatus("BUSY");
                vehiclesRepository.save(v);
            });
            
            assignment.setVehicleIds(java.util.Collections.singletonList(newVehicleId));
            assignmentRepository.save(assignment);
            
            logger.info("Vehicles replaced for assignment {}: new vehicle {} (Reason: {})", 
                assignmentId, newVehicleId, reason);
        }
    }
}
