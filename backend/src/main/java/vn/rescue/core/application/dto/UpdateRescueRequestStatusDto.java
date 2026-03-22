package vn.rescue.core.application.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateRescueRequestStatusDto {
    @NotBlank(message = "Trạng thái không được để trống")
    private String status;
    
    private String note;
}
