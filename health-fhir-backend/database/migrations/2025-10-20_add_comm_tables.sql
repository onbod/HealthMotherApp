-- Safe migration: Adds FHIR/DAK-compliant communication/admin tables with indexes and triggers
-- No DROP statements; all objects use IF NOT EXISTS or guarded creation

-- ==============================================
-- TIPS TABLE (Merged: Nutrition + Health) - FHIR/DAK compliant
-- ==============================================
CREATE TABLE IF NOT EXISTS tips (
    id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    trimester VARCHAR(10),
    visit VARCHAR(50),
    schedule VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    weeks VARCHAR(50),
    -- DAK Specific Fields
    dak_tip_id VARCHAR(50),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tips_fhir_id ON tips(fhir_id);
CREATE INDEX IF NOT EXISTS idx_tips_category ON tips(category);
CREATE INDEX IF NOT EXISTS idx_tips_is_active ON tips(is_active);

-- ==============================================
-- CHAT SYSTEM - FHIR/DAK compliant
-- ==============================================

-- Chat Threads (conversation overview)
CREATE TABLE IF NOT EXISTS chat_threads (
    id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    user_id VARCHAR(100) NOT NULL,
    health_worker_id VARCHAR(100) NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE SET NULL,
    organization_id INTEGER REFERENCES organization(organization_id) ON DELETE SET NULL,
    last_message TEXT,
    last_message_time TIMESTAMP,
    unread_count INT DEFAULT 0,
    updated_by VARCHAR(100),
    -- DAK Specific Fields
    dak_thread_id VARCHAR(50),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_threads_fhir_id ON chat_threads(fhir_id);
CREATE INDEX IF NOT EXISTS idx_chat_threads_user ON chat_threads(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_threads_health_worker ON chat_threads(health_worker_id);
CREATE INDEX IF NOT EXISTS idx_chat_threads_patient_id ON chat_threads(patient_id);

-- Chat Messages (actual chat content)
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    thread_id INT NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE,
    sender_id VARCHAR(100) NOT NULL,
    receiver_id VARCHAR(100) NOT NULL,
    sender_type VARCHAR(50),
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE SET NULL,
    organization_id INTEGER REFERENCES organization(organization_id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    -- DAK Specific Fields
    dak_message_id VARCHAR(50),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_fhir_id ON chat_messages(fhir_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_thread_id ON chat_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_is_read ON chat_messages(is_read);

-- ==============================================
-- REPORTS TABLE (Client Feedback / Facility Reports) - FHIR/DAK compliant
-- ==============================================
CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    client_number VARCHAR(100) NOT NULL,
    phone_number VARCHAR(30),
    facility_name VARCHAR(150),
    organization_id INTEGER REFERENCES organization(organization_id) ON DELETE SET NULL,
    report_type VARCHAR(100),
    description TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_read BOOLEAN DEFAULT FALSE,
    last_read_at TIMESTAMP,
    reply TEXT,
    reply_sent_at TIMESTAMP,
    reply_sent_by VARCHAR(100),
    deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    -- DAK Specific Fields
    dak_report_id VARCHAR(50),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reports_fhir_id ON reports(fhir_id);
CREATE INDEX IF NOT EXISTS idx_reports_client_number ON reports(client_number);
CREATE INDEX IF NOT EXISTS idx_reports_is_read ON reports(is_read);
CREATE INDEX IF NOT EXISTS idx_reports_deleted ON reports(deleted);

-- ==============================================
-- ADMINS TABLE (maps to FHIR Practitioner) - FHIR/DAK compliant
-- ==============================================
CREATE TABLE IF NOT EXISTS admins (
    id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(150),
    email VARCHAR(150) UNIQUE,
    password_hash TEXT NOT NULL,
    role VARCHAR(50) DEFAULT 'admin',
    practitioner_identifier VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    -- DAK Specific Fields
    dak_admin_id VARCHAR(50),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_admins_fhir_id ON admins(fhir_id);
CREATE INDEX IF NOT EXISTS idx_admins_username ON admins(username);

-- ==============================================
-- TRIGGERS: Guarded creation (no DROP)
-- ==============================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'update_tips_updated_at'
    ) THEN
        CREATE TRIGGER update_tips_updated_at BEFORE UPDATE ON tips
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'update_chat_threads_updated_at'
    ) THEN
        CREATE TRIGGER update_chat_threads_updated_at BEFORE UPDATE ON chat_threads
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'update_chat_messages_updated_at'
    ) THEN
        CREATE TRIGGER update_chat_messages_updated_at BEFORE UPDATE ON chat_messages
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'update_reports_updated_at'
    ) THEN
        CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'update_admins_updated_at'
    ) THEN
        CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;


