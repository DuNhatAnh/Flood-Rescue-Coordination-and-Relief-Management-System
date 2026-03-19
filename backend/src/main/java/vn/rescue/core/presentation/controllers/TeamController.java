package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.RescueCoordinationService;
import vn.rescue.core.domain.entities.RescueTeam;
import java.util.List;

@RestController
@RequestMapping("/api/v1/teams")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class TeamController {

    private final RescueCoordinationService rescueCoordinationService;

    @GetMapping("/available")
    public ResponseEntity<List<RescueTeam>> getAvailableTeams() {
        return ResponseEntity.ok(rescueCoordinationService.getAvailableTeams());
    }
}
