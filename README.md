# Healthy Mother APP

A comprehensive maternal health system with FHIR-compliant backend, Next.js admin dashboard, and Flutter mobile app. The system is fully SMART, FHIR, and DAK compliant for healthcare interoperability.

## Team Members

*   Ibrahim Success Swaray
*   Peter George
*   Aisha Suma
*   Joyce Thomas
*   Emmanuel Sahr Dauda

## Project Architecture

This project consists of three main components:

### 🏥 **FHIR Backend** (`health-fhir-backend/`)
- **Node.js/Express.js** server with PostgreSQL database
- **FHIR R4 (4.0.1)** compliant REST API
- **SMART on FHIR** authentication and authorization
- **DAK (District Health Information System)** integration
- **JWT-based** authentication for patients and administrators
- **OTP verification** for patient login
- **Decision support alerts** based on ANC visit data
- **FHIR CapabilityStatement** and standard endpoints

### 🖥️ **Admin Dashboard** (`healthapp/`)
- **Next.js 14** with TypeScript
- **Tailwind CSS** for modern UI
- **Admin authentication** with username/email and password
- **Patient data visualization** and management
- **FHIR resource** browsing and search
- **Real-time** dashboard with metrics and indicators
- **Responsive design** for desktop and mobile

### 📱 **Mobile App** (`lib/`)
- **Flutter** mobile application
- **Patient-focused** interface
- **Pregnancy tracking** and monitoring
- **Medication reminders** and notifications
- **Health education** content and videos
- **Emergency contacts** and reporting
- **AI chatbot** for pregnancy-related questions

### 🖥️ **Admin Dashboard** (`Admin_Dashboard/`)
- **Next.js 14** with TypeScript and modern React
- **Tailwind CSS** and **Shadcn/UI** for beautiful, responsive design
- **Role-based authentication** (App Admin and Clinician roles)
- **Patient management** with comprehensive patient records
- **Real-time analytics** dashboard with key metrics and trends
- **Referral tracking** and management system
- **Notification system** for patient communication
- **Health education hub** for managing tips, nutrition, and videos
- **Whistleblower reports** management with filtering and responses
- **PostgreSQL integration** for persistent data storage
- **Database management** tools with sync status and configuration
- **FHIR resource browser** for healthcare data standards
- **Mobile-responsive** design for all devices

## Features

### 🔐 **Authentication & Security**
- **Patient Login**: OTP verification via phone number or name/client number
- **Admin Login**: Username/email and password authentication
- **JWT Tokens**: Secure session management
- **Role-based Access**: Patient and admin role separation
- **PIN Code**: 4-digit security for mobile app users

### 🏠 **Core Features**

#### **Mobile App Features**
- 📅 **Pregnancy Tracker** – Monitor pregnancy progress and milestones
- 🧾 **Visit Records** – View past and upcoming antenatal visits
- 💊 **Medication Reminders** – Set and receive reminders for prescribed medications
- 📚 **Resource Hub** – Access health tips, nutrition guidance, and videos
- ☎️ **Emergency Contacts** – Quick access to emergency numbers
- 📝 **Report Issues** – Submit reports or feedback directly
- 🔔 **Smart Notifications** – Timely reminders for visits and medications
- 🤖 **AI Chatbot** – Real-time pregnancy-related Q&A

#### **Admin Dashboard Features**
- 👥 **Patient Management** – View and manage patient records
- 📊 **Analytics Dashboard** – Real-time metrics and indicators
- 🏥 **Facility Management** – Manage healthcare facilities
- 📈 **ANC Indicators** – Track antenatal care metrics
- 🔍 **FHIR Resource Browser** – Search and view FHIR resources
- 📋 **Reports & Analytics** – Comprehensive reporting tools

### 🏥 **Healthcare Standards Compliance**

#### **FHIR (Fast Healthcare Interoperability Resources)**
- **R4 (4.0.1)** compliant REST API
- **CapabilityStatement** endpoint (`/metadata`)
- **Resource CRUD** operations for Patient, Encounter, Observation, Procedure
- **Search functionality** with name and patient parameters
- **Bundle responses** for search results
- **OperationOutcome** for error handling

#### **SMART on FHIR**
- **OAuth 2.0** compatible authentication
- **JWT token** management
- **Scope-based** authorization
- **Launch context** support

#### **DAK (District Health Information System)**
- **Business process** alignment
- **Decision support** logic (ANC.DT.01-14)
- **Indicator metrics** tracking
- **Risk assessment** algorithms
- **Preventive care** guidelines
- **Scheduling logic** (ANC.S.01-05)

### 📊 **Data Management**
- **PostgreSQL** database with JSONB support
- **Relational tables** for structured data
- **FHIR resources** stored as JSONB
- **Cross-referenced** patient data
- **Audit trails** for decision support
- **Backup and recovery** procedures

## Getting Started

### Prerequisites

*   [Node.js](https://nodejs.org/) (v16 or higher)
*   [PostgreSQL](https://www.postgresql.org/) (v12 or higher)
*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   [Next.js](https://nextjs.org/) (included in healthapp/)
*   A code editor like [VS Code](https://code.visualstudio.com/)

### Installation & Running

1.  **Clone the repository:**
    ```sh
    git clone <repository-url>
    cd healthymamaapp
    ```

2.  **Set up the FHIR Backend:**
    ```sh
    cd health-fhir-backend
    npm install
    ```
    
    **For Local Development:**
    - Create database: `healthmother`
    - Update connection in `index.js`:
      ```javascript
      const pool = new Pool({
        user: 'postgres',
        host: 'localhost',
        database: 'healthmother',
        password: 'your_password',
        port: 5432,
      });
      ```
    
    **For Railway Deployment:**
    - The backend is deployed on Railway at: `https://health-fhir-backend-production.up.railway.app`
    - Database connection is automatically configured via Railway environment variables
    - No local setup required for production use
    
    **Run the backend locally:**
    ```sh
    node index.js
    ```
    Backend will run on `http://localhost:3000`

3.  **Set up the Admin Dashboard:**
    ```sh
    cd healthapp
    npm install
    ```
    
    **Run the dashboard:**
    ```sh
    npm run dev
    ```
    Dashboard will run on `http://localhost:3001`

4.  **Set up the Admin Dashboard:**
    ```bash
    cd Admin_Dashboard
    pnpm install
    # or
    npm install
    ```
    
    **Configure environment variables:**
    Create a `.env.local` file in the Admin_Dashboard directory:
    ```env
    # For Railway deployment (recommended)
    DATABASE_URL=postgresql://user:password@localhost:5432/healthmother
    NEXT_PUBLIC_API_URL=https://health-fhir-backend-production.up.railway.app
    
    # For local development
    # DATABASE_URL=postgresql://user:password@localhost:5432/healthmother
    # NEXT_PUBLIC_API_URL=http://localhost:3000
    ```
    
    **Run the Admin Dashboard (using Git Bash):**
    ```bash
    # Open Git Bash in the Admin_Dashboard directory
    pnpm dev
    # or
    npm run dev
    ```
    Dashboard will run on `http://localhost:3000` (or next available port)

5.  **Set up the Mobile App:**
    ```sh
    flutter pub get
    ```
    
    **Run the mobile app:**
    ```sh
    flutter run
    ```

### Database Setup

The system uses PostgreSQL with a comprehensive schema designed for maternal health management, fully aligned with healthcare interoperability standards.

#### **Database Schema Overview**

The database schema is structured around the maternal health journey, from pregnancy registration through postnatal care. It follows a **patient-centric approach** with **FHIR-compliant data structures** and supports **SMART on FHIR** authentication and **DAK (District Health Information System)** decision support logic.

**Key Design Principles:**
- **FHIR R4 Compliance**: Uses JSONB for FHIR resource storage and complex data types
- **SMART Integration**: Supports OAuth 2.0 flows and JWT token management
- **DAK Alignment**: Implements ANC indicators and decision support algorithms
- **Scalable Architecture**: Proper normalization with foreign key relationships
- **Audit Trail**: Comprehensive timestamp tracking for all records

#### **Alignment with Healthcare Standards**

**🏥 FHIR (Fast Healthcare Interoperability Resources)**
- **Resource Storage**: `fhir_resources` table stores complete FHIR resources as JSONB
- **HumanName Format**: Patient names stored in FHIR HumanName format with `use`, `given`, and `family` fields
- **Address Format**: Patient addresses follow FHIR Address structure
- **Resource Types**: Supports Patient, Encounter, Observation, Procedure resources
- **Search Capability**: FHIR-compliant search with name and patient parameters

**🔐 SMART on FHIR**
- **Authentication**: JWT token-based authentication for patients and administrators
- **Authorization**: Role-based access control (patient vs admin)
- **OAuth 2.0**: Compatible with SMART launch sequences
- **Scope Management**: Supports different permission levels
- **Session Management**: Secure token storage and validation

**📊 DAK (District Health Information System)**
- **ANC Indicators**: Tracks all 14 ANC indicators (ANC.DT.01-14)
- **Decision Support**: Implements ANC decision support logic (ANC.DT.01-14)
- **Risk Assessment**: Algorithms for maternal and fetal risk assessment
- **Scheduling Logic**: Supports ANC scheduling guidelines (ANC.S.01-05)
- **Quality Metrics**: Comprehensive data for quality improvement
- **Preventive Care**: Guidelines for immunizations, supplements, and prophylaxis

#### **Data Flow Architecture**

```
Patient Registration → Pregnancy Tracking → ANC Visits → Delivery → Postnatal Care
       ↓                    ↓                ↓           ↓           ↓
   FHIR Patient      FHIR Encounter   FHIR Observation  FHIR Procedure  FHIR Observation
       ↓                    ↓                ↓           ↓           ↓
   SMART Auth        DAK Indicators   Decision Support  Risk Assessment  Quality Metrics
```

The system uses PostgreSQL with the following schema:

#### Core Tables

**1. `patient` - Patient Information**
```sql
CREATE TABLE patient (
    id SERIAL PRIMARY KEY,
    client_number VARCHAR(50) UNIQUE NOT NULL,
    name JSONB NOT NULL, -- FHIR HumanName format
    phone VARCHAR(20),
    nin_number VARCHAR(50),
    birth_date DATE,
    address JSONB, -- FHIR Address format
    gender VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**2. `pregnancy` - Pregnancy Records**
```sql
CREATE TABLE pregnancy (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patient(id),
    lmp DATE, -- Last Menstrual Period
    edd DATE, -- Expected Due Date
    pregnancy_number INTEGER,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**3. `anc_visit` - Antenatal Care Visits**
```sql
CREATE TABLE anc_visit (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patient(id),
    visit_number INTEGER,
    visit_date DATE,
    gestational_age_weeks INTEGER,
    blood_pressure VARCHAR(20),
    weight DECIMAL(5,2),
    hemoglobin DECIMAL(4,1),
    urine_test VARCHAR(50),
    hiv_test VARCHAR(20),
    syphilis_test VARCHAR(20),
    tetanus_toxoid INTEGER,
    iron_folate_tablets INTEGER,
    malaria_prophylaxis VARCHAR(50),
    complications TEXT,
    next_visit_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**4. `delivery` - Delivery Information**
```sql
CREATE TABLE delivery (
    id SERIAL PRIMARY KEY,
    pregnancy_id INTEGER REFERENCES pregnancy(id),
    delivery_date DATE,
    delivery_mode VARCHAR(50), -- vaginal, cesarean, etc.
    delivery_place VARCHAR(100),
    complications TEXT,
    blood_loss VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**5. `neonate` - Newborn Information**
```sql
CREATE TABLE neonate (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES delivery(id),
    gender VARCHAR(10),
    birth_weight DECIMAL(4,2),
    apgar_score INTEGER,
    resuscitation_required BOOLEAN,
    congenital_anomalies TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**6. `postnatal_visit` - Postnatal Care Visits**
```sql
CREATE TABLE postnatal_visit (
    id SERIAL PRIMARY KEY,
    delivery_id INTEGER REFERENCES delivery(id),
    visit_date DATE,
    visit_number INTEGER,
    mother_condition TEXT,
    baby_condition TEXT,
    breastfeeding_status VARCHAR(50),
    family_planning VARCHAR(100),
    next_visit_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**7. `admin` - Administrator Accounts**
```sql
CREATE TABLE admin (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**8. `fhir_resources` - FHIR Resource Storage**
```sql
CREATE TABLE fhir_resources (
    id SERIAL PRIMARY KEY,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(100) NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(resource_type, resource_id)
);
```

**9. `chat_message` - Chat System**
```sql
CREATE TABLE chat_message (
    id SERIAL PRIMARY KEY,
    chat_id VARCHAR(100) NOT NULL,
    sender_id INTEGER,
    sender_type VARCHAR(20), -- 'patient', 'admin', 'system'
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Database Setup Commands

1. **Create the database:**
   ```sql
   CREATE DATABASE healthmother;
   ```

2. **Create admin user:**
   ```sql
   INSERT INTO admin (username, password_hash, email, name, role) 
   VALUES ('admin', '$2b$10$...', 'admin@healthymama.com', 'System Administrator', 'admin');
   ```

3. **Sample patient data:**
   ```sql
   INSERT INTO patient (client_number, name, phone, birth_date, gender) 
   VALUES (
       'ANC-2024-0125',
       '[{"use": "official", "given": ["Mariama"], "family": "Sesay"}]',
       '+23288054388',
       '1995-03-15',
       'female'
   );
   ```

## 🖥️ Admin Dashboard

### **Overview**
The Admin Dashboard is a modern, responsive web application built with **Next.js 14**, **TypeScript**, and **Tailwind CSS**. It provides healthcare administrators and clinicians with comprehensive tools for managing maternal health data, patient records, and healthcare operations.

### **Key Features**

#### **🔐 Authentication & Roles**
- **Role-based Access**: App Admin (full access) and Clinician (limited access)
- **Secure Login**: Username/email and password authentication
- **Session Management**: Persistent login sessions with localStorage
- **Permission Control**: Different features available based on user role

#### **📊 Dashboard Analytics**
- **Real-time Metrics**: Patient counts, visit statistics, and key indicators
- **Trend Analysis**: Visual charts showing maternal health trends
- **Upcoming Due Dates**: Automated alerts for patient follow-ups
- **Performance Indicators**: ANC metrics and quality improvement data

#### **👥 Patient Management**
- **Patient Directory**: Browse and search patient records
- **Detailed Profiles**: Comprehensive patient information and medical history
- **Visit Records**: Complete ANC visit history and documentation
- **Risk Assessment**: Automated risk scoring and alerts

#### **🏥 Referral System**
- **Referral Tracking**: Manage patient referrals and follow-ups
- **Status Updates**: Track referral progress and outcomes
- **Communication Tools**: Integrated messaging for referral coordination

#### **🔔 Notification Center**
- **Patient Notifications**: Create and schedule patient reminders
- **Bulk Messaging**: Send notifications to multiple patients
- **Template System**: Pre-built notification templates
- **Delivery Tracking**: Monitor notification delivery status

#### **📚 Health Education Hub**
- **Content Management**: Create and edit health tips and nutrition advice
- **Video Library**: Manage educational videos and resources
- **Patient Distribution**: Send educational content to patients
- **Content Analytics**: Track engagement with educational materials

#### **📋 Reports & Compliance**
- **Whistleblower Reports**: Review and respond to anonymous reports
- **Filtering Tools**: Advanced search and filter capabilities
- **Response Management**: Track report responses and resolutions
- **Audit Trail**: Complete history of report handling

#### **🗄️ Database Management**
- **Connection Status**: Real-time database connectivity monitoring
- **Sync Indicators**: Visual status of data synchronization
- **Configuration Tools**: Database connection settings management
- **Error Handling**: Clear error messages and troubleshooting

### **Technology Stack**
- **Frontend**: Next.js 14, React 19, TypeScript
- **Styling**: Tailwind CSS, Shadcn/UI components
- **Charts**: Recharts for data visualization
- **Icons**: Lucide React for modern iconography
- **Database**: PostgreSQL with JSONB support
- **Authentication**: Custom JWT-based system
- **State Management**: React hooks and context

### **Running the Admin Dashboard**

#### **Prerequisites**
- Node.js (v18 or higher)
- pnpm (recommended) or npm/yarn
- PostgreSQL database running
- Git Bash (for Windows users)

#### **Installation Steps**

1. **Navigate to Admin Dashboard directory:**
   ```bash
   cd Admin_Dashboard
   ```

2. **Install dependencies:**
   ```bash
   pnpm install
   # or
   npm install
   ```

3. **Configure environment variables:**
   Create `.env.local` file:
   ```env
   DATABASE_URL=postgresql://username:password@localhost:5432/healthmother
   NEXT_PUBLIC_API_URL=http://localhost:3000
   ```

4. **Start development server (using Git Bash):**
   ```bash
   pnpm dev
   # or
   npm run dev
   ```

5. **Access the dashboard:**
   Open `http://localhost:3000` in your browser

#### **Available Scripts**
- `pnpm dev` - Start development server
- `pnpm build` - Build for production
- `pnpm start` - Start production server
- `pnpm lint` - Run ESLint

### **Default Login Credentials**
- **App Admin**: Full access to all features
- **Clinician**: Limited access to patient management and basic features

## API Endpoints

**Base URL**: `https://health-fhir-backend-production.up.railway.app`

### Authentication
- `POST /login/request-otp` - Request OTP for patient login
- `POST /login/verify-otp` - Verify OTP and get patient token
- `POST /login/direct` - Direct patient login (no OTP)
- `POST /admin/login` - Admin login

### FHIR Resources
- `GET /metadata` - FHIR CapabilityStatement
- `GET /fhir/:resourceType` - Search FHIR resources
- `POST /fhir/:resourceType` - Create FHIR resource
- `GET /fhir/:resourceType/:id` - Read specific FHIR resource
- `PUT /fhir/:resourceType/:id` - Update FHIR resource
- `DELETE /fhir/:resourceType/:id` - Delete FHIR resource

### Patient Data
- `GET /user/session` - Get patient session data
- `GET /admin/patient/:id/full` - Get comprehensive patient data (admin only)

### Analytics & Indicators
- `GET /indicators/anc` - ANC indicator metrics
- `POST /report` - Submit reports

### Chat & Communication
- `GET /chat/:chatId/messages` - Get chat messages
- `POST /chat/:chatId/messages` - Send new message

## Testing

### Production Environment
- **Backend URL**: `https://health-fhir-backend-production.up.railway.app`
- **Database**: PostgreSQL hosted on Railway
- **SSL**: HTTPS enabled

### Test Patient Data
- **ClientNumber:** `ANC-2024-0125`
- **Name:** `Mariama Sesay`
- **Phone:** `088054388`
- **OTP:** `123456` (for testing)

### Test Admin Data
- **Username:** `admin`
- **Email:** `ibrahimswaray430@gmail.com`
- **Password:** `dauda2019`

## Development

### Backend Development
- **Port:** 3000
- **CORS:** Enabled for `http://localhost:3001`
- **Logging:** Console logging for debugging
- **Error Handling:** FHIR OperationOutcome format

### Frontend Development
- **Port:** 3001
- **Framework:** Next.js 14 with TypeScript
- **Styling:** Tailwind CSS
- **State Management:** React hooks and context

### Mobile Development
- **Framework:** Flutter
- **Platforms:** Android, iOS, Web
- **State Management:** Provider pattern
- **Navigation:** Flutter navigation 2.0

## Deployment

### Backend Deployment (Railway)

The backend is deployed on **Railway** for production use:

#### **Railway Configuration**
- **URL**: `https://health-fhir-backend-production.up.railway.app`
- **Database**: PostgreSQL hosted on Railway
- **Environment Variables**: Automatically managed by Railway
- **SSL**: HTTPS enabled by default
- **Auto-scaling**: Handled by Railway platform

#### **Railway Setup Steps**
1. **Connect Repository**: Link your GitHub repository to Railway
2. **Configure Environment Variables**:
   ```env
   DATABASE_URL=postgresql://railway_user:password@railway_host:5432/railway_db
   JWT_SECRET=your_jwt_secret_key
   NODE_ENV=production
   ```
3. **Deploy**: Railway automatically deploys on git push
4. **Database**: Railway provides PostgreSQL database
5. **Domain**: Custom domain can be configured

#### **Local Development Deployment**
1. Set up PostgreSQL on production server
2. Configure environment variables
3. Use PM2 or similar for process management
4. Set up SSL certificates
5. Configure firewall rules

### Frontend Deployment
1. Build the Next.js app: `npm run build`
2. Deploy to Vercel, Netlify, or similar
3. Configure environment variables
4. Set up custom domain

### Mobile App Deployment
1. Build APK: `flutter build apk`
2. Build iOS: `flutter build ios`
3. Upload to app stores
4. Configure Firebase (optional)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

    
    