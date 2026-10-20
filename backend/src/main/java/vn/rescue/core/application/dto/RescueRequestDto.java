package vn.rescue.core.application.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
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
    @Pattern(regexp = "^(0|\\+84)(\\s|\\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\\d)(\\s|\\.)?(\\d{3})(\\s|\\.)?(\\d{3})$", message = "Số điện thoại không hợp lệ")
    private String citizenPhone;
    
    @NotNull(message = "Tọa độ vĩ độ (Lat) không được để trống")
    @DecimalMin(value = "-90.0", message = "Vĩ độ (Lat) phải nằm trong khoảng từ -90.0 đến 90.0")
    @DecimalMax(value = "90.0", message = "Vĩ độ (Lat) phải nằm trong khoảng từ -90.0 đến 90.0")
    private Double locationLat;
    
    @NotNull(message = "Tọa độ kinh độ (Lng) không được để trống")
    @DecimalMin(value = "-180.0", message = "Kinh độ (Lng) phải nằm trong khoảng từ -180.0 đến 180.0")
    @DecimalMax(value = "180.0", message = "Kinh độ (Lng) phải nằm trong khoảng từ -180.0 đến 180.0")
    private Double locationLng;
    
    private String addressText;
    private String description;
    private String urgencyLevel;
    
    @Min(value = 1, message = "Số người gặp nạn phải lớn hơn 0")
    private Integer numberOfPeople;
}
