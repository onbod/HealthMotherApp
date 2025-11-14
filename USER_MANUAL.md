# Healthy Mother App - User Manual

## Table of Contents
1. [System Overview](#system-overview)
2. [Prerequisites](#prerequisites)
3. [Installation & Setup](#installation--setup)
4. [Running the System](#running-the-system)
5. [Testing the System](#testing-the-system)
6. [Test Login Credentials](#test-login-credentials)
7. [Troubleshooting](#troubleshooting)
8. [Additional Resources](#additional-resources)

---

## System Overview

The Healthy Mother App is a comprehensive maternal health management system consisting of three main components:

1. **FHIR Backend** (`health-fhir-backend/`) - Node.js/Express API server with PostgreSQL database
   - **Production URL:** `https://health-fhir-backend-production-6ae1.up.railway.app`
   - **Status:** ✅ Deployed and running on Railway
2. **Admin Dashboard** (`Admin_Dashboard/`) - Next.js web application for healthcare administrators
3. **Mobile App** (`lib/`) - Flutter mobile application for patients

> **Note:** This manual uses the **production Railway backend** for testing. The backend and database are fully deployed and operational on Railway.

---

## Prerequisites

Before setting up the system, ensure you have the following installed:

### Required Software
- **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
- **Flutter SDK** (v3.7.0 or higher) - [Download](https://flutter.dev/docs/get-started/install)
- **pnpm** or **npm** - Package managers
- **Git** - Version control

### Development Tools (Optional)
- **VS Code** or your preferred code editor
- **Android Studio** or **Xcode** (for mobile app development)

---

## Installation & Setup

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd HealthMotherApp
```

### Step 2: Set Up the Admin Dashboard

1. **Navigate to Admin Dashboard Directory:**
   ```bash
   cd Admin_Dashboard
   ```

2. **Install Dependencies:**
   ```bash
   pnpm install
   # or
   npm install
   ```

3. **Configure Environment Variables:**
   
   Create `.env.local` file:
   ```env
   NEXT_PUBLIC_API_URL=https://health-fhir-backend-production-6ae1.up.railway.app
   ```

### Step 3: Set Up the Mobile App

1. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

2. **Verify Configuration:**
   
   The mobile app is already configured to use the production Railway backend. The backend URL is set in `lib/core/config.dart` to:
   `https://health-fhir-backend-production-6ae1.up.railway.app`

---

## Running the System

> **Important:** The **production Railway backend** is already deployed and running. You only need to run the Admin Dashboard locally.

### Production Backend (Railway) ✅

The backend is deployed and running on Railway:
- **Production URL:** `https://health-fhir-backend-production-6ae1.up.railway.app`
- **Status:** ✅ Active and operational
- **Database:** ✅ PostgreSQL hosted on Railway

**Verify Backend is Running:**
```bash
curl https://health-fhir-backend-production-6ae1.up.railway.app/healthz
```

### Running the Admin Dashboard

1. **Start the Admin Dashboard:**
   ```bash
   cd Admin_Dashboard
   pnpm dev
   # or
   npm run dev
   ```

2. **Access the Dashboard:**
   - Open your browser and visit: `http://localhost:3000` (or next available port)
   - The dashboard will automatically open in your default browser

3. **Expected Output:**
   ```
   ▲ Next.js 15.2.4
   - Local:        http://localhost:3000
   - Ready in 2.5s
   ```

### Running the Mobile App

1. **Start Flutter App:**
   ```bash
   # From project root
   flutter run
   ```

2. **Select Device:**
   - Choose from available devices (emulator, physical device, or web)
   - For Android: `flutter run -d android`
   - For iOS: `flutter run -d ios`
   - For Web: `flutter run -d chrome`

3. **Expected Output:**
   ```
   Launching lib/main.dart on [device] in debug mode...
   Running Gradle task 'assembleDebug'...
   ```

---

## Testing the System

> **Using Production Railway Backend:** All test examples below use the production Railway URL: `https://health-fhir-backend-production-6ae1.up.railway.app`

### Testing the Backend

#### 1. Health Check Endpoints

```bash
# Basic health check (no database required)
curl https://health-fhir-backend-production-6ae1.up.railway.app/healthz

# Application health check
curl https://health-fhir-backend-production-6ae1.up.railway.app/health

# Database connection test
curl https://health-fhir-backend-production-6ae1.up.railway.app/db-test
```

#### 2. Test Authentication Endpoints

**Patient Direct Login:**
```bash
curl -X POST https://health-fhir-backend-production-6ae1.up.railway.app/login/direct \
  -H "Content-Type: application/json" \
  -d '{
    "given": "Mariama",
    "family": "Sesay",
    "identifier": "ANC-2024-0125"
  }'
```

**Admin Login:**
```bash
curl -X POST https://health-fhir-backend-production-6ae1.up.railway.app/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ibrahimswaray430@gmail.com",
    "password": "dauda2019"
  }'
```

**OTP Request (for testing):**
```bash
curl -X POST https://health-fhir-backend-production-6ae1.up.railway.app/login/request-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+23288054388"
  }'
```

**OTP Verification:**
```bash
curl -X POST https://health-fhir-backend-production-6ae1.up.railway.app/login/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+23288054388",
    "otp": "123456"
  }'
```

#### 3. Test FHIR Endpoints

```bash
# Get FHIR CapabilityStatement
curl https://health-fhir-backend-production-6ae1.up.railway.app/metadata

# Search for patients
curl https://health-fhir-backend-production-6ae1.up.railway.app/fhir/Patient?name=Mariama

# Get patient by ID
curl https://health-fhir-backend-production-6ae1.up.railway.app/fhir/Patient/[patient_id]
```

> **Note:** Replace `[patient_id]` with an actual patient ID from your database.

### Testing the Admin Dashboard

1. **Access Login Page:**
   - Navigate to `http://localhost:3000` (or the port shown in terminal)

2. **Test Admin Login:**
   - Use the test credentials (see [Test Login Credentials](#test-login-credentials))
   - After successful login, you should see the dashboard

3. **Test Features:**
   - Navigate through different sections (Patients, Referrals, Reports, etc.)
   - Verify data is loading from the production Railway backend

### Testing the Mobile App

1. **Launch the App:**
   ```bash
   flutter run
   ```
   Select your device (emulator, physical device, or web)

2. **Test Patient Login:**
   - Use the test patient credentials (see [Test Login Credentials](#test-login-credentials))
   - Test both OTP and direct login methods

3. **Test Features:**
   - Navigate through app screens
   - Test pregnancy tracking, medication reminders, health education, and emergency contacts

---

## Test Login Credentials

### Admin Dashboard Login

**App Admin Account:**
- **Email/Username:** `ibrahimswaray430@gmail.com`
- **Password:** `dauda2019`
- **Role:** App Admin (Full Access)

**Note:** Additional admin accounts can be created in the database. See database setup section.

### Mobile App - Patient Login

#### Method 1: Direct Login (Name + Identifier)

**Test Patient 1:**
- **Name:** `Mariama Sesay`
- **Client Number/Identifier:** `ANC-2024-0125`
- **Phone:** `+23288054388` or `088054388`
- **National ID:** (if available in database)

#### Method 2: OTP Login (Phone Number)

**Test Patient 1 (OTP Method):**
- **Phone Number:** `+23288054388` or `088054388`
- **OTP Code:** `123456` (for testing only)
- **Note:** OTP expires after 5 minutes

#### Method 3: Direct Login (National ID)

If the patient has a national ID in the database:
- **National ID:** (as stored in database)
- **Name:** `Mariama Sesay`

### Creating Additional Test Users

#### Add Test Patient via SQL:

```sql
INSERT INTO patient (
    identifier, 
    first_name, 
    last_name, 
    name, 
    phone, 
    gender, 
    birth_date,
    national_id
) VALUES (
    'ANC-2024-0126',
    'Fatima',
    'Kamara',
    'Fatima Kamara',
    '+23288012345',
    'female',
    '1990-05-20',
    'SL123456789'
);
```

#### Add Test Admin via SQL:

```sql
-- First, hash the password using bcrypt
-- Password: test123
-- Hash: $2b$10$... (generate using Node.js bcrypt)

INSERT INTO admins (
    username,
    email,
    password_hash,
    full_name,
    role
) VALUES (
    'testadmin',
    'testadmin@healthymama.com',
    '$2b$10$...', -- Replace with actual bcrypt hash
    'Test Administrator',
    'admin'
);
```

**To generate password hash:**
```javascript
const bcrypt = require('bcrypt');
const hash = await bcrypt.hash('your_password', 10);
console.log(hash);
```

---

## Troubleshooting

### Common Issues and Solutions

#### Admin Dashboard Issues

**Problem: Cannot Connect to Backend**
```
Error: Failed to fetch
```

**Solution:**
1. Verify production Railway backend is accessible:
   ```bash
   curl https://health-fhir-backend-production-6ae1.up.railway.app/healthz
   ```
2. Check `.env.local` has: `NEXT_PUBLIC_API_URL=https://health-fhir-backend-production-6ae1.up.railway.app`
3. Check browser console for detailed error messages

**Problem: Login Fails**
```
Error: Invalid credentials
```

**Solution:**
1. Verify admin account exists in database
2. Check password hash is correct
3. Verify backend `/admin/login` endpoint is working
4. Check browser network tab for API response

#### Mobile App Issues

**Problem: App Cannot Connect to Backend**
```
Error: SocketException: Failed host lookup
```

**Solution:**
1. Verify internet connection (production backend requires internet)
2. Check Railway backend status:
   ```bash
   curl https://health-fhir-backend-production-6ae1.up.railway.app/healthz
   ```

**Problem: OTP Not Received**
```
Error: OTP not found or expired
```

**Solution:**
1. For testing, OTP is always `123456`
2. Check backend console for OTP log message
3. Verify phone number format matches database
4. OTP expires after 5 minutes

**Problem: Flutter Build Errors**
```
Error: Could not resolve dependencies
```

**Solution:**
1. Clean Flutter cache:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Update Flutter:
   ```bash
   flutter upgrade
   ```

3. Check `pubspec.yaml` for dependency conflicts


---

## Additional Resources

### Documentation Files
- **Main README:** `README.md` - Comprehensive project overview
- **Backend README:** `health-fhir-backend/README.md` - Backend-specific documentation
- **Admin Dashboard README:** `Admin_Dashboard/readme.md` - Dashboard documentation
- **Railway Deployment:** `health-fhir-backend/RAILWAY_DEPLOYMENT.md` - Production deployment guide

### API Documentation
- **Base URL:** `https://health-fhir-backend-production-6ae1.up.railway.app`
- **Health Check:** `https://health-fhir-backend-production-6ae1.up.railway.app/healthz`
- **FHIR Metadata:** `https://health-fhir-backend-production-6ae1.up.railway.app/metadata`

### Useful Commands

**Admin Dashboard:**
```bash
cd Admin_Dashboard && pnpm dev
```

**Mobile App:**
```bash
flutter run
flutter devices  # List available devices
```

### Support

For additional help:
1. Check the main `README.md` for detailed architecture information
2. Check browser developer console for frontend errors
3. Verify Railway backend is accessible: `curl https://health-fhir-backend-production-6ae1.up.railway.app/healthz`
4. Contact the development team or create an issue in the repository

---

## Quick Start Checklist

Use this checklist to ensure everything is set up correctly for testing with the production Railway backend:

### Production Backend (Railway) ✅
- [x] Backend deployed and running on Railway
- [x] Production URL accessible: `https://health-fhir-backend-production-6ae1.up.railway.app`
- [x] Health check passes: `/healthz`
- [x] Database connected and operational
- [x] Test admin account exists in Railway database
- [x] Test patient account exists in Railway database

### Admin Dashboard
- [ ] Admin Dashboard dependencies installed (`pnpm install`)
- [ ] Admin Dashboard `.env.local` configured with production URL:
  ```env
  NEXT_PUBLIC_API_URL=https://health-fhir-backend-production-6ae1.up.railway.app
  ```
- [ ] Admin Dashboard running and accessible
- [ ] Can login with test admin credentials
- [ ] Data loads from production Railway backend

### Mobile App
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Mobile app configured to use production Railway backend
- [ ] Verify `lib/core/config.dart` returns `productionUrl`
- [ ] App can connect to production backend
- [ ] Can login with test patient credentials
- [ ] Data syncs with production Railway backend


---

**Last Updated:** 2024
**Version:** 1.0.0

