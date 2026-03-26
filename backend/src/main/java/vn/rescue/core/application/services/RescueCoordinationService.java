package vn.rescue.core.application.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.rescue.core.application.dto.TaskAssignmentResponse;
import vn.rescue.core.domain.entities.Assignment;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.domain.entities.Vehicles;
import vn.rescue.core.domain.repositories.AssignmentRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;
import vn.rescue.core.domain.repositories.RescueTeamRepository;
import vn.rescue.core.domain.repositories.VehiclesRepository;

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

        return response;
    }
}
