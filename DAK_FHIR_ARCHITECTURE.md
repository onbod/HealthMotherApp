# DAK & FHIR Architecture - HealthyMama

## 🎯 Overview

This document focuses specifically on the **DAK (District Assessment Kit)** and **FHIR R4** implementation within the HealthyMama system, detailing how these standards are integrated into the healthcare workflow for Sierra Leone.

---

## 📋 Table of Contents

1. [DAK Overview](#dak-overview)
2. [FHIR R4 Overview](#fhir-r4-overview)
3. [DAK Implementation](#dak-implementation)
4. [FHIR Implementation](#fhir-implementation)
5. [Integration Architecture](#integration-architecture)
6. [Database Tables](#database-tables)
7. [API Endpoints](#api-endpoints)
8. [Workflow Examples](#workflow-examples)

---

## 🎯 DAK Overview

### What is DAK?

**District Assessment Kit (DAK)** is a comprehensive tool for maternal and child health monitoring in Sierra Leone, following WHO recommendations for antenatal care, delivery, and postnatal care.

### DAK Components in HealthyMama:

1. **DAK Contact Schedule**: Recommended contact schedules for ANC/PNC
2. **DAK Risk Assessment**: Maternal risk level evaluation
3. **DAK Quality Indicators**: Care quality metrics
4. **DAK Configuration**: System-wide DAK settings
5. **DAK Decision Support**: Clinical decision algorithms

---

## 📋 FHIR R4 Overview

### What is FHIR?

**Fast Healthcare Interoperability Resources (FHIR) R4** is an international standard for exchanging healthcare information electronically. It provides:

- **Resource-based data model**: Standard data structures
- **RESTful API**: Standard API patterns
- **JSON/XML support**: Multiple formats
- **Extensibility**: Custom elements when needed

### FHIR Resources in HealthyMama:

1. **Patient**: Demographics and identification
2. **Encounter**: Healthcare visits
3. **Observation**: Clinical measurements
4. **Condition**: Diagnoses and medical conditions
5. **Procedure**: Medical procedures performed
6. **MedicationStatement**: Prescribed medications
7. **PregnancyEpisod**: Pregnancy episodes
8. **Delivery**: Delivery events
9. **Neonate**: Newborn information

---

## 🏗️ DAK Implementation

### 1. DAK Contact Schedule

**Purpose**: Track and schedule patient contacts according to WHO/DAK guidelines

**Table**: `dak_contact_schedule`

```sql
CREATE TABLE dak_contact_schedule (
    contact_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id),
    pregnancy_id INTEGER REFERENCES pregnancy(pregnancy_id),
    contact_number INTEGER NOT NULL,
    recommended_gestation_weeks INTEGER,
    contact_date DATE,
    contact_status contact_status,  -- 'scheduled', 'completed', 'missed', 'cancelled'
    provider_notes TEXT,
    dak_contact_id VARCHAR(50),
    contact_type VARCHAR(20),  -- 'ANC', 'PNC', 'Delivery'
    fhir_resource JSONB,
    version_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Workflow**:
1. System calculates recommended contact dates based on gestational age
2. Contacts scheduled for ANC: 8, 12, 16, 20, 24, 28, 32, 36 weeks
3. Post-delivery contacts: 1 day, 6 weeks postpartum
4. Provider updates contact_status after each visit

**Example Contact Schedule**:
```
Gestational Week | Contact Number | Scheduled Date | Status
-----------------|----------------|----------------|----------
8                | 1              | 2024-07-22     | completed
12               | 2              | 2024-08-05     | completed
16               | 3              | 2024-08-19     | completed
20               | 4              | 2024-09-02     | completed
...              | ...            | ...            | ...
```

### 2. DAK Risk Assessment

**Purpose**: Evaluate maternal risk factors and assign risk levels

**Table**: `dak_risk_assessment`

```sql
CREATE TABLE dak_risk_assessment (
    risk_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id),
    encounter_id INTEGER REFERENCES encounter(encounter_id),
    risk_category VARCHAR(50),  -- 'maternal', 'fetal', 'delivery'
    risk_factors TEXT,
    risk_score INTEGER,  -- 1-10 scale
    risk_level risk_level,  -- 'low', 'medium', 'high', 'critical'
    management_plan TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    dak_risk_id VARCHAR(50),
    assessment_date DATE,
    assessor_name VARCHAR(255),
    fhir_resource JSONB,
    version_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Risk Levels**:
- **Low (score 1-3)**: Routine care, standard ANC schedule
- **Medium (score 4-6)**: Enhanced monitoring, additional tests
- **High (score 7-8)**: Specialized care, frequent monitoring
- **Critical (score 9-10)**: Immediate intervention, possible referral

**Risk Factor Examples**:
- Previous C-section
- Advanced maternal age (>35)
- Multiple gestation
- Gestational hypertension
- Anemia
- Malnutrition
- Previous complications

### 3. DAK Quality Indicators

**Purpose**: Track care quality and outcomes

**Table**: `dak_quality_indicators`

```sql
CREATE TABLE dak_quality_indicators (
    indicator_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    patient_id INTEGER REFERENCES patient(patient_id),
    encounter_id INTEGER REFERENCES encounter(encounter_id),
    indicator_code VARCHAR(50) NOT NULL,
    indicator_name VARCHAR(255) NOT NULL,
    indicator_value VARCHAR(255),
    indicator_status VARCHAR(50) DEFAULT 'completed',
    risk_flag VARCHAR(10) DEFAULT 'no',  -- 'yes', 'no'
    decision_support_message TEXT,
    next_visit_schedule DATE,
    dak_indicator_id VARCHAR(50),
    measurement_date DATE,
    target_value VARCHAR(255),
    fhir_resource JSONB,
    version_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Quality Indicators Tracked**:
- ANC Coverage Rate (target: ≥90%)
- Skilled Birth Attendance (target: ≥85%)
- Postnatal Care Coverage (target: ≥80%)
- Iron Supplementation Coverage (target: ≥95%)
- Folic Acid Supplementation (target: ≥90%)
- HIV Testing Coverage (target: ≥95%)
- Syphilis Testing Coverage (target: ≥90%)
- Tetanus Toxoid Coverage (target: ≥85%)
- Maternal Mortality Ratio (target: <5 per 100,000)
- Stillbirth Rate (target: <2 per 1000)
- Low Birth Weight Rate (target: <10%)

### 4. DAK Configuration

**Purpose**: System-wide DAK settings and parameters

**Table**: `dak_configuration`

```sql
CREATE TABLE dak_configuration (
    config_id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(50) UNIQUE NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT,
    config_type VARCHAR(50),  -- 'threshold', 'schedule', 'alert', 'calculation'
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    fhir_resource JSONB,
    version_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Configuration Keys**:
- `anc_visit_schedule`: Recommended weeks for ANC visits
- `bp_threshold_systolic`: Elevated BP threshold
- `bp_threshold_diastolic`: Elevated BP threshold
- `hb_threshold_anemia`: Anemia hemoglobin threshold
- `pnc_schedule`: Postnatal care schedule
- `emergency_referral_criteria`: Referral criteria

---

## 📋 FHIR Implementation

### FHIR Resource Structure

All entities in the system are represented as FHIR R4 resources and stored in both relational tables and JSONB format.

### Core FHIR Resources:

#### 1. Patient Resource

```json
{
  "resourceType": "Patient",
  "id": "patient-demo-001",
  "identifier": [
    {
      "system": "http://health.gov.sl/patient-id",
      "value": "PAT-2024-001"
    }
  ],
  "name": [
    {
      "use": "official",
      "family": "Sesay",
      "given": ["Mariatu"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+232-76-123-456"
    }
  ],
  "gender": "female",
  "birthDate": "1993-08-12",
  "address": [
    {
      "text": "123 Main Street, Freetown, Sierra Leone"
    }
  ]
}
```

#### 2. Encounter Resource

```json
{
  "resourceType": "Encounter",
  "id": "encounter-demo-001",
  "status": "finished",
  "class": {
    "code": "AMB",
    "display": "ambulatory"
  },
  "type": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
          "code": "ANC",
          "display": "Antenatal Care"
        }
      ]
    }
  ],
  "subject": {
    "reference": "Patient/patient-demo-001"
  },
  "period": {
    "start": "2024-07-15T09:00:00Z"
  },
  "serviceProvider": {
    "reference": "Organization/org-demo-001"
  }
}
```

#### 3. Observation Resource

```json
{
  "resourceType": "Observation",
  "id": "obs-demo-001",
  "status": "final",
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "vital-signs",
          "display": "Vital Signs"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "8480-6",
        "display": "Blood Pressure"
      }
    ]
  },
  "subject": {
    "reference": "Patient/patient-demo-001"
  },
  "encounter": {
    "reference": "Encounter/encounter-demo-001"
  },
  "effectiveDateTime": "2024-07-15T09:00:00Z",
  "component": [
    {
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8480-6",
            "display": "Systolic Blood Pressure"
          }
        ]
      },
      "valueQuantity": {
        "value": 120,
        "unit": "mmHg"
      }
    },
    {
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8462-4",
            "display": "Diastolic Blood Pressure"
          }
        ]
      },
      "valueQuantity": {
        "value": 80,
        "unit": "mmHg"
      }
    }
  ]
}
```

#### 4. Condition Resource

```json
{
  "resourceType": "Condition",
  "id": "cond-demo-001",
  "clinicalStatus": {
    "coding": [
      {
        "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
        "code": "active",
        "display": "Active"
      }
    ]
  },
  "category": [
    {
      "coding": [
        {
          "system": "http://snomed.info/sct",
          "code": "maternal",
          "display": "Maternal Condition"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://hl7.org/fhir/sid/icd-10",
        "code": "O09.90",
        "display": "Pregnancy, unspecified, unspecified trimester"
      }
    ]
  },
  "subject": {
    "reference": "Patient/patient-demo-001"
  },
  "encounter": {
    "reference": "Encounter/encounter-demo-001"
  },
  "onsetDateTime": "2024-07-15",
  "severity": {
    "coding": [
      {
        "code": "moderate",
        "display": "Moderate"
      }
    ]
  }
}
```

---

## 🔗 Integration Architecture

### DAK + FHIR Integration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    ANC Visit Workflow                           │
└─────────────────────────────────────────────────────────────────┘

1. Patient Arrives
   ↓
2. Create FHIR Encounter Resource
   ↓
3. Perform DAK Risk Assessment
   ├── Evaluate Risk Factors
   ├── Calculate Risk Score
   └── Assign Risk Level
   ↓
4. Record FHIR Observations
   ├── Vital Signs (BP, Temperature, Pulse)
   ├── Fundal Height
   ├── Fetal Heart Rate
   └── Clinical Measurements
   ↓
5. Document FHIR Conditions
   ├── Pregnancy-Related Conditions
   ├── Complications
   └── Active Problems
   ↓
6. Record FHIR Procedures
   ├── Ultrasound
   ├── Laboratory Tests
   └── Vaccinations
   ↓
7. Prescribe Medications (FHIR MedicationStatement)
   ↓
8. Update DAK Contact Schedule
   ├── Mark Current Visit Complete
   └── Schedule Next Visit
   ↓
9. Update DAK Quality Indicators
   ├── Measure Care Quality
   └── Track Compliance
   ↓
10. Generate DAK Decision Support
    ├── Recommended Actions
    ├── Alerts
    └── Next Steps
```

---

## 🗄️ Database Tables

### DAK Tables

| Table Name | Purpose | Key Fields |
|-----------|---------|-----------|
| `dak_contact_schedule` | Contact scheduling | contact_number, contact_date, contact_status |
| `dak_risk_assessment` | Risk evaluation | risk_level, risk_score, risk_factors |
| `dak_quality_indicators` | Quality metrics | indicator_code, indicator_value, target_value |
| `dak_configuration` | System settings | config_key, config_value, config_type |

### FHIR Tables

| Table Name | Purpose | Key Fields |
|-----------|---------|-----------|
| `patient` | Patient demographics | patient_id, fhir_id, identifier, name |
| `encounter` | Healthcare encounters | encounter_id, fhir_id, encounter_type |
| `observation` | Clinical observations | observation_id, fhir_id, observation_type, value |
| `condition` | Medical conditions | condition_id, fhir_id, condition_code, status |
| `procedure` | Procedures performed | procedure_id, fhir_id, procedure_code |
| `medication_statement` | Medications | medication_statement_id, fhir_id, medication_code |
| `fhir_resources` | All FHIR resources | resource_type, fhir_id, resource_data |

---

## 🔌 API Endpoints

### DAK Endpoints

#### 1. DAK Decision Support

```http
GET /api/dak/decision-support/:patientId
```

**Purpose**: Get DAK-based clinical decision recommendations for a patient

**Response**:
```json
{
  "success": true,
  "data": {
    "patient_id": 1,
    "current_gestation_weeks": 28,
    "risk_level": "medium",
    "recommendations": [
      {
        "priority": "high",
        "action": "Monitor blood pressure closely",
        "rationale": "BP slightly elevated",
        "next_contact": "2024-08-20"
      }
    ],
    "alerts": [],
    "next_visit_date": "2024-08-20"
  }
}
```

#### 2. DAK Scheduling

```http
GET /api/dak/scheduling/:patientId
```

**Purpose**: Get DAK contact schedule for a patient

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "contact_number": 1,
      "recommended_gestation_weeks": 8,
      "contact_date": "2024-07-22",
      "contact_status": "completed"
    },
    {
      "contact_number": 2,
      "recommended_gestation_weeks": 12,
      "contact_date": "2024-08-05",
      "contact_status": "scheduled"
    }
  ]
}
```

#### 3. DAK Quality Metrics

```http
GET /api/dak/quality-metrics
```

**Purpose**: Get DAK quality indicators across all patients

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "indicator_code": "ANC_COV_001",
      "indicator_name": "ANC Coverage Rate",
      "target_value": "90.0%",
      "actual_value": "95.2%",
      "status": "achieved"
    },
    {
      "indicator_code": "SBA_001",
      "indicator_name": "Skilled Birth Attendance",
      "target_value": "85.0%",
      "actual_value": "88.7%",
      "status": "achieved"
    }
  ]
}
```

### FHIR Endpoints

#### 1. Get FHIR Resource

```http
GET /api/fhir/:resourceType/:id
```

**Example**: `GET /api/fhir/Patient/patient-demo-001`

**Response**: FHIR Patient Resource

#### 2. Get All FHIR Resources

```http
GET /api/fhir/:resourceType
```

**Example**: `GET /api/fhir/Observation`

**Response**: Array of FHIR Observation Resources

#### 3. Create FHIR Resource

```http
POST /api/fhir/:resourceType
```

**Example**: `POST /api/fhir/Observation`

**Request Body**: FHIR Observation Resource

**Response**: Created FHIR Resource

---

## 📊 Workflow Examples

### Example 1: Complete ANC Visit

**Scenario**: Patient arrives for 1st ANC visit

**Steps**:

1. **Create Encounter**
   ```http
   POST /api/encounter
   {
     "patient_id": 1,
     "encounter_type": "ANC",
     "encounter_date": "2024-07-15"
   }
   ```

2. **Perform DAK Risk Assessment**
   ```http
   POST /api/dak/risk-assessment
   {
     "patient_id": 1,
     "encounter_id": 1,
     "risk_factors": ["First pregnancy", "Age 31"],
     "risk_score": 2,
     "risk_level": "low"
   }
   ```

3. **Record Observations**
   ```http
   POST /api/observation
   {
     "patient_id": 1,
     "encounter_id": 1,
     "observation_type": "vital_signs",
     "observation_code": "8480-6",
     "value_number": 120
   }
   ```

4. **Update DAK Contact Schedule**
   ```http
   POST /api/dak/contact-schedule
   {
     "patient_id": 1,
     "contact_number": 1,
     "recommended_gestation_weeks": 8,
     "contact_status": "completed"
   }
   ```

### Example 2: Risk Escalation

**Scenario**: Patient develops gestational hypertension at 24 weeks

**Steps**:

1. **Update Risk Assessment**
   ```http
   PUT /api/dak/risk-assessment/1
   {
     "risk_factors": "Gestational hypertension detected",
     "risk_score": 6,
     "risk_level": "medium"
   }
   ```

2. **Record Condition**
   ```http
   POST /api/condition
   {
     "patient_id": 1,
     "condition_code": "O13",
     "condition_name": "Gestational hypertension",
     "status": "active",
     "severity": "moderate"
   }
   ```

3. **Update Management Plan**
   ```http
   PUT /api/dak/risk-assessment/1
   {
     "management_plan": "Monitor BP closely, dietary counseling, consider lifestyle modifications"
   }
   ```

4. **Generate DAK Decision Support**
   ```http
   GET /api/dak/decision-support/1
   ```

**Response**:
```json
{
  "recommendations": [
    {
      "priority": "high",
      "action": "Monitor blood pressure twice daily",
      "rationale": "Gestational hypertension detected",
      "next_visit_date": "2024-08-15"
    }
  ]
}
```

---

## 🎯 Key Benefits

### DAK Benefits:

1. **Standardized Care**: Consistent care delivery across facilities
2. **Risk Management**: Early identification of high-risk pregnancies
3. **Quality Tracking**: Metrics-driven quality improvement
4. **Decision Support**: Evidence-based clinical decisions
5. **Schedule Compliance**: Ensures patients receive care at right times

### FHIR Benefits:

1. **Interoperability**: Data exchange with other systems
2. **Standards Compliance**: International healthcare standards
3. **Flexibility**: Extensible data model
4. **Future-Proof**: Compatible with emerging technologies
5. **Integration**: Easy integration with third-party systems

---

## 📚 References

- **FHIR R4 Specification**: https://www.hl7.org/fhir/
- **WHO ANC Guidelines**: https://www.who.int/publications/i/item/9789240040279
- **DAK Sierra Leone**: Ministry of Health and Sanitation
- **LOINC Codes**: https://loinc.org/
- **SNOMED CT**: https://www.snomed.org/

---

## 🔧 Configuration

### DAK Configuration Examples

```sql
-- ANC Visit Schedule
INSERT INTO dak_configuration (config_key, config_value) VALUES
('anc_visit_weeks', '[8, 12, 16, 20, 24, 28, 32, 36]');

-- BP Thresholds
INSERT INTO dak_configuration (config_key, config_value) VALUES
('bp_threshold_systolic', '140'),
('bp_threshold_diastolic', '90');

-- Hemoglobin Threshold for Anemia
INSERT INTO dak_configuration (config_key, config_value) VALUES
('hb_threshold_anemia', '11.0');
```

### FHIR Resource Storage

Every table includes:
- `fhir_id`: Unique FHIR resource identifier
- `fhir_resource`: Complete FHIR resource in JSONB format
- `version_id`: FHIR version identifier

This dual storage (relational + JSONB) ensures both efficient querying and full FHIR compliance.




