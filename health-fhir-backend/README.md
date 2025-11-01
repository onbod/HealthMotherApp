# Health FHIR Backend

A comprehensive FHIR-compliant backend for maternal and child health applications, built with Node.js, Express, and PostgreSQL.

## Features

- 🔐 JWT-based authentication for patients and admins
- 📊 FHIR R4 compliant API endpoints
- 🏥 Complete maternal health tracking (ANC, delivery, postnatal)
- 💬 Real-time chat system for health workers
- 📱 Mobile-optimized API responses
- 🔔 Notification system
- 📈 Health indicators and reporting
- 🚀 Railway-ready deployment

## Quick Start

### Local Development

1. Clone the repository
2. Install dependencies: `npm install`
3. Set up PostgreSQL database
4. Copy `.env.example` to `.env` and configure
5. Run database schema: `psql -d your_database -f database/anc_register_fhir_dak_schema.sql`
6. Start the server: `npm start`

### Railway Deployment

1. Follow the [Railway Deployment Guide](docs/RAILWAY_DEPLOYMENT.md)
2. Deploy to Railway with one click
3. Set up PostgreSQL database on Railway
4. Configure environment variables
5. Run the database schema

## API Endpoints

### Authentication
- `POST /login/request-otp` - Request OTP for patient login
- `POST /login/verify-otp` - Verify OTP and get JWT token
- `POST /login/direct` - Direct login for patients
- `POST /admin/login` - Admin login

### Patient Data
- `GET /user/session` - Get current user session data
- `GET /patient` - List all patients
- `GET /api/patient/:id` - Get specific patient

### Health Records
- `GET /anc_visit` - ANC visit records
- `GET /pregnancy` - Pregnancy records
- `GET /delivery` - Delivery records
- `GET /postnatal_visit` - Postnatal visit records

### FHIR Resources
- `GET /fhir/:resourceType` - Search FHIR resources
- `POST /fhir/:resourceType` - Create FHIR resource
- `GET /fhir/:resourceType/:id` - Read FHIR resource
- `PUT /fhir/:resourceType/:id` - Update FHIR resource
- `DELETE /fhir/:resourceType/:id` - Delete FHIR resource

### Health Monitoring
- `GET /healthz` - Railway health check
- `GET /health` - Application health check
- `GET /db-test` - Database connection test

## Project Structure

```
health-fhir-backend/
├── database/                    # Database files
│   ├── anc_register_fhir_dak_schema.sql  # Main database schema
│   ├── demo_data.sql           # Demo data for testing
│   └── anc_register_mapping_table.csv    # DAK indicator mappings
├── docs/                       # Documentation
│   ├── anc_register_schema_overview.txt  # Schema documentation
│   └── RAILWAY_DEPLOYMENT.md   # Deployment guide
├── scripts/                    # Utility scripts
│   └── deploy-database.ps1     # Database deployment script
├── index.js                    # Main application file
├── db.js                       # Database connection
├── fhir-compliance.js          # FHIR compliance utilities
├── dak-decision-support.js     # DAK decision support
├── package.json                # Dependencies and scripts
└── README.md                   # This file
```

## Database Schema

The application uses PostgreSQL with the following main tables:
- `patient` - Patient information
- `pregnancy` - Pregnancy records
- `anc_visit` - Antenatal care visits
- `delivery` - Delivery records
- `neonate` - Newborn information
- `postnatal_visit` - Postnatal care visits
- `admin` - Administrator accounts
- `fhir_resources` - FHIR-compliant resources

## Environment Variables

```bash
DATABASE_URL=postgresql://username:password@hostname:port/database_name?sslmode=require
SECRET_KEY=your_jwt_secret_key
NODE_ENV=production
PORT=3000
```

## Testing Deployment

After deployment, run the verification script:

```bash
node verify-deployment.js https://your-railway-app.railway.app
```

## Technology Stack

- **Backend**: Node.js, Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT
- **FHIR**: FHIR R4 compliance
- **Deployment**: Railway
- **Security**: bcrypt, CORS, SSL

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

ISC License - see LICENSE file for details