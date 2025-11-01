-- ==============================================
-- DANGEROUS OPERATIONS: FULL DROP BEFORE RECREATE
-- ==============================================

-- ==============================================
-- CREATE COMPREHENSIVE ENUMS AND TYPES
-- ==============================================
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE encounter_type AS ENUM ('anc_visit', 'delivery', 'postnatal_care', 'emergency');
CREATE TYPE pregnancy_status AS ENUM ('active', 'completed', 'terminated', 'miscarriage');
CREATE TYPE delivery_mode AS ENUM ('normal_vaginal', 'cesarean_section', 'assisted_vaginal', 'emergency_cesarean');
CREATE TYPE delivery_outcome AS ENUM ('live_birth', 'stillbirth', 'miscarriage');
CREATE TYPE feeding_status AS ENUM ('exclusive_breastfeeding', 'mixed_feeding', 'formula_feeding', 'not_feeding');
CREATE TYPE health_status AS ENUM ('healthy', 'sick', 'critical', 'deceased');
CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE contact_status AS ENUM ('scheduled', 'completed', 'missed', 'cancelled');
CREATE TYPE test_result AS ENUM ('positive', 'negative', 'inconclusive', 'pending');
CREATE TYPE marital_status AS ENUM ('single', 'married', 'divorced', 'widowed', 'separated');
CREATE TYPE education_level AS ENUM ('none', 'primary', 'secondary', 'tertiary', 'university');
CREATE TYPE occupation_type AS ENUM ('unemployed', 'farmer', 'trader', 'teacher', 'health_worker', 'other');
CREATE TYPE insurance_type AS ENUM ('none', 'government', 'private', 'community', 'other');

-- ==============================================
-- ORGANIZATION TABLE (FHIR: Organization + DAK)
-- ==============================================
CREATE TABLE organization (
    organization_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(100),
    website VARCHAR(255),
    registration_number VARCHAR(100),
    license_number VARCHAR(100),
    facility_level VARCHAR(50), -- Primary, Secondary, Tertiary
    ownership_type VARCHAR(50), -- Government, Private, NGO
    catchment_area TEXT,
    services_offered TEXT[],
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- PATIENT TABLE (FHIR: Patient + DAK)
-- ==============================================
CREATE TABLE patient (
    patient_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    identifier VARCHAR(50) UNIQUE NOT NULL, -- DAK compliant identifier
    name VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    middle_name VARCHAR(100),
    gender gender_type NOT NULL,
    birth_date DATE,
    age INTEGER,
    marital_status marital_status,
    education_level education_level,
    occupation occupation_type,
    address TEXT,
    village VARCHAR(100),
    chiefdom VARCHAR(100),
    district VARCHAR(100),
    province VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Sierra Leone',
    phone VARCHAR(50),
    alternative_phone VARCHAR(50),
    email VARCHAR(100),
    emergency_contact VARCHAR(255),
    emergency_phone VARCHAR(50),
    national_id VARCHAR(50),
    insurance_type insurance_type,
    insurance_number VARCHAR(100),
    religion VARCHAR(50),
    ethnicity VARCHAR(50),
    language VARCHAR(50),
    -- DAK Specific Fields
    dak_patient_id VARCHAR(50), -- DAK specific patient ID
    registration_date DATE,
    registration_source VARCHAR(100), -- Self, Referral, Outreach
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- PREGNANCY TABLE (FHIR: Condition + DAK)
-- ==============================================
CREATE TABLE pregnancy (
    pregnancy_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    lmp_date DATE,
    edd_date DATE,
    gravida INTEGER DEFAULT 0,
    para INTEGER DEFAULT 0,
    abortion INTEGER DEFAULT 0,
    stillbirth INTEGER DEFAULT 0,
    live_birth INTEGER DEFAULT 0,
    current_gestation_weeks INTEGER,
    status pregnancy_status DEFAULT 'active',
    -- DAK Specific Fields
    dak_pregnancy_id VARCHAR(50),
    pregnancy_number INTEGER, -- 1st, 2nd, 3rd pregnancy
    previous_pregnancy_complications TEXT,
    previous_c_section BOOLEAN DEFAULT FALSE,
    previous_stillbirth BOOLEAN DEFAULT FALSE,
    previous_preterm_birth BOOLEAN DEFAULT FALSE,
    family_history TEXT,
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- ENCOUNTER TABLE (FHIR: Encounter + DAK)
-- ==============================================
CREATE TABLE encounter (
    encounter_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES organization(organization_id),
    encounter_type encounter_type NOT NULL,
    status VARCHAR(50) DEFAULT 'in_progress',
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    -- DAK Specific Fields
    dak_encounter_id VARCHAR(50),
    encounter_reason TEXT,
    chief_complaint TEXT,
    vital_signs JSONB, -- Store all vital signs as JSON
    physical_examination JSONB, -- Store physical exam findings
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- ANC VISIT TABLE (DAK Compliant + FHIR: Encounter)
-- ==============================================
CREATE TABLE anc_visit (
    anc_visit_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    pregnancy_id INTEGER REFERENCES pregnancy(pregnancy_id) ON DELETE CASCADE,
    visit_number INTEGER NOT NULL,
    visit_date DATE NOT NULL,
    gestation_weeks INTEGER,
    -- Physical Measurements
    weight_kg DECIMAL(5,2),
    height_cm DECIMAL(5,2),
    bmi DECIMAL(4,2),
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    pulse_rate INTEGER,
    temperature DECIMAL(4,2),
    respiratory_rate INTEGER,
    -- Obstetric Measurements
    fundal_height_cm DECIMAL(5,2),
    fetal_heart_rate INTEGER,
    fetal_position VARCHAR(50),
    fetal_movement BOOLEAN,
    -- Laboratory Results
    hemoglobin_gdl DECIMAL(4,2),
    hematocrit DECIMAL(4,2),
    blood_group VARCHAR(10),
    rhesus_factor VARCHAR(10),
    urine_protein VARCHAR(20),
    urine_glucose VARCHAR(20),
    urine_ketones VARCHAR(20),
    urine_blood VARCHAR(20),
    -- Test Results
    hiv_test_done BOOLEAN DEFAULT FALSE,
    hiv_test_result test_result,
    hiv_test_date DATE,
    syphilis_test_done BOOLEAN DEFAULT FALSE,
    syphilis_test_result test_result,
    syphilis_test_date DATE,
    hepatitis_b_test_done BOOLEAN DEFAULT FALSE,
    hepatitis_b_test_result test_result,
    hepatitis_b_test_date DATE,
    malaria_test_done BOOLEAN DEFAULT FALSE,
    malaria_test_result test_result,
    malaria_test_date DATE,
    -- Clinical Assessment
    maternal_complaints TEXT,
    danger_signs_present BOOLEAN DEFAULT FALSE,
    danger_signs_list TEXT,
    provider_notes TEXT,
    clinical_impression TEXT,
    plan_of_care TEXT,
    
    -- DAK Compliance Fields
    dak_contact_number INTEGER NOT NULL,
    risk_level risk_level DEFAULT 'low',
    risk_factors TEXT[],
    iron_supplement_given BOOLEAN DEFAULT FALSE,
    iron_supplement_dosage VARCHAR(50),
    folic_acid_given BOOLEAN DEFAULT FALSE,
    folic_acid_dosage VARCHAR(50),
    tetanus_toxoid_given BOOLEAN DEFAULT FALSE,
    tetanus_toxoid_dose INTEGER,
    malaria_prophylaxis_given BOOLEAN DEFAULT FALSE,
    malaria_prophylaxis_type VARCHAR(100),
    deworming_given BOOLEAN DEFAULT FALSE,
    deworming_type VARCHAR(100),
    -- Provider Information
    provider_name VARCHAR(255),
    provider_qualification VARCHAR(100),
    provider_id VARCHAR(50),
    -- Follow-up
    next_visit_date DATE,
    next_visit_gestation_weeks INTEGER,
    referral_made BOOLEAN DEFAULT FALSE,
    referral_reason TEXT,
    referral_facility VARCHAR(255),
    
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- OBSERVATION TABLE (FHIR: Observation + DAK)
-- ==============================================
CREATE TABLE observation (
    observation_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    observation_type VARCHAR(100) NOT NULL,
    observation_code VARCHAR(50), -- LOINC code
    observation_name VARCHAR(255),
    value_string VARCHAR(255),
    value_number DECIMAL(10,2),
    value_date DATE,
    value_boolean BOOLEAN,
    unit VARCHAR(50),
    reference_range VARCHAR(100),
    interpretation VARCHAR(50), -- Normal, High, Low, Critical
    status VARCHAR(50) DEFAULT 'final',
    -- DAK Specific Fields
    dak_observation_id VARCHAR(50),
    measurement_method VARCHAR(100),
    measurement_device VARCHAR(100),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- CONDITION TABLE (FHIR: Condition + DAK)
-- ==============================================
CREATE TABLE condition (
    condition_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    condition_code VARCHAR(50), -- ICD-10 code
    condition_name VARCHAR(255) NOT NULL,
    condition_category VARCHAR(100), -- Maternal, Fetal, Obstetric
    severity VARCHAR(50), -- Mild, Moderate, Severe
    status VARCHAR(50) DEFAULT 'active',
    onset_date DATE,
    resolution_date DATE,
    -- DAK Specific Fields
    dak_condition_id VARCHAR(50),
    risk_level risk_level,
    management_plan TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- PROCEDURE TABLE (FHIR: Procedure + DAK)
-- ==============================================
CREATE TABLE procedure (
    procedure_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    procedure_code VARCHAR(50), -- CPT code
    procedure_name VARCHAR(255) NOT NULL,
    procedure_category VARCHAR(100), -- Diagnostic, Therapeutic, Surgical
    status VARCHAR(50) DEFAULT 'completed',
    performed_date DATE,
    performed_time TIME,
    -- DAK Specific Fields
    dak_procedure_id VARCHAR(50),
    indication TEXT,
    complications TEXT,
    outcome VARCHAR(100),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- DELIVERY TABLE (FHIR: Procedure + DAK)
-- ==============================================
CREATE TABLE delivery (
    delivery_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    pregnancy_id INTEGER REFERENCES pregnancy(pregnancy_id) ON DELETE CASCADE,
    delivery_date DATE NOT NULL,
    delivery_time TIME,
    delivery_mode delivery_mode,
    delivery_outcome delivery_outcome,
    -- Maternal Measurements
    maternal_weight_kg DECIMAL(5,2),
    maternal_height_cm DECIMAL(5,2),
    -- Fetal Measurements
    apgar_1min INTEGER,
    apgar_5min INTEGER,
    birth_weight_grams INTEGER,
    birth_length_cm DECIMAL(5,2),
    head_circumference_cm DECIMAL(5,2),
    chest_circumference_cm DECIMAL(5,2),
    sex gender_type,
    -- Delivery Details
    labor_duration_hours DECIMAL(4,2),
    delivery_complications TEXT,
    episiotomy BOOLEAN DEFAULT FALSE,
    perineal_tear VARCHAR(50),
    blood_loss_ml INTEGER,
    -- DAK Specific Fields
    dak_delivery_id VARCHAR(50),
    delivery_facility VARCHAR(255),
    delivery_provider VARCHAR(255),
    delivery_provider_qualification VARCHAR(100),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- NEONATE TABLE (FHIR: Patient + DAK)
-- ==============================================
CREATE TABLE neonate (
    neonate_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    delivery_id INTEGER REFERENCES delivery(delivery_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    name VARCHAR(255),
    birth_date DATE NOT NULL,
    birth_time TIME,
    birth_weight_grams INTEGER,
    birth_length_cm DECIMAL(5,2),
    head_circumference_cm DECIMAL(5,2),
    chest_circumference_cm DECIMAL(5,2),
    sex gender_type,
    apgar_1min INTEGER,
    apgar_5min INTEGER,
    delivery_mode delivery_mode,
    -- DAK Specific Fields
    dak_neonate_id VARCHAR(50),
    birth_certificate_number VARCHAR(50),
    birth_registration_date DATE,
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- POSTNATAL CARE TABLE (FHIR: Encounter + DAK)
-- ==============================================
CREATE TABLE postnatal_care (
    postnatal_care_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    neonate_id INTEGER REFERENCES neonate(neonate_id) ON DELETE CASCADE,
    visit_date DATE NOT NULL,
    visit_type VARCHAR(100),
    -- Maternal Assessment
    maternal_weight_kg DECIMAL(5,2),
    maternal_bp_systolic INTEGER,
    maternal_bp_diastolic INTEGER,
    maternal_temperature DECIMAL(4,2),
    maternal_pulse INTEGER,
    maternal_complaints TEXT,
    maternal_bleeding VARCHAR(50), -- None, Light, Moderate, Heavy
    maternal_lochia VARCHAR(50), -- Normal, Abnormal
    -- Neonate Assessment
    neonate_weight_grams INTEGER,
    neonate_temperature DECIMAL(4,2),
    neonate_feeding_status feeding_status,
    neonate_health_status health_status,
    neonate_jaundice BOOLEAN DEFAULT FALSE,
    neonate_cord_status VARCHAR(50), -- Dry, Infected, Bleeding
    -- DAK Specific Fields
    dak_pnc_id VARCHAR(50),
    pnc_visit_number INTEGER,
    days_postpartum INTEGER,
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- MEDICATION STATEMENT TABLE (FHIR: MedicationStatement + DAK)
-- ==============================================
CREATE TABLE medication_statement (
    medication_statement_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    medication_code VARCHAR(50), -- NDC code
    medication_name VARCHAR(255) NOT NULL,
    medication_category VARCHAR(100), -- Iron, Folic Acid, Tetanus, etc.
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    route VARCHAR(50), -- Oral, IM, IV, etc.
    start_date DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'active',
    -- DAK Specific Fields
    dak_medication_id VARCHAR(50),
    prescribed_by VARCHAR(255),
    prescription_date DATE,
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- DAK CONTACT SCHEDULE TABLE (Essential DAK)
-- ==============================================
CREATE TABLE dak_contact_schedule (
    contact_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    pregnancy_id INTEGER REFERENCES pregnancy(pregnancy_id) ON DELETE CASCADE,
    contact_number INTEGER NOT NULL,
    recommended_gestation_weeks INTEGER NOT NULL,
    contact_date DATE,
    contact_status contact_status DEFAULT 'scheduled',
    provider_notes TEXT,
    -- DAK Specific Fields
    dak_contact_id VARCHAR(50),
    contact_type VARCHAR(100), -- ANC, PNC, Emergency
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- DAK RISK ASSESSMENT TABLE (Essential DAK)
-- ==============================================
CREATE TABLE dak_risk_assessment (
    risk_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    risk_category VARCHAR(50) NOT NULL,
    risk_factors TEXT,
    risk_score INTEGER,
    risk_level risk_level,
    management_plan TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    -- DAK Specific Fields
    dak_risk_id VARCHAR(50),
    assessment_date DATE,
    assessor_name VARCHAR(255),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- DAK QUALITY INDICATORS TABLE (Essential DAK)
-- ==============================================
CREATE TABLE dak_quality_indicators (
    indicator_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id) ON DELETE CASCADE,
    encounter_id INTEGER REFERENCES encounter(encounter_id) ON DELETE CASCADE,
    indicator_code VARCHAR(50) NOT NULL,
    indicator_name VARCHAR(255) NOT NULL,
    indicator_value VARCHAR(255),
    indicator_status VARCHAR(50) DEFAULT 'completed',
    risk_flag VARCHAR(10) DEFAULT 'no',
    decision_support_message TEXT,
    next_visit_schedule DATE,
    -- DAK Specific Fields
    dak_indicator_id VARCHAR(50),
    measurement_date DATE,
    target_value VARCHAR(255),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- DAK CONFIGURATION TABLE (Essential DAK)
-- ==============================================
CREATE TABLE dak_configuration (
    config_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    config_key VARCHAR(255) UNIQUE NOT NULL,
    config_value TEXT,
    config_description TEXT,
    config_category VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    -- DAK Specific Fields
    dak_config_id VARCHAR(50),
    -- FHIR Resource Data
    fhir_resource JSONB,
    version_id VARCHAR(50),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- TIPS TABLE (Merged: Nutrition + Health) - FHIR/DAK compliant
-- ==============================================
CREATE TABLE tips (
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

-- ==============================================
-- CHAT SYSTEM - FHIR/DAK compliant
-- ==============================================

-- Chat Threads (conversation overview)
CREATE TABLE chat_threads (
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

-- Chat Messages (actual chat content)
CREATE TABLE chat_messages (
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

-- ==============================================
-- REPORTS TABLE (Client Feedback / Facility Reports) - FHIR/DAK compliant
-- ==============================================
CREATE TABLE reports (
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

-- ==============================================
-- ADMINS TABLE (maps to FHIR Practitioner) - FHIR/DAK compliant
-- ==============================================
CREATE TABLE admins (
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

-- ==============================================
-- FHIR RESOURCES TABLE (for FHIR API endpoints)
-- ==============================================
CREATE TABLE fhir_resources (
    id SERIAL PRIMARY KEY,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(50) NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(resource_type, resource_id)
);

-- ==============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ==============================================
CREATE INDEX idx_patient_identifier ON patient(identifier);
CREATE INDEX idx_patient_name ON patient(name);
CREATE INDEX idx_patient_fhir_id ON patient(fhir_id);
CREATE INDEX idx_patient_dak_id ON patient(dak_patient_id);
CREATE INDEX idx_encounter_patient_id ON encounter(patient_id);
CREATE INDEX idx_encounter_type ON encounter(encounter_type);
CREATE INDEX idx_encounter_fhir_id ON encounter(fhir_id);
CREATE INDEX idx_anc_visit_patient_id ON anc_visit(pregnancy_id);
CREATE INDEX idx_anc_visit_date ON anc_visit(visit_date);
CREATE INDEX idx_anc_visit_contact_number ON anc_visit(dak_contact_number);
CREATE INDEX idx_anc_visit_fhir_id ON anc_visit(fhir_id);
CREATE INDEX idx_observation_patient_id ON observation(patient_id);
CREATE INDEX idx_observation_type ON observation(observation_type);
CREATE INDEX idx_observation_fhir_id ON observation(fhir_id);
CREATE INDEX idx_delivery_patient_id ON delivery(patient_id);
CREATE INDEX idx_delivery_fhir_id ON delivery(fhir_id);
CREATE INDEX idx_neonate_patient_id ON neonate(patient_id);
CREATE INDEX idx_neonate_fhir_id ON neonate(fhir_id);
CREATE INDEX idx_postnatal_care_patient_id ON postnatal_care(patient_id);
CREATE INDEX idx_postnatal_care_fhir_id ON postnatal_care(fhir_id);
CREATE INDEX idx_medication_patient_id ON medication_statement(patient_id);
CREATE INDEX idx_medication_fhir_id ON medication_statement(fhir_id);
CREATE INDEX idx_dak_contact_schedule_patient_id ON dak_contact_schedule(patient_id);
CREATE INDEX idx_dak_contact_schedule_fhir_id ON dak_contact_schedule(fhir_id);
CREATE INDEX idx_dak_risk_assessment_patient_id ON dak_risk_assessment(patient_id);
CREATE INDEX idx_dak_risk_assessment_fhir_id ON dak_risk_assessment(fhir_id);
CREATE INDEX idx_dak_quality_indicators_patient_id ON dak_quality_indicators(patient_id);
CREATE INDEX idx_dak_quality_indicators_code ON dak_quality_indicators(indicator_code);
CREATE INDEX idx_dak_quality_indicators_fhir_id ON dak_quality_indicators(fhir_id);

-- New indexes for added tables
CREATE INDEX idx_tips_fhir_id ON tips(fhir_id);
CREATE INDEX idx_tips_category ON tips(category);
CREATE INDEX idx_tips_is_active ON tips(is_active);

CREATE INDEX idx_chat_threads_fhir_id ON chat_threads(fhir_id);
CREATE INDEX idx_chat_threads_user ON chat_threads(user_id);
CREATE INDEX idx_chat_threads_health_worker ON chat_threads(health_worker_id);
CREATE INDEX idx_chat_threads_patient_id ON chat_threads(patient_id);

CREATE INDEX idx_chat_messages_fhir_id ON chat_messages(fhir_id);
CREATE INDEX idx_chat_messages_thread_id ON chat_messages(thread_id);
CREATE INDEX idx_chat_messages_is_read ON chat_messages(is_read);

CREATE INDEX idx_reports_fhir_id ON reports(fhir_id);
CREATE INDEX idx_reports_client_number ON reports(client_number);
CREATE INDEX idx_reports_is_read ON reports(is_read);
CREATE INDEX idx_reports_deleted ON reports(deleted);

CREATE INDEX idx_admins_fhir_id ON admins(fhir_id);
CREATE INDEX idx_admins_username ON admins(username);

-- ==============================================
-- CREATE TRIGGERS FOR UPDATED_AT
-- ==============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables
CREATE TRIGGER update_organization_updated_at BEFORE UPDATE ON organization FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_patient_updated_at BEFORE UPDATE ON patient FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pregnancy_updated_at BEFORE UPDATE ON pregnancy FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_encounter_updated_at BEFORE UPDATE ON encounter FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_anc_visit_updated_at BEFORE UPDATE ON anc_visit FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_observation_updated_at BEFORE UPDATE ON observation FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_condition_updated_at BEFORE UPDATE ON condition FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_procedure_updated_at BEFORE UPDATE ON procedure FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_delivery_updated_at BEFORE UPDATE ON delivery FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_neonate_updated_at BEFORE UPDATE ON neonate FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_postnatal_care_updated_at BEFORE UPDATE ON postnatal_care FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medication_statement_updated_at BEFORE UPDATE ON medication_statement FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dak_contact_schedule_updated_at BEFORE UPDATE ON dak_contact_schedule FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dak_risk_assessment_updated_at BEFORE UPDATE ON dak_risk_assessment FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dak_quality_indicators_updated_at BEFORE UPDATE ON dak_quality_indicators FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dak_configuration_updated_at BEFORE UPDATE ON dak_configuration FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tips_updated_at BEFORE UPDATE ON tips FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_threads_updated_at BEFORE UPDATE ON chat_threads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_messages_updated_at BEFORE UPDATE ON chat_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- INSERT DAK CONFIGURATION DATA
-- ==============================================
INSERT INTO dak_configuration (fhir_id, dak_config_id, config_key, config_value, config_description, config_category) VALUES
('dak-config-001', 'dak-config-001', 'dak_version', '1.0', 'DAK Version', 'system'),
('dak-config-002', 'dak-config-002', 'anc_contact_1_weeks', '12', 'First ANC contact recommended at 12 weeks', 'anc_schedule'),
('dak-config-003', 'dak-config-003', 'anc_contact_2_weeks', '16', 'Second ANC contact recommended at 16 weeks', 'anc_schedule'),
('dak-config-004', 'dak-config-004', 'anc_contact_3_weeks', '20', 'Third ANC contact recommended at 20 weeks', 'anc_schedule'),
('dak-config-005', 'dak-config-005', 'anc_contact_4_weeks', '26', 'Fourth ANC contact recommended at 26 weeks', 'anc_schedule'),
('dak-config-006', 'dak-config-006', 'anc_contact_5_weeks', '30', 'Fifth ANC contact recommended at 30 weeks', 'anc_schedule'),
('dak-config-007', 'dak-config-007', 'anc_contact_6_weeks', '34', 'Sixth ANC contact recommended at 34 weeks', 'anc_schedule'),
('dak-config-008', 'dak-config-008', 'anc_contact_7_weeks', '36', 'Seventh ANC contact recommended at 36 weeks', 'anc_schedule'),
('dak-config-009', 'dak-config-009', 'anc_contact_8_weeks', '38', 'Eighth ANC contact recommended at 38 weeks', 'anc_schedule'),
('dak-config-010', 'dak-config-010', 'hemoglobin_normal_min', '11.0', 'Minimum normal hemoglobin level (g/dL)', 'clinical_thresholds'),
('dak-config-011', 'dak-config-011', 'hemoglobin_normal_max', '13.0', 'Maximum normal hemoglobin level (g/dL)', 'clinical_thresholds'),
('dak-config-012', 'dak-config-012', 'blood_pressure_normal_systolic', '140', 'Normal systolic blood pressure threshold (mmHg)', 'clinical_thresholds'),
('dak-config-013', 'dak-config-013', 'blood_pressure_normal_diastolic', '90', 'Normal diastolic blood pressure threshold (mmHg)', 'clinical_thresholds'),
('dak-config-014', 'dak-config-014', 'fundal_height_normal_min', '20', 'Minimum normal fundal height at 20 weeks (cm)', 'clinical_thresholds'),
('dak-config-015', 'dak-config-015', 'fundal_height_normal_max', '40', 'Maximum normal fundal height at term (cm)', 'clinical_thresholds'),
('dak-config-016', 'dak-config-016', 'fetal_heart_rate_normal_min', '110', 'Minimum normal fetal heart rate (bpm)', 'clinical_thresholds'),
('dak-config-017', 'dak-config-017', 'fetal_heart_rate_normal_max', '160', 'Maximum normal fetal heart rate (bpm)', 'clinical_thresholds'),
('dak-config-018', 'dak-config-018', 'weight_gain_normal_min', '1.0', 'Minimum normal weight gain per month (kg)', 'clinical_thresholds'),
('dak-config-019', 'dak-config-019', 'weight_gain_normal_max', '2.0', 'Maximum normal weight gain per month (kg)', 'clinical_thresholds'),
('dak-config-020', 'dak-config-020', 'risk_level_low', 'low', 'Low risk level', 'risk_assessment'),
('dak-config-021', 'dak-config-021', 'risk_level_medium', 'medium', 'Medium risk level', 'risk_assessment'),
('dak-config-022', 'dak-config-022', 'risk_level_high', 'high', 'High risk level', 'risk_assessment'),
('dak-config-023', 'dak-config-023', 'risk_level_critical', 'critical', 'Critical risk level', 'risk_assessment'),
('dak-config-024', 'dak-config-024', 'decision_support_enabled', 'true', 'Enable decision support system', 'system'),
('dak-config-025', 'dak-config-025', 'quality_indicators_enabled', 'true', 'Enable quality indicators tracking', 'system'),
('dak-config-026', 'dak-config-026', 'audit_trail_enabled', 'true', 'Enable audit trail logging', 'system'),
('dak-config-027', 'dak-config-027', 'data_quality_monitoring', 'true', 'Enable data quality monitoring', 'system'),
('dak-config-028', 'dak-config-028', 'reporting_enabled', 'true', 'Enable reporting functionality', 'system'),
('dak-config-029', 'dak-config-029', 'compliance_checklist_enabled', 'true', 'Enable compliance checklist', 'system'),
('dak-config-030', 'dak-config-030', 'performance_indicators_enabled', 'true', 'Enable performance indicators', 'system'),
('dak-config-031', 'dak-config-031', 'dak_indicators_enabled', 'true', 'Enable DAK indicators tracking', 'system'),
('dak-config-032', 'dak-config-032', 'anc_contact_schedule_enabled', 'true', 'Enable ANC contact schedule tracking', 'system'),
('dak-config-033', 'dak-config-033', 'risk_assessment_enabled', 'true', 'Enable risk assessment functionality', 'system'),
('dak-config-034', 'dak-config-034', 'quality_metrics_enabled', 'true', 'Enable quality metrics tracking', 'system'),
('dak-config-035', 'dak-config-035', 'data_quality_enabled', 'true', 'Enable data quality monitoring', 'system');