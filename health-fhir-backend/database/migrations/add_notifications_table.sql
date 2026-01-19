-- ==============================================
-- MIGRATION: Add notifications table
-- ==============================================
-- This migration adds the notifications table to support
-- patient notifications in the mobile app and admin dashboard

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE SET NULL,
    organization_id INTEGER REFERENCES organization(organization_id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    target_categories TEXT[], -- Array of target categories (e.g., ['first_trimester', 'high_risk'])
    type VARCHAR(50) DEFAULT 'general', -- notification, system_update, emergency
    status VARCHAR(50) DEFAULT 'sent', -- sent, pending, delivered, failed
    scheduled_at TIMESTAMP,
    trimester VARCHAR(20), -- first, second, third, all
    visit INTEGER, -- Specific ANC visit number
    weeks INTEGER, -- Specific gestational weeks
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    recipient_id VARCHAR(100), -- Patient identifier or phone number
    -- DAK Specific Fields
    dak_notification_id VARCHAR(50),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_fhir_id ON notifications(fhir_id);
CREATE INDEX IF NOT EXISTS idx_notifications_patient_id ON notifications(patient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_trimester ON notifications(trimester);
CREATE INDEX IF NOT EXISTS idx_notifications_visit ON notifications(visit);
CREATE INDEX IF NOT EXISTS idx_notifications_weeks ON notifications(weeks);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Create trigger for updated_at
CREATE TRIGGER update_notifications_updated_at 
    BEFORE UPDATE ON notifications 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();




