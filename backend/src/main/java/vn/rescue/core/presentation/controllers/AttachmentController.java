package vn.rescue.core.presentation.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.rescue.core.application.services.FileStorageService;
import vn.rescue.core.application.services.RescueRequestService;
import vn.rescue.core.domain.entities.Attachment;
import vn.rescue.core.domain.entities.RescueRequest;
import vn.rescue.core.domain.repositories.AttachmentRepository;
import vn.rescue.core.presentation.common.ApiResponse;

@RestController
@RequestMapping("/api/v1/attachments")
@RequiredArgsConstructor
public class AttachmentController {

    private final FileStorageService fileStorageService;
    private final AttachmentRepository attachmentRepository;
    private final RescueRequestService rescueRequestService;

    @PostMapping("/upload")
    public ResponseEntity<ApiResponse<String>> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("requestId") String requestId) {

        RescueRequest request = rescueRequestService.getById(requestId);
        String fileUrl = fileStorageService.save(file);

        Attachment attachment = new Attachment();
        attachment.setRequestId(request.getId());
        attachment.setFileUrl(fileUrl);
        attachmentRepository.save(attachment);

        return ResponseEntity.ok(ApiResponse.success(fileUrl, "Tải lên thành công"));
    }
}
