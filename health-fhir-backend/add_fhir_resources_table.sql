-- Add fhir_resources table to existing database
CREATE TABLE IF NOT EXISTS fhir_resources (
    id SERIAL PRIMARY KEY,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(50) NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(resource_type, resource_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_fhir_resources_type ON fhir_resources(resource_type);
CREATE INDEX IF NOT EXISTS idx_fhir_resources_id ON fhir_resources(resource_id);
CREATE INDEX IF NOT EXISTS idx_fhir_resources_data ON fhir_resources USING GIN(data);
