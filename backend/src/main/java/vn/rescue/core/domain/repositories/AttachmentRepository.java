package vn.rescue.core.domain.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Attachment;

@Repository
public interface AttachmentRepository extends JpaRepository<Attachment, Long> {
}
