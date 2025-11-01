# HealthyMama System Architecture

## 📐 Overview

HealthyMama is a comprehensive mobile health application for Sierra Leone focusing on Antenatal Care (ANC), delivery, and postnatal care for pregnant women. The system follows FHIR R4 standards and implements DAK (District Assessment Kit) guidelines.

---

## 🏗️ System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER LAYER                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  Mobile App (Flutter)              │  Admin Dashboard (Next.js)           │
│  - Patient Authentication          │  - Clinician Management                │
│  - ANC Visits Tracking             │  - Patient Monitoring                  │
│  - Appointment Scheduling          │  - Analytics & Reports                 │
│  - Medication Reminders            │  - Data Quality Dashboard             │
│  - Health Education                │  - Real-time Notifications             │
└────────────┬───────────────────────┴─────────────┬──────────────────────────┘
             │                                      │
             │  REST API Calls                     │
             │  JWT Authentication                  │
             │                                      │
┌────────────▼──────────────────────────────────────▼──────────────────────────┐
│                        API GATEWAY LAYER                                       │
├───────────────────────────────────────────────────────────────────────────────┤
│  Backend API (Node.js/Express)                                                  │
│  - Authentication Endpoints                                                    │
│  - Patient Management                                                          │
│  - ANC Visit Tracking                                                          │
│  - Delivery & Neonatal Care                                                    │
│  - Postnatal Care                                                              │
│  - DAK Decision Support                                                        │
│  - FHIR R4 Compliance                                                          │
└────────────┬──────────────────────────────────────────────────────────────────┘
             │
             │  PostgreSQL Queries
             │
┌────────────▼──────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                             │
├───────────────────────────────────────────────────────────────────────────────┤
│  Railway PostgreSQL Database                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Core Tables                                                          │    │
│  │ - organization                                                      │    │
│  │ - patient                                                           │    │
│  │ - pregnancy                                                         │    │
│  │ - encounter                                                         │    │
│  │ - anc_visit                                                         │    │
│  │ - delivery                                                          │    │
│  │ - neonate                                                           │    │
│  │ - postnatal_care                                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ Clinical Data Tables                                                │    │
│  │ - observation                                                       │    │
│  │ - condition                                                         │    │
│  │ - procedure                                                         │    │
│  │ - medication_statement                                              │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ DAK-Specific Tables                                                 │    │
│  │ - dak_contact_schedule                                              │    │
│  │ - dak_risk_assessment                                               │    │
│  │ - dak_quality_indicators                                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                           AUTHENTICATION FLOW                                  │
└────────────────────────────────────────────────────────────────────────────────┘

Mobile App                     Backend API                 Database
    │                               │                           │
    │─── Request OTP ───────────────▶                          │
    │                               │                           │
    │                               │─── Fetch User ────────────▶
    │                               │                           │
    │◀── Return OTP ───────────────│                           │
    │                               │                           │
    │─── Verify OTP + Code ─────────▶                          │
    │                               │                           │
    │                               │─── Validate ──────────────▶
    │                               │                           │
    │◀── JWT Token ─────────────────│                           │
    │                               │                           │
    │─── Store Token Securely       │                           │
    │                               │                           │

┌────────────────────────────────────────────────────────────────────────────────┐
│                           DATA FETCHING FLOW                                   │
└────────────────────────────────────────────────────────────────────────────────┘

Mobile App                     Backend API                 Database
    │                               │                           │
    │─── GET /user/session ────────▶                          │
    │   + JWT Token                │                           │
    │                               │                           │
    │                               │─── Validate JWT ─────────▶
    │                               │                           │
    │                               │◀── User Data ─────────────│
    │                               │                           │
    │                               │─── Fetch Pregnancy ───────▶
    │                               │                           │
    │                               │◀── Pregnancy Data ────────│
    │                               │                           │
    │                               │─── Fetch ANC Visits ──────▶
    │                               │                           │
    │                               │◀── ANC Visit Data ────────│
    │                               │                           │
    │                               │─── Fetch Delivery ────────▶
    │                               │                           │
    │                               │◀── Delivery Data ─────────│
    │                               │                           │
    │                               │─── Fetch Postnatal ───────▶
    │                               │                           │
    │                               │◀── Postnatal Data ────────│
    │                               │                           │
    │◀── Complete Session Data ─────│                           │
    │                               │                           │
```

---

## 🎯 Component Architecture

### **1. Mobile Application (Flutter)**

#### **Folder Structure:**
```
lib/
├── auth/                      # Authentication screens
│   ├── auth_screen.dart      # OTP verification
│   ├── login_screen.dart     # Phone login
│   ├── main_login_screen.dart # Main login with identifier
│   └── phone_auth_screen.dart
│
├── core/                     # Core configuration
│   └── config.dart          # API configuration
│
├── features/                 # Feature modules
│   ├── home_screen.dart
│   ├── anc_visit_screen.dart
│   ├── appointments_screen.dart
│   └── pin_setup_screen.dart
│
├── providers/                # State management
│   └── user_session_provider.dart
│
├── services/                 # Service layer
│   ├── auth_service.dart
│   └── api_service.dart
│
├── widgets/                  # Reusable widgets
│   └── global_navigation.dart
│
└── main.dart                 # App entry point
```

#### **Key Features:**
- **Authentication**: Multiple methods (Phone, Identifier, NIN)
- **ANC Tracking**: Visit history and upcoming appointments
- **Notifications**: Medication reminders and appointment alerts
- **Offline Support**: Secure local storage
- **FHIR Compliance**: Healthcare data standards

### **2. Backend API (Node.js/Express)**

#### **Technology Stack:**
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL (Railway)
- **Authentication**: JWT
- **Standards**: FHIR R4

#### **API Endpoints:**

```
Authentication Endpoints:
├── POST /login/request-otp          # Request OTP
├── POST /login/verify-otp           # Verify OTP
└── POST /login/direct               # Direct login

Patient Management:
├── GET  /patient                    # Get all patients
├── GET  /patient/:id                # Get patient by ID
└── GET  /user/session               # Get user session

ANC Visits:
├── GET  /anc_visit                  # Get all ANC visits
├── GET  /anc_visit/:id              # Get visit by ID
└── POST /anc_visit                  # Create new visit

Delivery & Neonatal:
├── GET  /delivery                   # Get all deliveries
├── GET  /neonate                    # Get all neonates
└── GET  /postnatal_care              # Get postnatal visits

Clinical Data:
├── GET  /observation                # Get observations
├── GET  /condition                  # Get conditions
├── GET  /procedure                  # Get procedures
└── GET  /medication_statement       # Get medications

DAK Features:
├── GET  /dak/decision-support/:id   # DAK decision support
├── GET  /dak/scheduling/:id         # DAK scheduling
└── GET  /dak/quality-metrics        # Quality indicators
```

### **3. Database Schema (PostgreSQL)**

#### **Core Tables:**

**patient**
- Stores patient demographic data
- Fields: patient_id, first_name, last_name, phone, identifier, national_id, address, etc.
- Links to: pregnancy, encounter

**pregnancy**
- Tracks pregnancy information
- Fields: pregnancy_id, patient_id, lmp_date, edd_date, gravida, parity, risk_factors
- Links to: patient, delivery

**encounter**
- Records healthcare encounters
- Fields: encounter_id, patient_id, organization_id, encounter_date, encounter_type
- Links to: patient, organization, anc_visit

**anc_visit**
- ANC visit details
- Fields: anc_visit_id, encounter_id, pregnancy_id, visit_number, visit_date, gestational_age_weeks
- Links to: encounter, pregnancy

**delivery**
- Delivery information
- Fields: delivery_id, pregnancy_id, delivery_date, delivery_mode, outcome
- Links to: pregnancy, neonate

**neonate**
- Neonatal information
- Fields: neonate_id, delivery_id, gender, birth_weight, apgar_scores
- Links to: delivery

**postnatal_care**
- Postnatal visits
- Fields: postnatal_care_id, delivery_id, pnc_visit_number, visit_date
- Links to: delivery

**observation**
- Clinical observations
- Fields: observation_id, patient_id, encounter_id, observation_type, value_number

**condition**
- Medical conditions
- Fields: condition_id, patient_id, encounter_id, condition_code, status, onset_date

**procedure**
- Medical procedures
- Fields: procedure_id, patient_id, encounter_id, procedure_code, performed_date

**medication_statement**
- Medications prescribed
- Fields: medication_statement_id, patient_id, encounter_id, medication_code, dosage

**dak_contact_schedule**
- Patient contact scheduling
- Fields: dak_contact_id, patient_id, pregnancy_id, contact_number, contact_date

**dak_risk_assessment**
- Risk assessments
- Fields: risk_assessment_id, patient_id, encounter_id, risk_level, risk_factors

**dak_quality_indicators**
- Quality metrics
- Fields: indicator_id, patient_id, encounter_id, indicator_code, indicator_value

---

## 🔐 Security Architecture

### **Authentication Flow:**

```
1. User provides credentials (phone/identifier/NIN)
2. Backend generates OTP and stores temporarily
3. OTP sent to user (in production: SMS/Email)
4. User verifies OTP
5. Backend generates JWT token with user data
6. Mobile app stores JWT securely (FlutterSecureStorage)
7. JWT used for subsequent API calls
8. JWT validated on each request
```

### **Security Measures:**

- **JWT Tokens**: Stateless authentication
- **Secure Storage**: FlutterSecureStorage for mobile
- **HTTPS**: All API communications encrypted
- **Token Expiry**: 2-hour token lifetime
- **Password Hashing**: Bcrypt for admin passwords
- **CORS**: Configured for specific origins
- **Input Validation**: All API inputs validated

---

## 📊 Data Architecture

### **Relationships:**

```
organization (1) ──(N)─→ encounter
patient (1) ──(N)─→ pregnancy
pregnancy (1) ──(N)─→ anc_visit
pregnancy (1) ──(1)─→ delivery
delivery (1) ──(N)─→ neonate
delivery (1) ──(N)─→ postnatal_care
encounter (1) ──(N)─→ observation
encounter (1) ──(N)─→ condition
encounter (1) ──(N)─→ procedure
encounter (1) ──(N)─→ medication_statement
```

### **Data Flow:**

```
1. Patient Registration → patient table
2. Pregnancy Confirmation → pregnancy table
3. ANC Visits → anc_visit table
4. Delivery Event → delivery + neonate tables
5. Postnatal Care → postnatal_care table
6. Clinical Observations → observation table
7. Medical Conditions → condition table
8. Procedures → procedure table
9. Medications → medication_statement table
```

---

## 🚀 Deployment Architecture

### **Frontend:**
- **Mobile App**: Android/iOS via Flutter
- **Admin Dashboard**: Vercel deployment

### **Backend:**
- **API Server**: Railway Platform
- **Database**: Railway PostgreSQL

### **Infrastructure:**

```
                    ┌─────────────────┐
                    │  Vercel CDN     │
                    │  Admin Dashboard│
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Railway API    │
                    │  Node.js Server │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  PostgreSQL DB  │
                    │   Railway Host  │
                    └─────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Mobile Devices │
                    │   (Flutter App) │
                    └─────────────────┘
```

---

## 🔄 Integration Points

### **1. FHIR R4 Compliance:**
- All patient data follows FHIR standards
- FHIR resources stored in database
- FHIR IDs generated for all entities
- FHIR JSON structure maintained

### **2. DAK Guidelines:**
- DAK contact schedule implemented
- DAK risk assessment tracking
- DAK quality indicators monitoring
- Decision support algorithms

### **3. Third-Party Services:**
- **SMS Service**: OTP delivery (production)
- **Email Service**: Notifications (production)
- **Push Notifications**: Firebase (production)
- **Analytics**: Usage tracking (production)

---

## 📈 Scalability Considerations

### **Current Capacity:**
- **Database**: ~1000 patients supported
- **Concurrent Users**: ~100 simultaneous users
- **API Throughput**: ~1000 requests/minute

### **Future Enhancements:**
- **Caching**: Redis for session management
- **Load Balancing**: Multiple API instances
- **CDN**: Static asset optimization
- **Message Queue**: Background job processing
- **Monitoring**: Application performance monitoring

---

## 🛠️ Development Workflow

```
1. Feature Development
   ↓
2. Local Testing (Flutter + Node.js)
   ↓
3. Database Migration (PostgreSQL)
   ↓
4. API Testing (Postman/curl)
   ↓
5. Mobile App Testing (Emulator/Device)
   ↓
6. Code Review
   ↓
7. Railway Deployment
   ↓
8. Production Testing
   ↓
9. Release
```

---

## 📝 Technology Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| Mobile App | Flutter | 3.x |
| Backend API | Node.js | 18.x |
| Framework | Express.js | 4.x |
| Database | PostgreSQL | 15.x |
| Authentication | JWT | 9.x |
| Standards | FHIR R4 | R4 |
| Deployment | Railway | Latest |
| Admin UI | Next.js | 14.x |

---

This architecture provides a robust, scalable, and standards-compliant healthcare system for Sierra Leone's maternal health needs.
