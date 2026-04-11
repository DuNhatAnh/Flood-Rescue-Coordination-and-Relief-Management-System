package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.application.services.RescueCoordinationService;
import vn.rescue.core.domain.entities.RescueTeam;
import vn.rescue.core.presentation.common.ApiResponse;
import java.util.List;

@RestController
@RequestMapping("/api/v1/teams")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class TeamController {

    private final RescueCoordinationService rescueCoordinationService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<RescueTeam>>> getAllTeams() {
        return ResponseEntity.ok(ApiResponse.success(rescueCoordinationService.getAllTeams(), "Danh sách đội cứu hộ"));
    }

    @GetMapping("/available")
    public ResponseEntity<ApiResponse<List<RescueTeam>>> getAvailableTeams() {
        return ResponseEntity.ok(ApiResponse.success(rescueCoordinationService.getAvailableTeams(), "Danh sách đội cứu hộ sẵn sàng"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RescueTeam>> getTeamById(@PathVariable String id) {
        return rescueCoordinationService.getTeamById(id)
                .map(team -> ResponseEntity.ok(ApiResponse.success(team, "Thông tin đội cứu hộ")))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RescueTeam>> updateTeam(@PathVariable String id, @RequestBody java.util.Map<String, String> body) {
        String newName = body.get("teamName");
        if (newName == null || newName.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error(400, "Tên đội không được để trống"));
        }
        return ResponseEntity.ok(ApiResponse.success(rescueCoordinationService.updateTeam(id, newName), "Cập nhật tên đội thành công"));
    }
}

