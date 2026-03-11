package vn.rescue.core.domain.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import vn.rescue.core.domain.entities.Attachment;

@Repository
public interface AttachmentRepository extends MongoRepository<Attachment, String> {
}
