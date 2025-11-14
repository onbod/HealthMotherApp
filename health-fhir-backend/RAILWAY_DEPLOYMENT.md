# Railway Deployment Guide

## Pre-Deployment Checklist

✅ **Code Quality**
- All syntax errors fixed
- All comment markers properly formatted
- No duplicate endpoints
- Clean console.log statements
- 105 API endpoints verified

✅ **Configuration Files**
- `railway.json` configured with health check path `/healthz`
- `package.json` has correct start script
- Database connection handles Railway DATABASE_URL
- CORS configured for production domains

## Railway Environment Variables

Set these in Railway dashboard under your service → Variables:

### Required Variables

```bash
DATABASE_URL=postgresql://user:password@host:port/database?sslmode=require
# Railway automatically provides this when you add a PostgreSQL service

SECRET_KEY=your_secure_jwt_secret_key_here
# Generate a strong secret: openssl rand -base64 32

NODE_ENV=production
# Railway sets this automatically, but you can override
```

### Optional Variables

```bash
PORT=3000
# Railway sets this automatically, but you can override if needed
```

## Deployment Steps

1. **Connect Repository to Railway**
   - Go to Railway dashboard
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Select the `health-fhir-backend` directory

2. **Add PostgreSQL Service**
   - In your Railway project, click "New"
   - Select "Database" → "Add PostgreSQL"
   - Railway will automatically create and link it
   - The `DATABASE_URL` will be automatically set

3. **Set Environment Variables**
   - Go to your service → Variables
   - Add `SECRET_KEY` (generate a secure random string)
   - Verify `DATABASE_URL` is set (should be automatic)
   - Set `NODE_ENV=production` (optional, Railway sets this)

4. **Deploy Database Schema**
   - After deployment, connect to your Railway PostgreSQL database
   - Run the schema file:
   ```bash
   psql $DATABASE_URL -f database/anc_register_fhir_dak_schema.sql
   ```
   - Or use Railway's database console to run the SQL file

5. **Verify Deployment**
   - Check Railway logs for successful startup
   - Test health endpoint: `https://your-app.railway.app/healthz`
   - Test root endpoint: `https://your-app.railway.app/`
   - Test database connection: `https://your-app.railway.app/db-test`

## Health Check Endpoints

Railway uses `/healthz` for health checks (configured in `railway.json`):

- `GET /healthz` - Railway health check (no database required)
- `GET /health` - Application health check
- `GET /` - Root endpoint with API status
- `GET /db-test` - Database connection test

## Key API Endpoints

### Authentication
- `POST /login/request-otp` - Request OTP
- `POST /login/verify-otp` - Verify OTP
- `POST /login/direct` - Direct login
- `POST /admin/login` - Admin login

### Patient Data
- `GET /user/session` - Get user session (requires JWT)
- `GET /patient` - List patients
- `GET /api/patient/:id` - Get patient by ID

### Health Records
- `GET /anc_visit` - ANC visits
- `GET /pregnancy` - Pregnancy records
- `GET /delivery` - Delivery records
- `GET /postnatal_care` - Postnatal visits

### FHIR Resources
- `GET /fhir/:resourceType` - Search FHIR resources
- `GET /metadata` - FHIR CapabilityStatement
- `POST /fhir/:resourceType` - Create FHIR resource

### Reports
- `POST /report` - Submit report (supports image_urls)
- `GET /report` - List reports

## Troubleshooting

### Server Won't Start
1. Check Railway logs for errors
2. Verify `DATABASE_URL` is set correctly
3. Ensure `SECRET_KEY` is set
4. Check that port binding is correct (Railway sets PORT automatically)

### Database Connection Issues
1. Verify PostgreSQL service is running
2. Check `DATABASE_URL` format
3. Ensure SSL is enabled (Railway requires it)
4. Test connection with `/db-test` endpoint

### CORS Errors
1. Verify frontend domains are in `allowedOrigins` array
2. Check that CORS middleware is properly configured
3. Ensure credentials are set correctly

## Post-Deployment Verification

Run these tests after deployment:

```bash
# Health check
curl https://your-app.railway.app/healthz

# Root endpoint
curl https://your-app.railway.app/

# Database test
curl https://your-app.railway.app/db-test

# FHIR metadata
curl https://your-app.railway.app/metadata
```

## Monitoring

- Railway automatically monitors `/healthz` endpoint
- Check Railway dashboard for logs and metrics
- Set up alerts for failed health checks
- Monitor database connection pool

## Production Best Practices

1. **Security**
   - Use strong `SECRET_KEY` (32+ characters)
   - Enable SSL/TLS (Railway does this automatically)
   - Keep dependencies updated
   - Review CORS settings regularly

2. **Performance**
   - Monitor database connection pool
   - Review slow query logs
   - Optimize database indexes
   - Use Railway's built-in monitoring

3. **Backups**
   - Railway PostgreSQL includes automatic backups
   - Consider additional backup strategy for critical data
   - Test restore procedures regularly

## Support

For issues:
1. Check Railway logs first
2. Review application logs in Railway dashboard
3. Test endpoints individually
4. Verify environment variables are set correctly

