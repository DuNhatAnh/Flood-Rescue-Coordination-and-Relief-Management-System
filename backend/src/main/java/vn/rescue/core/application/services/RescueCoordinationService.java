package vn.rescue.core.application.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.TaskAssignmentResponse;
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
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
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

    public List<Vehicles> getAvailableVehicles() {
        List<Vehicles> vehicles = vehiclesRepository.findByStatusIgnoreCase("AVAILABLE");
        logger.info("Fixed 403: Found {} available vehicles", vehicles.size());
        return vehicles;
    }

    public Assignment createAssignment(String requestId, String teamId, String vehicleId, String assignedBy) {
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

            // Update vehicle status
            Optional<Vehicles> vehicleOpt = vehiclesRepository.findById(vehicleId);
            if (vehicleOpt.isPresent()) {
                Vehicles vehicle = vehicleOpt.get();
                vehicle.setStatus("BUSY");
                vehiclesRepository.save(vehicle);
            }

            Assignment assignment = new Assignment();
            assignment.setRequestId(request.getId()); // Use canonical ID
            assignment.setTeamId(teamId);
            assignment.setVehicleId(vehicleId);
            assignment.setAssignedBy(assignedBy);
            assignment.setAssignedAt(LocalDateTime.now());
            assignment.setStatus("IN_PROGRESS");

            return assignmentRepository.save(assignment);
        }
        return null;
    }

    public List<TaskAssignmentResponse> getAssignmentsByTeam(String teamId) {
        List<Assignment> assignments = assignmentRepository.findByTeamId(teamId);
        return assignments.stream().map(this::convertToResponse).collect(Collectors.toList());
    }

    @Transactional
    public void updateAssignmentStatus(String id, java.util.Map<String, Object> body) {
        String status = (String) body.get("status");
        String note = (String) body.get("note");

        Optional<Assignment> assignmentOpt = assignmentRepository.findById(id);
        if (assignmentOpt.isPresent()) {
            Assignment assignment = assignmentOpt.get();
            assignment.setStatus(status);
            assignmentRepository.save(assignment);

            // Sync with RescueRequest
            Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(assignment.getRequestId());
            if (requestOpt.isPresent()) {
                RescueRequest request = requestOpt.get();
                request.setStatus(status);
                rescueRequestRepository.save(request);

                // Log history
                RequestStatusHistory history = new RequestStatusHistory();
                history.setRequestId(request.getId());
                history.setStatus(status);
                history.setNote(note != null ? note : "Trạng thái nhiệm vụ chuyển sang " + status);
                history.setCreatedAt(LocalDateTime.now());
                requestStatusHistoryRepository.save(history);

                // If COMPLETED, release resources
                if ("COMPLETED".equalsIgnoreCase(status)) {
                    // Release Team
                    Optional<RescueTeam> teamOpt = rescueTeamRepository.findById(assignment.getTeamId());
                    teamOpt.ifPresent(team -> {
                        team.setStatus("AVAILABLE");
                        rescueTeamRepository.save(team);
                    });

                    // Release Vehicle
                    Optional<Vehicles> vehicleOpt = vehiclesRepository.findById(assignment.getVehicleId());
                    vehicleOpt.ifPresent(vehicle -> {
                        vehicle.setStatus("AVAILABLE");
                        vehiclesRepository.save(vehicle);
                    });
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
        response.setVehicleId(assignment.getVehicleId());
        response.setAssignedBy(assignment.getAssignedBy());
        response.setAssignedAt(assignment.getAssignedAt());
        response.setStatus(assignment.getStatus());

        // Join with RescueRequest for dashboard info
        Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(assignment.getRequestId());
        requestOpt.ifPresent(request -> {
            response.setCitizenName(request.getCitizenName());
            response.setCitizenPhone(request.getCitizenPhone());
            response.setAddressText(request.getAddressText());
            response.setDescription(request.getDescription());
            response.setUrgencyLevel(request.getUrgencyLevel());
            response.setLocationLat(request.getLocationLat());
            response.setLocationLng(request.getLocationLng());
        });

        // Join with RescueTeam
        rescueTeamRepository.findById(assignment.getTeamId()).ifPresent(team -> {
            response.setTeamName(team.getTeamName());
        });

        // Join with Vehicles
        if (assignment.getVehicleId() != null) {
            vehiclesRepository.findById(assignment.getVehicleId()).ifPresent(vehicle -> {
                response.setVehicleType(vehicle.getVehicleType());
                response.setLicensePlate(vehicle.getLicensePlate());
            });
        }

        return response;
    }
}
