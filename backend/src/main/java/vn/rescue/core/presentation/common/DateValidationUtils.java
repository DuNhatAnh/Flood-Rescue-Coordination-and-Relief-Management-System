package vn.rescue.core.presentation.common;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

public class DateValidationUtils {

    private DateValidationUtils() {
    }

    /**
     * Chuyển đổi chuỗi ngày tháng sang LocalDateTime một cách linh hoạt.
     * Hỗ trợ định dạng: yyyy-MM-dd, ISO_DATE_TIME, ISO_INSTANT (UTC với đuôi Z).
     */
    public static LocalDateTime parseDateTime(String dateStr, boolean isEndOfDay) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return null;
        }
        String trimmed = dateStr.trim();
        try {
            // Định dạng ngày đơn thuần: 2026-10-12
            if (trimmed.length() == 10 && trimmed.matches("^\\d{4}-\\d{2}-\\d{2}$")) {
                LocalDate date = LocalDate.parse(trimmed);
                return isEndOfDay ? date.atTime(23, 59, 59, 999999999) : date.atStartOfDay();
            }
            // Định dạng UTC Instant: 2026-10-12T05:40:10Z hoặc có nano
            if (trimmed.endsWith("Z")) {
                Instant instant = Instant.parse(trimmed);
                return LocalDateTime.ofInstant(instant, ZoneId.systemDefault());
            }
            // Định dạng ISO LocalDateTime
            return LocalDateTime.parse(trimmed, DateTimeFormatter.ISO_DATE_TIME);
        } catch (Exception e) {
            try {
                return LocalDateTime.parse(trimmed);
            } catch (Exception ex) {
                throw new IllegalArgumentException("Định dạng ngày không hợp lệ: " + dateStr);
            }
        }
    }

    /**
     * Kiểm tra và chặn lọc khi ngày bắt đầu lớn hơn ngày kết thúc.
     * Ném IllegalArgumentException nếu startDate > endDate.
     */
    public static LocalDateTime[] validateAndParseRange(String startDateStr, String endDateStr) {
        LocalDateTime start = parseDateTime(startDateStr, false);
        LocalDateTime end = parseDateTime(endDateStr, true);

        if (start != null && end != null && start.isAfter(end)) {
            throw new IllegalArgumentException("Ngày bắt đầu không được lớn hơn ngày kết thúc");
        }

        return new LocalDateTime[]{start, end};
    }

    /**
     * Kiểm tra khoảng thời gian giữa 2 đối tượng LocalDateTime.
     */
    public static void validateDateRange(LocalDateTime start, LocalDateTime end) {
        if (start != null && end != null && start.isAfter(end)) {
            throw new IllegalArgumentException("Ngày bắt đầu không được lớn hơn ngày kết thúc");
        }
    }
}
