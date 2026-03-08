package vn.rescue.core.presentation.controllers;

import org.springframework.web.bind.annotation.*;
import vn.rescue.core.domain.entities.RescueReport;

@RestController
@RequestMapping("/api/rescue-reports")
public class RescueReportController {

    @PostMapping
    public RescueReport submitReport(@RequestBody RescueReport report) {
        // Skeleton: Return the same report for now
        return report;
    }
}
