package vn.rescue.core.application.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.rescue.core.domain.entities.Assignment;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.AssignmentRepository;
import vn.rescue.core.domain.repositories.RescueRequestRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class RescueCoordinationService {

    @Autowired
    private RescueRequestRepository rescueRequestRepository;

    @Autowired
    private AssignmentRepository assignmentRepository;

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
        if (requestOpt.isPresent()) {
            RescueRequest request = requestOpt.get();
            request.setVerified(true);
            request.setVerifiedBy(verifiedBy);
            rescueRequestRepository.save(request);
        }
    }

    public Assignment createAssignment(String requestId, String teamId, String assignedBy) {
        Optional<RescueRequest> requestOpt = rescueRequestRepository.findById(requestId);
        if (requestOpt.isPresent()) {
            RescueRequest request = requestOpt.get();
            request.setStatus("ASSIGNED");
            rescueRequestRepository.save(request);

            Assignment assignment = new Assignment();
            assignment.setRequestId(requestId);
            assignment.setTeamId(teamId);
            assignment.setAssignedBy(assignedBy);
            assignment.setAssignedAt(LocalDateTime.now());
            assignment.setStatus("IN_PROGRESS");
            
            return assignmentRepository.save(assignment);
        }
        return null;
    }
}
