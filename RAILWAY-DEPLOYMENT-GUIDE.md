# 🚀 Railway Deployment Guide - Step by Step

## 📋 **Prerequisites Checklist**

Before we start, make sure you have:
- ✅ Railway account (sign up at [railway.app](https://railway.app))
- ✅ GitHub repository with your code
- ✅ Railway CLI installed (optional but helpful)

---

## 🎯 **Step 1: Create Railway Project**

### **Option A: Using Railway Dashboard (Recommended)**

1. **Go to Railway Dashboard**
   - Visit [railway.app](https://railway.app)
   - Sign in with your GitHub account

2. **Create New Project**
   - Click **"New Project"**
   - Select **"Deploy from GitHub repo"**
   - Choose your repository: `health-fhir-backend`

3. **Railway will automatically:**
   - Clone your repository
   - Detect it's a Node.js project
   - Start the deployment process

### **Option B: Using Railway CLI**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Initialize project
railway init

# Link to existing project
railway link
```

---

## 🗄️ **Step 2: Add PostgreSQL Database**

1. **In your Railway project dashboard:**
   - Click **"New"** button
   - Select **"Database"** → **"PostgreSQL"**
   - Railway will create a PostgreSQL database

2. **Wait for database to be ready:**
   - Status should show **"Deployed"**
   - Note the connection details

---

## ⚙️ **Step 3: Configure Environment Variables**

1. **Go to your main app service** (not the database)
2. **Click on "Variables" tab**
3. **Add these environment variables:**

```env
# Database Configuration
DATABASE_URL=postgresql://postgres:password@hostname:port/railway?sslmode=require

# Application Configuration
SECRET_KEY=your_super_secret_jwt_key_here_change_this_in_production
NODE_ENV=production
PORT=3000

# Railway Configuration
RAILWAY_PUBLIC_DOMAIN=https://your-app-name.up.railway.app
```

**Important Notes:**
- Replace `DATABASE_URL` with the actual URL from your PostgreSQL service
- Generate a strong `SECRET_KEY` (use a password generator)
- Railway will automatically set `PORT` and `RAILWAY_PUBLIC_DOMAIN`

---

## 🗃️ **Step 4: Deploy Database Schema**

1. **Go to your PostgreSQL database service**
2. **Click on "Query" tab**
3. **Copy the unified schema:**
   - Open `unified-schema.sql` from your project
   - Copy all the content

4. **Execute the schema:**
   - Paste the SQL content in the query editor
   - Click **"Run"** to execute
   - Wait for completion (may take a few minutes)

5. **Verify schema deployment:**
   - Check that tables were created
   - Verify DAK indicators were inserted
   - Confirm sample data was loaded

---

## 🚀 **Step 5: Deploy Backend Application**

1. **Railway will automatically deploy when you push to GitHub**
2. **Or manually trigger deployment:**
   - Go to your app service
   - Click **"Deploy"** button
   - Wait for deployment to complete

3. **Check deployment logs:**
   - Go to **"Deployments"** tab
   - Click on the latest deployment
   - Check **"Logs"** for any errors

---

## 🧪 **Step 6: Test Your Deployment**

### **Test Commands (Run Locally)**

```bash
# Test database compliance
npm run test-database-compliance

# Test FHIR compliance
npm run test-fhir-compliance

# Test DAK compliance
npm run test-dak-compliance

# Test production endpoints
npm run test-production
```

### **Manual Testing**

1. **Health Check:**
   ```
   https://your-app-name.up.railway.app/healthz
   ```

2. **FHIR Metadata:**
   ```
   https://your-app-name.up.railway.app/metadata
   ```

3. **DAK Indicators:**
   ```
   https://your-app-name.up.railway.app/indicators/anc
   ```

4. **FHIR Patient Search:**
   ```
   https://your-app-name.up.railway.app/fhir/Patient
   ```

---

## 🔧 **Step 7: Configure Custom Domain (Optional)**

1. **Go to your app service**
2. **Click on "Settings" tab**
3. **Scroll to "Domains" section**
4. **Add your custom domain:**
   - Click **"Custom Domain"**
   - Enter your domain name
   - Follow the DNS configuration instructions

---

## 📊 **Step 8: Monitor Your Application**

### **Railway Dashboard Features:**
- **Metrics**: CPU, Memory, Network usage
- **Logs**: Real-time application logs
- **Deployments**: Deployment history
- **Variables**: Environment variables management

### **Health Monitoring:**
- **Health Check**: `/healthz` endpoint
- **Database Status**: Connection monitoring
- **API Status**: Endpoint availability

---

## 🎯 **Step 9: Verify Compliance**

### **DAK Compliance Check:**
```bash
curl https://your-app-name.up.railway.app/indicators/anc
```

### **FHIR R4 Compliance Check:**
```bash
curl https://your-app-name.up.railway.app/metadata
```

### **Database Compliance Check:**
```bash
npm run test-database-compliance
```

---

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: DATABASE_URL not found**
**Solution:**
- Check that DATABASE_URL is set in environment variables
- Verify the URL format is correct
- Ensure the database service is running

### **Issue 2: Migration fails**
**Solution:**
- Check PostgreSQL logs in Railway dashboard
- Verify the schema SQL syntax
- Try running the migration in smaller chunks

### **Issue 3: App won't start**
**Solution:**
- Check application logs in Railway dashboard
- Verify all environment variables are set
- Ensure package.json has correct start script

### **Issue 4: CORS errors**
**Solution:**
- Check allowed origins in your CORS configuration
- Add your domain to the allowed origins list
- Verify HTTPS is being used

---

## ✅ **Success Checklist**

- [ ] Railway project created
- [ ] PostgreSQL database added
- [ ] Environment variables configured
- [ ] Database schema deployed
- [ ] Backend application deployed
- [ ] Health check endpoint working
- [ ] FHIR metadata endpoint working
- [ ] DAK indicators endpoint working
- [ ] Database compliance tests passing
- [ ] Custom domain configured (optional)
- [ ] Monitoring set up

---

## 🎉 **Congratulations!**

Your Healthy Mother App is now deployed to Railway with:
- ✅ **Complete DAK Compliance**
- ✅ **Full FHIR R4 Compliance**
- ✅ **Production-Ready Database**
- ✅ **Scalable Infrastructure**
- ✅ **Automatic Deployments**

**Your app is live and ready for production use!** 🚀🏥
