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
    
    **Configure PostgreSQL:**
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
    
    **Run the backend:**
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

4.  **Set up the Mobile App:**
    ```sh
    flutter pub get
    ```
    
    **Run the mobile app:**
    ```sh
    flutter run
    ```

### Database Setup

1. **Create the database schema** (see `database_schema.sql`)
2. **Insert demo data** (see `demo_data.sql`)
3. **Create admin user**:
   ```sql
   INSERT INTO admin (username, password_hash, email, name, role) 
   VALUES ('admin', '$2b$10$...', 'admin@healthymama.com', 'System Administrator', 'admin');
   ```

## API Endpoints

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

### Backend Deployment
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

    
    