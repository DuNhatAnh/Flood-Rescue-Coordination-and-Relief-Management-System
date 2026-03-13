package vn.rescue.core.application.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class RescueRequestDto {
    @NotBlank(message = "Họ tên không được để trống")
    private String citizenName;
    
    @NotBlank(message = "Số điện thoại không được để trống")
    @Pattern(regexp = "^(0|\\+84)(\\s|\\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\\d)(\\s|\\.)?(\\d{3})(\\s|\\.)?(\\d{3})$", message = "Số điện thoại không hợp lệ")
    private String citizenPhone;
    
    @NotNull(message = "Tọa độ vĩ độ (Lat) không hợp lệ")
    private Double locationLat;
    
    @NotNull(message = "Tọa độ kinh độ (Lng) không hợp lệ")
    private Double locationLng;
    
    private String addressText;
    private String description;
    private String urgencyLevel;
    
    @Min(value = 1, message = "Số người gặp nạn phải lớn hơn 0")
    private Integer numberOfPeople;
}
