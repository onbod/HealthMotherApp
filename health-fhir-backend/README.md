# Health FHIR Backend

A comprehensive FHIR-compliant backend for maternal and child health applications, built with Node.js, Express, and PostgreSQL.

## Features

- JWT-based authentication for patients and admins
- FHIR R4 compliant API endpoints
- Complete maternal health tracking (ANC, delivery, postnatal)
- Real-time chat system for health workers
- Mobile-optimized API responses
- Notification system
- Health indicators and reporting
- Railway-ready deployment

## Quick Start

### Local Development

1. Clone the repository
2. Install dependencies: `npm install`
3. Set up PostgreSQL database
4. Copy `.env.example` to `.env` and configure
5. Run database schema: `psql -d your_database -f database/anc_register_fhir_dak_schema.sql`
6. Start the server: `npm start`

### Railway Deployment

The backend is **fully prepared** for Railway deployment:

1. **Code Quality**: All syntax errors fixed, 105 API endpoints verified
2. **Configuration**: `railway.json` configured with health check at `/healthz`
3. **Database**: Automatic `DATABASE_URL` handling for Railway PostgreSQL
4. **Environment**: Production-ready error handling and logging

**Quick Deployment Steps:**
1. Push code to GitHub
2. Connect repository to Railway
3. Add PostgreSQL service (automatic `DATABASE_URL`)
4. Set `SECRET_KEY` environment variable
5. Deploy database schema: `database/anc_register_fhir_dak_schema.sql`
6. Verify: Test `/healthz` endpoint

**For detailed instructions, see**: [RAILWAY_DEPLOYMENT.md](./RAILWAY_DEPLOYMENT.md)

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
- `GET /healthz` - Railway health check (no database required)
- `GET /health` - Application health check
- `GET /` - Root endpoint with API status
- `GET /db-test` - Database connection test

### Reports & Issues
- `POST /report` - Submit report (supports `image_urls` array)
- `GET /report` - List all reports
- `GET /reports/:id` - Get specific report

### DAK & Decision Support
- `GET /dak/decision-support/:patientId` - DAK decision support alerts
- `GET /dak/scheduling/:patientId` - DAK scheduling recommendations
- `GET /dak/quality-metrics` - DAK quality indicators
- `GET /indicators/anc` - ANC indicator metrics

## Project Structure

```
health-fhir-backend/
├── database/                           # Database files
│   ├── anc_register_fhir_dak_schema.sql  # Main database schema
│   ├── add_report_images.sql          # Image support migration
│   └── migrations/                    # Database migrations
│       ├── 2025-10-20_add_comm_tables.sql
│       └── add_notifications_table.sql
├── index.js                           # Main application (5,524 lines, 105 endpoints)
├── db.js                              # Database connection (Railway-ready)
├── fhir-compliance.js                # FHIR R4 compliance utilities
├── dak-decision-support.js            # DAK decision support logic
├── package.json                       # Dependencies and scripts
├── railway.json                       # Railway deployment configuration
├── RAILWAY_DEPLOYMENT.md              # Complete Railway deployment guide
└── README.md                          # This file
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

### Required for Railway
```bash
DATABASE_URL=postgresql://username:password@hostname:port/database_name?sslmode=require
# Automatically provided by Railway when PostgreSQL service is added

SECRET_KEY=your_jwt_secret_key
# Generate a strong secret: openssl rand -base64 32
# Required for JWT token signing
```

### Optional
```bash
NODE_ENV=production
# Railway sets this automatically, but can be overridden

PORT=3000
# Railway sets this automatically via process.env.PORT
```

### Local Development
If `DATABASE_URL` is not set, the backend falls back to local PostgreSQL:
- Host: `localhost`
- Port: `5432`
- Database: `health_fhir`
- User: `postgres`
- Password: `password`
- SSL: `false`

**Note**: For production, always use Railway's `DATABASE_URL` with SSL enabled.

## Testing Deployment

After deployment, verify the endpoints:

```bash
# Health check (Railway uses this for monitoring)
curl https://your-railway-app.railway.app/healthz

# Root endpoint
curl https://your-railway-app.railway.app/

# Database connection test
curl https://your-railway-app.railway.app/db-test

# FHIR metadata
curl https://your-railway-app.railway.app/metadata
```

All endpoints should return valid JSON responses. See [RAILWAY_DEPLOYMENT.md](./RAILWAY_DEPLOYMENT.md) for complete verification steps.

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