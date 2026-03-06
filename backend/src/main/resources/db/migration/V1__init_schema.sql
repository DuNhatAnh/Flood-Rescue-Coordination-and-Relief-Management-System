-- 1. Bảng roles
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

-- 2. Bảng users
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    role_id INT NOT NULL REFERENCES roles(role_id),
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE / LOCKED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bảng rescue_requests
CREATE TABLE rescue_requests (
    request_id BIGSERIAL PRIMARY KEY,
    citizen_name VARCHAR(100) NOT NULL,
    citizen_phone VARCHAR(20) NOT NULL,
    location_lat DECIMAL(10, 8) NOT NULL,
    location_lng DECIMAL(11, 8) NOT NULL,
    address_text TEXT NOT NULL,
    description TEXT,
    urgency_level VARCHAR(20) DEFAULT 'MEDIUM', -- HIGH / MEDIUM / LOW
    status VARCHAR(20) DEFAULT 'PENDING',       -- PENDING / ASSIGNED / COMPLETED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_by INT REFERENCES users(user_id)   -- Nullable
);

-- 4. Bảng attachments
CREATE TABLE attachments (
    attachment_id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES rescue_requests(request_id) ON DELETE CASCADE,
    file_url VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Bảng request_status_history
CREATE TABLE request_status_history (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES rescue_requests(request_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    updated_by INT REFERENCES users(user_id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    note TEXT
);

-- 6. Bảng rescue_teams
CREATE TABLE rescue_teams (
    team_id SERIAL PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'AVAILABLE', -- AVAILABLE / BUSY
    leader_id INT NOT NULL REFERENCES users(user_id)
);

-- 7. Bảng team_members
CREATE TABLE team_members (
    id SERIAL PRIMARY KEY,
    team_id INT NOT NULL REFERENCES rescue_teams(team_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id),
    role_in_team VARCHAR(50),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Bảng vehicles
CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    vehicle_type VARCHAR(50) NOT NULL,
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'AVAILABLE', -- AVAILABLE / MAINTENANCE / IN_USE
    current_location TEXT,
    team_id INT REFERENCES rescue_teams(team_id) -- Nullable
);

-- 9. Bảng assignments
CREATE TABLE assignments (
    assignment_id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES rescue_requests(request_id),
    team_id INT NOT NULL REFERENCES rescue_teams(team_id),
    assigned_by INT NOT NULL REFERENCES users(user_id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'IN_PROGRESS', -- IN_PROGRESS / COMPLETED / CANCELLED
    completed_at TIMESTAMP
);

-- 10. Bảng resource_allocations
CREATE TABLE resource_allocations (
    id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL REFERENCES assignments(assignment_id) ON DELETE CASCADE,
    vehicle_id INT NOT NULL REFERENCES vehicles(vehicle_id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- 11. Bảng rescue_reports
CREATE TABLE rescue_reports (
    report_id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL REFERENCES assignments(assignment_id) ON DELETE CASCADE,
    rescued_people_count INT DEFAULT 0,
    actual_condition TEXT,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Bảng warehouses
CREATE TABLE warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    location TEXT NOT NULL,
    manager_id INT REFERENCES users(user_id),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. Bảng relief_items
CREATE TABLE relief_items (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    description TEXT
);

-- 14. Bảng inventory
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    item_id INT NOT NULL REFERENCES relief_items(item_id) ON DELETE CASCADE,
    quantity INT DEFAULT 0,
    UNIQUE(warehouse_id, item_id)
);

-- 15. Bảng distributions
CREATE TABLE distributions (
    distribution_id BIGSERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL REFERENCES warehouses(warehouse_id),
    request_id BIGINT REFERENCES rescue_requests(request_id),
    distributed_by INT NOT NULL REFERENCES users(user_id),
    distributed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 16. Bảng distribution_details
CREATE TABLE distribution_details (
    id BIGSERIAL PRIMARY KEY,
    distribution_id BIGINT NOT NULL REFERENCES distributions(distribution_id) ON DELETE CASCADE,
    item_id INT NOT NULL REFERENCES relief_items(item_id),
    quantity INT NOT NULL CHECK (quantity > 0)
);

-- 17. Bảng notifications
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'UNREAD', -- UNREAD / READ
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 18. Bảng system_logs
CREATE TABLE system_logs (
    log_id BIGSERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- INSERT SEED DATA
INSERT INTO roles (role_name) VALUES 
('ADMIN'), 
('COORDINATOR'), 
('STAFF_RESCUE'), 
('STAFF_RESOURCE');

-- password = hash for 'admin123', 'coordinator123', 'staff123'
-- For now, inserting dummy hash string for presentation, team should update these based on Bcrypt mapping.
INSERT INTO users (full_name, email, phone, password, role_id) VALUES 
('System Admin', 'admin@rescue.vn', '0901234567', '$2a$10$wE/.7.2LNoo7c1y3m8B1ue349Gz0Fz9Qn38h6n/Z77cOQG0rM7fQO', 1),
('Task Coordinator', 'coordinator@rescue.vn', '0912345678', '$2a$10$wE/.7.2LNoo7c1y3m8B1ue349Gz0Fz9Qn38h6n/Z77cOQG0rM7fQO', 2),
('Rescue Staff', 'staff@rescue.vn', '0922334455', '$2a$10$wE/.7.2LNoo7c1y3m8B1ue349Gz0Fz9Qn38h6n/Z77cOQG0rM7fQO', 3);
