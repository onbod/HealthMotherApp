# Railway Deployment Guide for Health FHIR Backend

## Prerequisites
1. Railway account (sign up at https://railway.app)
2. GitHub repository with your code
3. PostgreSQL database on Railway

## Step 1: Create Railway Project

1. Go to [Railway](https://railway.app) and sign in
2. Click "New Project"
3. Choose "Deploy from GitHub repo"
4. Select your repository: `health-fhir-backend`

## Step 2: Add PostgreSQL Database

1. In your Railway project dashboard, click "New"
2. Select "Database" → "PostgreSQL"
3. Railway will automatically create a PostgreSQL database
4. Note down the connection details (you'll need them later)

## Step 3: Set Environment Variables

In your Railway project dashboard:

1. Go to your service (the main app, not the database)
2. Click on "Variables" tab
3. Add these environment variables:

```
DATABASE_URL=postgresql://username:password@hostname:port/database_name?sslmode=require
SECRET_KEY=your_super_secret_jwt_key_here_change_this_in_production
NODE_ENV=production
PORT=3000
```

**Important**: Replace the `DATABASE_URL` with the actual connection string from your Railway PostgreSQL database.

## Step 4: Deploy Database Schema

1. Go to your PostgreSQL database in Railway
2. Click on "Query" tab
3. Copy and paste the contents of `schema.sql` file
4. Click "Run" to execute the schema

## Step 5: Deploy Your Application

1. Railway will automatically deploy when you push to your main branch
2. Or you can manually trigger deployment from the Railway dashboard
3. Check the deployment logs for any errors

## Step 6: Test Your Deployment

Once deployed, test these endpoints:

- `GET /` - Basic health check
- `GET /healthz` - Railway health check
- `GET /db-test` - Database connection test
- `GET /test-patients` - Test database query

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:port/db?sslmode=require` |
| `SECRET_KEY` | JWT secret key | `your-secret-key-here` |
| `NODE_ENV` | Environment | `production` |
| `PORT` | Server port | `3000` (Railway sets this automatically) |

## Troubleshooting

### Database Connection Issues
- Verify `DATABASE_URL` is correct
- Check if SSL is required (Railway requires SSL)
- Ensure database is running

### Application Won't Start
- Check logs in Railway dashboard
- Verify all environment variables are set
- Ensure `package.json` has correct start script

### Health Check Failing
- Verify `/healthz` endpoint is working
- Check if database connection is established
- Review application logs

## Monitoring

Railway provides:
- Real-time logs
- Metrics and monitoring
- Automatic restarts on failure
- Health checks

## Security Notes

1. Never commit `.env` file to version control
2. Use strong, unique `SECRET_KEY`
3. Keep `DATABASE_URL` secure
4. Enable SSL for all connections

## Next Steps

After successful deployment:
1. Test all API endpoints
2. Set up monitoring alerts
3. Configure custom domain (optional)
4. Set up CI/CD pipeline (optional)
