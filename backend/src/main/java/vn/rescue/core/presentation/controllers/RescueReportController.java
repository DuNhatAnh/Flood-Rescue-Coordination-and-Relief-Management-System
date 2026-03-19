package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.rescue.core.domain.entities.RescueReport;
import vn.rescue.core.domain.repositories.RescueReportRepository;
import vn.rescue.core.presentation.common.ApiResponse;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/v1/rescue-reports")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RescueReportController {

    private final RescueReportRepository rescueReportRepository;

    @PostMapping
    public ResponseEntity<ApiResponse<RescueReport>> submitReport(@RequestBody RescueReport report) {
        report.setCreatedAt(LocalDateTime.now());
        RescueReport savedReport = rescueReportRepository.save(report);
        return ResponseEntity.ok(ApiResponse.success(savedReport, "Rescue report submitted successfully"));
    }
}
