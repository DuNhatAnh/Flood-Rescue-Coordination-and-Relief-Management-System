package vn.rescue.core.application.services;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
public class FileStorageService {

    private final Path root = Paths.get("uploads");

    public FileStorageService() {
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            throw new RuntimeException("Could not initialize folder for upload!");
        }
    }

    public String save(MultipartFile file) {
        if (file == null || file.isEmpty() || file.getSize() == 0) {
            throw new IllegalArgumentException("File tải lên không được để rỗng");
        }
        try {
            String originalFilename = file.getOriginalFilename();
            String cleanFilename = (originalFilename != null) ? Paths.get(originalFilename).getFileName().toString() : "file";
            String filename = UUID.randomUUID().toString() + "_" + cleanFilename;
            Files.copy(file.getInputStream(), this.root.resolve(filename));
            return "/uploads/" + filename;
        } catch (Exception e) {
            throw new RuntimeException("Could not store the file. Error: " + e.getMessage());
        }
    }
}
