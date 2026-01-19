require('dotenv').config(); // Load env vars

const express = require('express');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');
const Fhir = require('fhir').Fhir;
const fhir = new Fhir();
const fhirCompliance = require('./fhir-compliance');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const cors = require('cors');

const SECRET_KEY = process.env.SECRET_KEY || 'your_secret_key';
const otpStore = new Map();

const app = express();
app.use(bodyParser.json());

// Allow frontend to connect
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:59016',
  'http://localhost:3001',
  'https://healthymama-admin-dashboard.vercel.app',
  'https://healthymotherapp.vercel.app'
];

app.use(cors({
  origin: function (origin, callback) {
    // allow requests with no origin (like mobile apps, curl, etc.)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    } else {
      return callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));

// Log all incoming requests (only for non-polling endpoints to reduce log spam)
app.use((req, res, next) => {
  // Skip logging for frequent polling endpoints
  const skipLogging = ['/api/notifications', '/chat/', '/user/session'].some(path => req.url.startsWith(path));
  if (!skipLogging) {
    console.log('INCOMING REQUEST:', req.method, req.url);
  }
  next();
});

// PostgreSQL connection (works locally + Railway)
const pool = require('./db');

// Test database connection on startup
async function testDatabaseConnection() {
  try {
    if (process.env.NODE_ENV !== 'production') {
    console.log('Testing database connection...');
    }
    
    const result = await pool.query('SELECT NOW() as current_time');
    console.log('Database connection successful:', result.rows[0].current_time);
  } catch (error) {
    console.error('Database connection failed:', error.message);
    // Don't exit in production to keep the container running
    if (process.env.NODE_ENV !== 'production') {
      process.exit(1);
    }
  }
}

// Test connection on startup
testDatabaseConnection();

// Root endpoint for Railway health check
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'FHIR Backend API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Railway health check endpoint (no database required)
app.get('/healthz', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    port: process.env.PORT || 3000,
    railway: true
  });
});

// Additional Railway health check
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok',
    message: 'Railway health check passed',
    timestamp: new Date().toISOString(),
    port: process.env.PORT || 3000
  });
});

// One-time admin password reset endpoint (secured with secret key)
app.post('/admin/reset-all', async (req, res) => {
  try {
    const { secret } = req.body;
    // Simple security check - must provide correct secret
    if (secret !== 'healthymama2026reset') {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    const newPassword = 'Admin@123';
    const password_hash = await bcrypt.hash(newPassword, 10);
    
    // Update all admin passwords and set main admin email
    await pool.query(`UPDATE admins SET password_hash = $1, updated_at = CURRENT_TIMESTAMP`, [password_hash]);
    await pool.query(`UPDATE admins SET email = $1 WHERE id = 1`, ['ibrahimswaray430@gmail.com']);
    
    res.json({
      success: true,
      message: 'All admin passwords reset to Admin@123. Main admin email updated to ibrahimswaray430@gmail.com',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error resetting admins:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Simple test endpoint that doesn't require database
app.get('/test', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Test endpoint working',
    timestamp: new Date().toISOString()
  });
});

// FHIR R4 Metadata Endpoint (CapabilityStatement)
app.get('/metadata', (req, res) => {
  try {
    const capabilityStatement = fhirCompliance.getCapabilityStatement();
    res.set('Content-Type', 'application/fhir+json');
    res.json(capabilityStatement);
  } catch (error) {
    console.error('Error generating CapabilityStatement:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error generating CapabilityStatement'
        }
      ]
    });
  }
});

// FHIR R4 Conformance Endpoint (alias for metadata)
app.get('/fhir/metadata', (req, res) => {
  res.redirect('/metadata');
});

// FHIR R4 Search Parameters
app.get('/SearchParameter', (req, res) => {
  try {
    const searchParams = fhirCompliance.getSearchParameters();
    res.set('Content-Type', 'application/fhir+json');
    res.json(searchParams);
  } catch (error) {
    console.error('Error getting search parameters:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error getting search parameters'
        }
      ]
    });
  }
});

// FHIR R4 Operation Definitions
app.get('/OperationDefinition', (req, res) => {
  try {
    const operationDefs = fhirCompliance.getOperationDefinitions();
    const bundle = {
      resourceType: 'Bundle',
      type: 'searchset',
      total: operationDefs.length,
      entry: operationDefs.map(def => ({
        resource: def
      }))
    };
    res.set('Content-Type', 'application/fhir+json');
    res.json(bundle);
  } catch (error) {
    console.error('Error getting operation definitions:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error getting operation definitions'
        }
      ]
    });
  }
});

// FHIR R4 Structure Definitions
app.get('/StructureDefinition', (req, res) => {
  try {
    const structureDefs = fhirCompliance.getStructureDefinitions();
    const bundle = {
      resourceType: 'Bundle',
      type: 'searchset',
      total: structureDefs.length,
      entry: structureDefs.map(def => ({
        resource: def
      }))
    };
    res.set('Content-Type', 'application/fhir+json');
    res.json(bundle);
  } catch (error) {
    console.error('Error getting structure definitions:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error getting structure definitions'
        }
      ]
    });
  }
});

// FHIR R4 Value Sets
app.get('/ValueSet', (req, res) => {
  try {
    const valueSets = fhirCompliance.getValueSets();
    const bundle = {
      resourceType: 'Bundle',
      type: 'searchset',
      total: valueSets.length,
      entry: valueSets.map(vs => ({
        resource: vs
      }))
    };
    res.set('Content-Type', 'application/fhir+json');
    res.json(bundle);
  } catch (error) {
    console.error('Error getting value sets:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error getting value sets'
        }
      ]
    });
  }
});

// Database test endpoint
app.get('/db-test', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time');
    res.json({ 
      status: 'ok', 
      message: 'Database connection successful',
      database_time: result.rows[0].current_time,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'error', 
      message: 'Database connection failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Quick Health Check (duplicate - keeping for compatibility)
app.get('/health-check', async (req, res) => {
  try {
    await pool.query('SELECT NOW()');
    res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    console.error('DB ERROR:', err);
    res.status(500).json({ status: 'error', db: 'disconnected' });
  }
});

// Authentication & User Routes

// OTP request endpoint
app.post('/login/request-otp', async (req, res) => {
  const { phone, identifier, given, family, national_id } = req.body;
  let query, value;

  if (phone) {
    query = 'SELECT * FROM patient WHERE phone = $1';
    value = [phone];
  } else if (given && family && identifier) {
    query = `
      SELECT * FROM patient
      WHERE first_name = $1 AND last_name = $2 AND identifier = $3
    `;
    value = [given, family, identifier];
  } else if (national_id) {
    query = 'SELECT * FROM patient WHERE national_id = $1';
    value = [national_id];
  } else {
    return res.status(400).json({ error: 'Missing identifier' });
  }

  const result = await pool.query(query, value);
  if (result.rows.length === 0) {
    return res.status(404).json(operationOutcome('error', 'not-found', 'User not found'));
  }

  const otp = '123456'; // TEMP for testing
  let otpKey = phone || (given && family && identifier ? `${given}:${family}:${identifier}` : national_id);
  otpStore.set(otpKey, { otp, expires: Date.now() + 5 * 60 * 1000 });

  console.log(`OTP for ${otpKey}: ${otp}`); // Replace with SMS in production
  res.json({ message: 'OTP sent', otp }); // <-- REMOVE 'otp' IN PRODUCTION
});

// OTP verify endpoint
app.post('/login/verify-otp', async (req, res) => {
  const { phone, identifier, given, family, national_id, otp } = req.body;
  let key, query, value;

  if (phone) {
    key = phone;
    query = 'SELECT * FROM patient WHERE phone = $1';
    value = [phone];
  } else if (given && family && identifier) {
    key = `${given}:${family}:${identifier}`;
    query = `
      SELECT * FROM patient
      WHERE first_name = $1 AND last_name = $2 AND identifier = $3
    `;
    value = [given, family, identifier];
  } else if (national_id) {
    key = national_id;
    query = 'SELECT * FROM patient WHERE national_id = $1';
    value = [national_id];
  } else {
    return res.status(400).json({ error: 'Missing identifier' });
  }

  const otpEntry = otpStore.get(key);
  if (!otpEntry || otpEntry.otp !== otp || otpEntry.expires < Date.now()) {
    return res.status(401).json({ error: 'Invalid or expired OTP' });
  }

  const result = await pool.query(query, value);
  if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

  otpStore.delete(key);

  const user = result.rows[0];
  const token = jwt.sign(
    { id: user.patient_id, identifier: user.identifier, name: user.name, phone: user.phone, national_id: user.national_id, role: 'patient' },
    SECRET_KEY,
    { expiresIn: '1h' }
  );

  res.json({ token });
});

// Direct login endpoint
app.post('/login/direct', async (req, res) => {
  const { given, family, identifier, national_id } = req.body;
  let query, value;
  
  if (given && family && identifier) {
    query = `
      SELECT * FROM patient
      WHERE first_name = $1 AND last_name = $2 AND identifier = $3
    `;
    value = [given, family, identifier];
    let result = await pool.query(query, value);
    
    if (result.rows.length === 0 && national_id && national_id !== identifier) {
      query = `
        SELECT * FROM patient
        WHERE first_name = $1 AND last_name = $2 AND national_id = $3
      `;
      value = [given, family, national_id];
      result = await pool.query(query, value);
    }
    
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    
    const user = result.rows[0];
    const token = jwt.sign(
      { id: user.patient_id, identifier: user.identifier, name: user.name, phone: user.phone, national_id: user.national_id, role: 'patient' },
      SECRET_KEY,
      { expiresIn: '1h' }
    );

    return res.json({ token });
  } else if (national_id) {
    query = 'SELECT * FROM patient WHERE national_id = $1';
    value = [national_id];
    const result = await pool.query(query, value);
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const user = result.rows[0];
    const token = jwt.sign(
      { id: user.patient_id, identifier: user.identifier, name: user.name, phone: user.phone, national_id: user.national_id, role: 'patient' },
      SECRET_KEY,
      { expiresIn: '1h' }
    );

    return res.json({ token });
  } else {
    return res.status(400).json({ error: 'Missing identifier' });
  }
});

// Admin login
app.post('/admin/login', async (req, res) => {
  const { email, password } = req.body;
  // Align with schema: table `admins`, fields include id, username, email, full_name, password_hash, role
  const result = await pool.query('SELECT * FROM admins WHERE username = $1 OR email = $1', [email]);
  if (result.rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });

  const admin = result.rows[0];
  const match = await bcrypt.compare(password, admin.password_hash);
  if (!match) return res.status(401).json({ error: 'Invalid credentials' });

  const token = jwt.sign(
    { id: admin.id, username: admin.username, email: admin.email, name: admin.full_name || admin.username, role: admin.role || 'admin' },
    SECRET_KEY,
    { expiresIn: '2h' }
  );

  res.json({ token, name: admin.full_name || admin.username, email: admin.email });
});

// JWT auth middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    if (!user.role || (user.role !== 'patient' && user.role !== 'admin')) {
      return res.status(403).json({ error: 'Insufficient role' });
    }
    next();
  });
}

// Import DAK Decision Support System
const dakSupport = require('./dak-decision-support');

// Enhanced DAK Decision Support Alerts
function generateDecisionSupportAlerts(pregnancy, ancVisits) {
  return dakSupport.generateDAKDecisionSupportAlerts(pregnancy, ancVisits);
}

// Basic Test Route
app.get('/test-patients', async (req, res) => {
  const result = await pool.query('SELECT patient_id FROM patient');
  res.json(result.rows);
});

// Helper function for FHIR OperationOutcome

function operationOutcome(severity, code, diagnostics) {
  return {
    resourceType: "OperationOutcome",
    issue: [
      {
        severity,
        code,
        diagnostics
      }
    ]
  };
}

// This function is now replaced by the DAK decision support system above

// 1. Your custom endpoint - Updated to match new schema
app.post('/report', async (req, res) => {
  const {
    client_number,
    client_name,
    phone_number,
    report_type,
    facility_name,
    description,
    is_anonymous,
    organization_id,
    reply,
    fhir_resource,
    image_urls
  } = req.body;

  try {
    // Validate required fields
    if (!client_number || !client_name || !description) {
      return res.status(400).json({ 
        error: 'Missing required fields', 
        details: 'client_number, client_name, and description are required' 
      });
    }

    const fhirId = uuidv4();
    const dakReportId = `dak-report-${Date.now()}`;
    
    // Handle image_urls - ensure it's an array
    let imageUrlsArray = [];
    if (image_urls) {
      if (Array.isArray(image_urls)) {
        imageUrlsArray = image_urls.filter(url => url && url.trim().length > 0);
      } else if (typeof image_urls === 'string') {
        imageUrlsArray = [image_urls].filter(url => url && url.trim().length > 0);
      }
    }
    
    const result = await pool.query(
      `INSERT INTO reports
        (fhir_id, dak_report_id, client_number, client_name, phone_number, report_type, facility_name, organization_id, description, is_anonymous, reply, fhir_resource, image_urls)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING *`,
      [
        fhirId,
        dakReportId,
        client_number,
        client_name,
        phone_number || null,
        report_type || null,
        facility_name || null,
        organization_id || null,
        description,
        is_anonymous === true || false,
        reply || null,
        fhir_resource ? JSON.stringify(fhir_resource) : null,
        imageUrlsArray.length > 0 ? imageUrlsArray : null
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    console.error('Error inserting report:', e);
    res.status(500).json({ error: 'Failed to submit report', details: e.message });
  }
});

// Enhanced DAK Indicators endpoint
app.get('/indicators/anc', async (req, res) => {
  try {
    // Get all ANC visits for calculation
    const ancVisitsResult = await pool.query(`
      SELECT 
        visit_number, gestational_age_weeks, hiv_status, syphilis_status,
        iron_supplementation, tetanus_doses, birth_preparedness_plan,
        danger_sign_education, postpartum_plan, family_planning_counseling
      FROM anc_visit
    `);
    
    const ancVisits = ancVisitsResult.rows;
    const indicators = dakSupport.calculateDAKIndicators(ancVisits, []);
    
    const metrics = {
      resourceType: "MeasureReport",
      type: "summary",
      period: {
        start: "2025-01-01",
        end: new Date().toISOString()
      },
      group: Object.keys(indicators).map(key => ({
        measureScore: { value: indicators[key].value },
        description: indicators[key].name,
        numerator: indicators[key].numerator,
        denominator: indicators[key].denominator,
        target: indicators[key].target,
        status: indicators[key].status
      }))
    };
    
    res.json(metrics);
  } catch (error) {
    console.error('Error calculating DAK indicators:', error);
    res.status(500).json({ error: 'Failed to calculate indicators' });
  }
});

// New DAK Decision Support endpoint
app.get('/dak/decision-support/:patientId', async (req, res) => {
  try {
    const { patientId } = req.params;
    
    // Get patient pregnancy and visits
    const pregnancyResult = await pool.query(`
      SELECT p.*, pr.lmp_date, pr.edd_date, pr.gravida, pr.para, pr.status as pregnancy_status
      FROM patient p
      LEFT JOIN pregnancy pr ON p.patient_id = pr.patient_id
      WHERE p.patient_id = $1 AND pr.status = 'active'
    `, [patientId]);
    
    if (pregnancyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Active pregnancy not found' });
    }
    
    const pregnancy = pregnancyResult.rows[0];
    
    const visitsResult = await pool.query(`
      SELECT av.* FROM anc_visit av
      JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
      WHERE pr.patient_id = $1
      ORDER BY av.visit_date ASC
    `, [patientId]);
    
    const ancVisits = visitsResult.rows;
    const alerts = dakSupport.generateDAKDecisionSupportAlerts(pregnancy, ancVisits);
    const nextVisit = dakSupport.calculateNextDAKVisit(pregnancy, ancVisits);
    
    res.json({
      patientId,
      pregnancy,
      ancVisits,
      decisionSupportAlerts: alerts,
      nextVisitRecommendation: nextVisit,
      totalAlerts: alerts.length,
      highPriorityAlerts: alerts.filter(a => a.priority === 'high').length
    });
    
  } catch (error) {
    console.error('Error generating DAK decision support:', error);
    res.status(500).json({ error: 'Failed to generate decision support' });
  }
});

// DAK Scheduling endpoint
app.get('/dak/scheduling/:patientId', async (req, res) => {
  try {
    const { patientId } = req.params;
    
    const pregnancyResult = await pool.query(`
      SELECT p.*, pr.lmp_date, pr.edd_date, pr.gravida, pr.para, pr.status as pregnancy_status
      FROM patient p
      LEFT JOIN pregnancy pr ON p.patient_id = pr.patient_id
      WHERE p.patient_id = $1 AND pr.status = 'active'
    `, [patientId]);
    
    if (pregnancyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Active pregnancy not found' });
    }
    
    const pregnancy = pregnancyResult.rows[0];
    
    const visitsResult = await pool.query(`
      SELECT av.* FROM anc_visit av
      JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
      WHERE pr.patient_id = $1
      ORDER BY av.visit_date ASC
    `, [patientId]);
    
    const ancVisits = visitsResult.rows;
    const nextVisit = dakSupport.calculateNextDAKVisit(pregnancy, ancVisits);
    
    // Get scheduling history
    const schedulingResult = await pool.query(`
      SELECT * FROM dak_contact_schedule 
      WHERE patient_id = $1 
      ORDER BY contact_number ASC, created_at DESC
    `, [patientId]);
    
    res.json({
      patientId,
      pregnancy,
      currentVisits: ancVisits.length,
      nextVisitRecommendation: nextVisit,
      schedulingHistory: schedulingResult.rows,
      dakSchedulingGuidelines: dakSupport.DAK_SCHEDULING
    });
    
  } catch (error) {
    console.error('Error generating DAK scheduling:', error);
    res.status(500).json({ error: 'Failed to generate scheduling recommendations' });
  }
});

// DAK Scheduling endpoint for specific contact number
app.get('/dak/scheduling/:patientId/:contactNumber', async (req, res) => {
  try {
    const { patientId, contactNumber } = req.params;
    
    const result = await pool.query(`
      SELECT 
        dcs.*,
        p.name as patient_name,
        p.identifier as patient_identifier,
        pr.lmp_date,
        pr.edd_date
      FROM dak_contact_schedule dcs
      LEFT JOIN patient p ON dcs.patient_id = p.patient_id
      LEFT JOIN pregnancy pr ON dcs.pregnancy_id = pr.pregnancy_id
      WHERE dcs.patient_id = $1 AND dcs.contact_number = $2
      ORDER BY dcs.created_at DESC
      LIMIT 1
    `, [patientId, contactNumber]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        error: 'Contact schedule not found',
        message: `No contact schedule found for patient ${patientId} with contact number ${contactNumber}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Error fetching DAK contact schedule:', error);
    res.status(500).json({ error: 'Failed to fetch contact schedule' });
  }
});

// DAK Quality Metrics endpoint
app.get('/dak/quality-metrics', async (req, res) => {
  try {
    const { facilityId, startDate, endDate, patientId } = req.query;
    
    let query = `
      SELECT 
        dqi.indicator_id,
        dqi.fhir_id,
        dqi.patient_id,
        dqi.encounter_id,
        dqi.indicator_code,
        dqi.indicator_name,
        dqi.indicator_value,
        dqi.indicator_status,
        dqi.risk_flag,
        dqi.decision_support_message,
        dqi.next_visit_schedule,
        dqi.dak_indicator_id,
        dqi.measurement_date,
        dqi.target_value,
        dqi.fhir_resource,
        dqi.version_id,
        dqi.created_at,
        dqi.updated_at,
        dqi.last_updated,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM dak_quality_indicators dqi
      LEFT JOIN patient p ON dqi.patient_id = p.patient_id
      WHERE 1=1
    `;
    
    const params = [];
    let paramCount = 0;
    
    if (patientId) {
      paramCount++;
      query += ` AND dqi.patient_id = $${paramCount}`;
      params.push(patientId);
    }
    
    if (startDate) {
      paramCount++;
      query += ` AND dqi.measurement_date >= $${paramCount}`;
      params.push(startDate);
    }
    
    if (endDate) {
      paramCount++;
      query += ` AND dqi.measurement_date <= $${paramCount}`;
      params.push(endDate);
    }
    
    query += ` ORDER BY dqi.measurement_date DESC`;
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      qualityMetrics: result.rows,
      totalMetrics: result.rows.length,
      period: { startDate, endDate },
      filters: { facilityId, patientId },
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Error fetching quality metrics:', error);
    res.status(500).json({ error: 'Failed to fetch quality metrics' });
  }
});

// Get user session/profile endpoint (MUST come before catch-all routes)
app.get('/user/session', async (req, res) => {
  console.log('DEBUG: /user/session - Starting endpoint');
  
  // Extract user ID from JWT token in Authorization header
  const authHeader = req.headers['authorization'];
  console.log('DEBUG: /user/session - authHeader:', authHeader);
  
  const token = authHeader && authHeader.split(' ')[1];
  console.log('DEBUG: /user/session - token:', token ? 'present' : 'missing');
  
  if (!token) {
    console.log('DEBUG: /user/session - No token provided');
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    let userId = decoded.id;
    console.log('DEBUG: /user/session decoded token:', decoded);
    console.log('DEBUG: /user/session initial userId:', userId);

    // Fallback resolution if token lacks id (older tokens or alternate issuers)
    if (!userId) {
      try {
        if (decoded.phone) {
          const r = await pool.query('SELECT patient_id FROM patient WHERE phone = $1', [decoded.phone]);
          if (r.rows.length > 0) userId = r.rows[0].patient_id;
        }
        if (!userId && decoded.national_id) {
          const r = await pool.query('SELECT patient_id FROM patient WHERE national_id = $1', [decoded.national_id]);
          if (r.rows.length > 0) userId = r.rows[0].patient_id;
        }
        if (!userId && decoded.identifier) {
          const r = await pool.query('SELECT patient_id FROM patient WHERE identifier = $1', [decoded.identifier]);
          if (r.rows.length > 0) userId = r.rows[0].patient_id;
        }
      } catch (e) {
        console.warn('WARN: /user/session fallback id resolution failed:', e.message);
      }
    }

    if (!userId) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    console.log('DEBUG: /user/session resolved userId:', userId);

  // Get patient info
  const patientResult = await pool.query('SELECT * FROM patient WHERE patient_id = $1', [userId]);
  console.log('DEBUG: /user/session patientResult:', patientResult.rows);
    console.log('DEBUG: /user/session patientResult.rowCount:', patientResult.rowCount);

  if (patientResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });
  const patient = patientResult.rows[0];

  // Get current pregnancy (latest by edd_date)
  const pregnancyResult = await pool.query(
    'SELECT * FROM pregnancy WHERE patient_id = $1 ORDER BY edd_date DESC LIMIT 1', [userId]
  );
  const pregnancy = pregnancyResult.rows[0] || null;
  console.log('DEBUG: /user/session pregnancy:', pregnancy);

  // Get all ANC visits for this patient (for the current pregnancy)
  let ancVisits = [];
  if (pregnancy) {
    const ancResult = await pool.query(
      `SELECT av.*
       FROM anc_visit av
       JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
       WHERE pr.patient_id = $1
       ORDER BY av.visit_number ASC`,
      [userId]
    );
    ancVisits = ancResult.rows;
  }
  console.log('DEBUG: /user/session ancVisits:', ancVisits);

  // Get delivery info for this pregnancy
  let delivery = null;
  if (pregnancy) {
    const deliveryResult = await pool.query(
      'SELECT * FROM delivery WHERE pregnancy_id = $1', [pregnancy.pregnancy_id]
    );
    delivery = deliveryResult.rows[0] || null;
  }
  console.log('DEBUG: /user/session delivery:', delivery);

  // Get neonate info for this delivery
  let neonates = [];
  if (delivery) {
    const neonateResult = await pool.query(
      'SELECT * FROM neonate WHERE delivery_id = $1', [delivery.delivery_id]
    );
    neonates = neonateResult.rows;
  }
  console.log('DEBUG: /user/session neonates:', neonates);

  // Get postnatal visits for this delivery
  let postnatalVisits = [];
  if (delivery) {
    const postnatalResult = await pool.query(
      'SELECT * FROM postnatal_care WHERE patient_id = $1 ORDER BY visit_date ASC', [userId]
    );
    postnatalVisits = postnatalResult.rows;
  }
  console.log('DEBUG: /user/session postnatalVisits:', postnatalVisits);

  const decisionSupportAlerts = pregnancy ? generateDecisionSupportAlerts(pregnancy, ancVisits) : [];

  res.json({
    patient,
    pregnancy,
    ancVisits,
    delivery,
    neonates,
    postnatalVisits,
    decisionSupportAlerts
  });
  } catch (err) {
    console.error('JWT verification error:', err);
    return res.status(401).json({ error: 'Invalid token' });
  }
});

// API PREFIXED ROUTES (for frontend compatibility)
app.get('/api/anc_visit', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        av.*,
        p.name as patient_name,
        p.identifier as patient_identifier,
        pr.lmp_date,
        pr.edd_date
      FROM anc_visit av
      LEFT JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
      LEFT JOIN patient p ON pr.patient_id = p.patient_id
      ORDER BY av.visit_date DESC, av.visit_number ASC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching all anc_visit:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch anc_visit',
      message: err.message 
    });
  }
});

app.get('/api/postnatal_care', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        pnc.*,
        p.name as mother_name,
        p.identifier as mother_identifier,
        n.name as neonate_name
      FROM postnatal_care pnc
      LEFT JOIN patient p ON pnc.patient_id = p.patient_id
      LEFT JOIN neonate n ON pnc.neonate_id = n.neonate_id
      ORDER BY pnc.visit_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching postnatal_care:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch postnatal_care data',
      message: err.message 
    });
  }
});

app.get('/api/delivery', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        d.*,
        p.name as mother_name,
        p.identifier as mother_identifier,
        pr.lmp_date,
        pr.edd_date
      FROM delivery d
      LEFT JOIN patient p ON d.patient_id = p.patient_id
      LEFT JOIN pregnancy pr ON d.pregnancy_id = pr.pregnancy_id
      ORDER BY d.delivery_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching delivery:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch delivery data',
      message: err.message 
    });
  }
});

// SPECIFIC TABLE ROUTES – THESE ALWAYS COME FIRST

// ANC visits
app.get('/anc_visit', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        av.anc_visit_id,
        av.fhir_id,
        av.encounter_id,
        av.pregnancy_id,
        pr.patient_id,
        av.visit_number,
        av.visit_date,
        av.gestation_weeks,
        av.weight_kg,
        av.height_cm,
        av.bmi,
        av.blood_pressure_systolic,
        av.blood_pressure_diastolic,
        av.pulse_rate,
        av.temperature,
        av.respiratory_rate,
        av.fundal_height_cm,
        av.fetal_heart_rate,
        av.fetal_position,
        av.fetal_movement,
        av.hemoglobin_gdl,
        av.hematocrit,
        av.blood_group,
        av.rhesus_factor,
        av.urine_protein,
        av.urine_glucose,
        av.urine_ketones,
        av.urine_blood,
        av.hiv_test_done,
        av.hiv_test_result,
        av.hiv_test_date,
        av.syphilis_test_done,
        av.syphilis_test_result,
        av.syphilis_test_date,
        av.hepatitis_b_test_done,
        av.hepatitis_b_test_result,
        av.hepatitis_b_test_date,
        av.malaria_test_done,
        av.malaria_test_result,
        av.malaria_test_date,
        av.maternal_complaints,
        av.danger_signs_present,
        av.danger_signs_list,
        av.provider_notes,
        av.clinical_impression,
        av.plan_of_care,
        av.dak_contact_number,
        av.risk_level,
        av.risk_factors,
        av.iron_supplement_given,
        av.iron_supplement_dosage,
        av.folic_acid_given,
        av.folic_acid_dosage,
        av.tetanus_toxoid_given,
        av.tetanus_toxoid_dose,
        av.malaria_prophylaxis_given,
        av.malaria_prophylaxis_type,
        av.deworming_given,
        av.deworming_type,
        av.provider_name,
        av.provider_qualification,
        av.provider_id,
        av.next_visit_date,
        av.next_visit_gestation_weeks,
        av.referral_made,
        av.referral_reason,
        av.referral_facility,
        av.fhir_resource,
        av.version_id,
        av.created_at,
        av.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM anc_visit av
      LEFT JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
      LEFT JOIN patient p ON pr.patient_id = p.patient_id
      ORDER BY av.visit_date DESC, av.visit_number ASC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching all anc_visit:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch anc_visit',
      message: err.message 
    });
  }
});

app.get('/anc_visit/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        av.*,
        p.name as patient_name,
        p.identifier as patient_identifier,
        pr.lmp_date,
        pr.edd_date,
        pr.gravida,
        pr.para
      FROM anc_visit av
      LEFT JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
      LEFT JOIN patient p ON pr.patient_id = p.patient_id
      WHERE av.anc_visit_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'ANC visit not found',
        message: `No ANC visit found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching anc_visit:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch anc_visit data',
      message: err.message 
    });
  }
});

app.get('/anc_visits/patient/:patientId', async (req, res) => {
  try {
    const { patientId } = req.params;
    const result = await pool.query(
      `SELECT av.* FROM anc_visit av
       JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
       WHERE pr.patient_id = $1
       ORDER BY av.visit_date ASC`,
      [patientId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching anc visits:', err);
    res.status(500).json({ error: 'Failed to fetch anc visits' });
  }
});

// Pregnancy
app.get('/pregnancy', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        pr.pregnancy_id,
        pr.fhir_id,
        pr.patient_id,
        pr.lmp_date,
        pr.edd_date,
        pr.gravida,
        pr.para,
        pr.abortion,
        pr.stillbirth,
        pr.live_birth,
        pr.current_gestation_weeks,
        pr.status,
        pr.dak_pregnancy_id,
        pr.pregnancy_number,
        pr.previous_pregnancy_complications,
        pr.previous_c_section,
        pr.previous_stillbirth,
        pr.previous_preterm_birth,
        pr.family_history,
        pr.fhir_resource,
        pr.version_id,
        pr.created_at,
        pr.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier,
        p.phone as patient_phone
      FROM pregnancy pr
      LEFT JOIN patient p ON pr.patient_id = p.patient_id
      ORDER BY pr.created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching pregnancy:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch pregnancy data',
      message: err.message 
    });
  }
});

// Delivery
app.get('/delivery', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        d.delivery_id,
        d.fhir_id,
        d.patient_id,
        d.encounter_id,
        d.pregnancy_id,
        d.delivery_date,
        d.delivery_time,
        d.delivery_mode,
        d.delivery_outcome,
        d.maternal_weight_kg,
        d.maternal_height_cm,
        d.apgar_1min,
        d.apgar_5min,
        d.birth_weight_grams,
        d.birth_length_cm,
        d.head_circumference_cm,
        d.chest_circumference_cm,
        d.sex,
        d.labor_duration_hours,
        d.delivery_complications,
        d.episiotomy,
        d.perineal_tear,
        d.blood_loss_ml,
        d.dak_delivery_id,
        d.delivery_facility,
        d.delivery_provider,
        d.delivery_provider_qualification,
        d.fhir_resource,
        d.version_id,
        d.created_at,
        d.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier,
        pr.lmp_date,
        pr.edd_date,
        pr.gravida,
        pr.para
      FROM delivery d
      LEFT JOIN patient p ON d.patient_id = p.patient_id
      LEFT JOIN pregnancy pr ON d.pregnancy_id = pr.pregnancy_id
      ORDER BY d.delivery_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching delivery:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch delivery data',
      message: err.message 
    });
  }
});

// Neonates
app.get('/neonate', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        n.neonate_id,
        n.fhir_id,
        n.patient_id,
        n.delivery_id,
        n.encounter_id,
        n.name,
        n.birth_date,
        n.birth_time,
        n.birth_weight_grams,
        n.birth_length_cm,
        n.head_circumference_cm,
        n.chest_circumference_cm,
        n.sex,
        n.apgar_1min,
        n.apgar_5min,
        n.delivery_mode,
        n.dak_neonate_id,
        n.birth_certificate_number,
        n.birth_registration_date,
        n.fhir_resource,
        n.version_id,
        n.created_at,
        n.updated_at,
        p.name as mother_name,
        p.identifier as mother_identifier,
        d.delivery_date,
        d.delivery_outcome,
        d.delivery_facility
      FROM neonate n
      LEFT JOIN patient p ON n.patient_id = p.patient_id
      LEFT JOIN delivery d ON n.delivery_id = d.delivery_id
      ORDER BY n.birth_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching neonate:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch neonate data',
      message: err.message 
    });
  }
});

// Postnatal Care
app.get('/postnatal_care', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        pnc.postnatal_care_id,
        pnc.fhir_id,
        pnc.patient_id,
        pnc.encounter_id,
        pnc.neonate_id,
        pnc.visit_date,
        pnc.visit_type,
        pnc.maternal_weight_kg,
        pnc.maternal_bp_systolic,
        pnc.maternal_bp_diastolic,
        pnc.maternal_temperature,
        pnc.maternal_pulse,
        pnc.maternal_complaints,
        pnc.maternal_bleeding,
        pnc.maternal_lochia,
        pnc.neonate_weight_grams,
        pnc.neonate_temperature,
        pnc.neonate_feeding_status,
        pnc.neonate_health_status,
        pnc.neonate_jaundice,
        pnc.neonate_cord_status,
        pnc.dak_pnc_id,
        pnc.pnc_visit_number,
        pnc.days_postpartum,
        pnc.fhir_resource,
        pnc.version_id,
        pnc.created_at,
        pnc.updated_at,
        p.name as mother_name,
        p.identifier as mother_identifier,
        n.name as neonate_name,
        n.birth_date as neonate_birth_date,
        d.delivery_date,
        d.delivery_outcome
      FROM postnatal_care pnc
      LEFT JOIN patient p ON pnc.patient_id = p.patient_id
      LEFT JOIN neonate n ON pnc.neonate_id = n.neonate_id
      LEFT JOIN delivery d ON pnc.patient_id = d.patient_id
      ORDER BY pnc.visit_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching postnatal_care:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch postnatal_care data',
      message: err.message 
    });
  }
});

// Patient
app.get('/patient', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        patient_id,
        fhir_id,
        identifier,
        name,
        first_name,
        last_name,
        middle_name,
        gender,
        birth_date,
        age,
        marital_status,
        education_level,
        occupation,
        address,
        village,
        chiefdom,
        district,
        province,
        country,
        phone,
        alternative_phone,
        email,
        emergency_contact,
        emergency_phone,
        national_id,
        insurance_type,
        insurance_number,
        religion,
        ethnicity,
        language,
        dak_patient_id,
        registration_date,
        registration_source,
        created_at,
        updated_at
      FROM patient 
      ORDER BY created_at DESC
    `);
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching patient:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch patient data',
      message: err.message 
    });
  }
});

app.get('/api/patient/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        patient_id,
        fhir_id,
        identifier,
        name,
        first_name,
        last_name,
        middle_name,
        gender,
        birth_date,
        age,
        marital_status,
        education_level,
        occupation,
        address,
        village,
        chiefdom,
        district,
        province,
        country,
        phone,
        alternative_phone,
        email,
        emergency_contact,
        emergency_phone,
        national_id,
        insurance_type,
        insurance_number,
        religion,
        ethnicity,
        language,
        dak_patient_id,
        registration_date,
        registration_source,
        fhir_resource,
        version_id,
        created_at,
        updated_at
      FROM patient 
      WHERE patient_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Patient not found',
        message: `No patient found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching patient:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch patient data',
      message: err.message 
    });
  }
});

app.get('/api/patient', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM patient');
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching patient:', err);
    res.status(500).json({ error: 'Failed to fetch patient data' });
  }
});

// Organization
app.get('/organization', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        organization_id,
        fhir_id,
        name,
        type,
        address,
        phone,
        email,
        website,
        registration_number,
        license_number,
        facility_level,
        ownership_type,
        catchment_area,
        services_offered,
        fhir_resource,
        version_id,
        created_at,
        updated_at
      FROM organization 
      ORDER BY created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching organization:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch organization data',
      message: err.message 
    });
  }
});

// Admin - Updated to match new schema (using admins table)
app.get('/admin', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        id,
        fhir_id,
        dak_admin_id,
        username,
        email,
        full_name,
        role,
        practitioner_identifier,
        is_active,
        last_login,
        created_at,
        updated_at
      FROM admins 
      ORDER BY created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching admin:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch admin data',
      message: err.message 
    });
  }
});

// Encounter
app.get('/encounter', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        e.encounter_id,
        e.fhir_id,
        e.patient_id,
        e.organization_id,
        e.encounter_type,
        e.status,
        e.start_date,
        e.end_date,
        e.dak_encounter_id,
        e.encounter_reason,
        e.chief_complaint,
        e.vital_signs,
        e.physical_examination,
        e.fhir_resource,
        e.version_id,
        e.created_at,
        e.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier,
        o.name as organization_name
      FROM encounter e
      LEFT JOIN patient p ON e.patient_id = p.patient_id
      LEFT JOIN organization o ON e.organization_id = o.organization_id
      ORDER BY e.start_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching encounter:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch encounter data',
      message: err.message 
    });
  }
});

// Report - Updated to match new schema
app.get('/report', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        id,
        fhir_id,
        dak_report_id,
        client_number,
        client_name,
        phone_number,
        report_type,
        facility_name,
        organization_id,
        description,
        is_anonymous,
        is_read,
        last_read_at,
        reply,
        reply_sent_at,
        reply_sent_by,
        deleted,
        deleted_at,
        fhir_resource,
        version_id,
        last_updated,
        created_at,
        updated_at
      FROM reports 
      WHERE deleted = FALSE OR deleted IS NULL
      ORDER BY created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching report:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch report data',
      message: err.message 
    });
  }
});

// Observation
app.get('/observation', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        o.observation_id,
        o.fhir_id,
        o.patient_id,
        o.encounter_id,
        o.observation_code,
        o.observation_value,
        o.observation_unit,
        o.observation_date,
        o.observation_status,
        o.reference_range,
        o.interpretation,
        o.note,
        o.fhir_resource,
        o.version_id,
        o.created_at,
        o.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM observation o
      LEFT JOIN patient p ON o.patient_id = p.patient_id
      ORDER BY o.observation_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching observation:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch observation data',
      message: err.message 
    });
  }
});

// Condition
app.get('/condition', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        c.condition_id,
        c.fhir_id,
        c.patient_id,
        c.encounter_id,
        c.condition_code,
        c.condition_name,
        c.condition_category,
        c.clinical_status,
        c.verification_status,
        c.onset_date,
        c.abatement_date,
        c.severity,
        c.body_site,
        c.note,
        c.fhir_resource,
        c.version_id,
        c.created_at,
        c.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM condition c
      LEFT JOIN patient p ON c.patient_id = p.patient_id
      ORDER BY c.created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching condition:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch condition data',
      message: err.message 
    });
  }
});

// Procedure
app.get('/procedure', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        pr.procedure_id,
        pr.fhir_id,
        pr.patient_id,
        pr.encounter_id,
        pr.procedure_code,
        pr.procedure_name,
        pr.procedure_category,
        pr.status,
        pr.performed_date,
        pr.performed_period_start,
        pr.performed_period_end,
        pr.outcome,
        pr.complication,
        pr.follow_up,
        pr.note,
        pr.fhir_resource,
        pr.version_id,
        pr.created_at,
        pr.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM procedure pr
      LEFT JOIN patient p ON pr.patient_id = p.patient_id
      ORDER BY pr.performed_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching procedure:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch procedure data',
      message: err.message 
    });
  }
});

// Medication Statement
app.get('/medication_statement', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        ms.medication_statement_id,
        ms.fhir_id,
        ms.patient_id,
        ms.encounter_id,
        ms.medication_code,
        ms.medication_name,
        ms.status,
        ms.category,
        ms.dosage_instruction,
        ms.dosage_text,
        ms.dosage_quantity,
        ms.dosage_unit,
        ms.frequency,
        ms.route,
        ms.start_date,
        ms.end_date,
        ms.reason_code,
        ms.note,
        ms.fhir_resource,
        ms.version_id,
        ms.created_at,
        ms.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM medication_statement ms
      LEFT JOIN patient p ON ms.patient_id = p.patient_id
      ORDER BY ms.created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching medication_statement:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch medication_statement data',
      message: err.message 
    });
  }
});

// DAK Contact Schedule
app.get('/dak_contact_schedule', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        dcs.contact_id,
        dcs.fhir_id,
        dcs.patient_id,
        dcs.pregnancy_id,
        dcs.contact_number,
        dcs.recommended_gestation_weeks,
        dcs.contact_date,
        dcs.contact_status,
        dcs.contact_type,
        dcs.provider_notes,
        dcs.dak_contact_id,
        dcs.fhir_resource,
        dcs.version_id,
        dcs.created_at,
        dcs.updated_at,
        dcs.last_updated,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM dak_contact_schedule dcs
      LEFT JOIN patient p ON dcs.patient_id = p.patient_id
      ORDER BY dcs.contact_date DESC, dcs.contact_number ASC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_contact_schedule:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_contact_schedule data',
      message: err.message 
    });
  }
});

// DAK Risk Assessment
app.get('/dak_risk_assessment', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        dra.risk_id,
        dra.fhir_id,
        dra.patient_id,
        dra.encounter_id,
        dra.risk_category,
        dra.risk_factors,
        dra.risk_score,
        dra.risk_level,
        dra.management_plan,
        dra.follow_up_required,
        dra.dak_risk_id,
        dra.assessment_date,
        dra.assessor_name,
        dra.fhir_resource,
        dra.version_id,
        dra.created_at,
        dra.updated_at,
        dra.last_updated,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM dak_risk_assessment dra
      LEFT JOIN patient p ON dra.patient_id = p.patient_id
      ORDER BY dra.assessment_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_risk_assessment:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_risk_assessment data',
      message: err.message 
    });
  }
});

// DAK Quality Indicators
app.get('/dak_quality_indicators', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        dqi.indicator_id,
        dqi.fhir_id,
        dqi.patient_id,
        dqi.encounter_id,
        dqi.indicator_code,
        dqi.indicator_name,
        dqi.indicator_value,
        dqi.indicator_status,
        dqi.risk_flag,
        dqi.decision_support_message,
        dqi.next_visit_schedule,
        dqi.dak_indicator_id,
        dqi.measurement_date,
        dqi.target_value,
        dqi.fhir_resource,
        dqi.version_id,
        dqi.created_at,
        dqi.updated_at,
        dqi.last_updated,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM dak_quality_indicators dqi
      LEFT JOIN patient p ON dqi.patient_id = p.patient_id
      ORDER BY dqi.measurement_date DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_quality_indicators:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_quality_indicators data',
      message: err.message 
    });
  }
});

// DAK Configuration
app.get('/dak_configuration', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        dc.config_id,
        dc.fhir_id,
        dc.config_key,
        dc.config_value,
        dc.config_description,
        dc.config_category,
        dc.is_active,
        dc.dak_config_id,
        dc.fhir_resource,
        dc.version_id,
        dc.created_at,
        dc.updated_at,
        dc.last_updated
      FROM dak_configuration dc
      ORDER BY dc.created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_configuration:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_configuration data',
      message: err.message 
    });
  }
});

// Tips - Updated to match new schema
app.get('/tips', async (req, res) => {
  try {
    const { category, is_active, trimester } = req.query;
    let query = `
      SELECT 
        t.id,
        t.fhir_id,
        t.dak_tip_id,
        t.title,
        t.category,
        t.content,
        t.trimester,
        t.visit,
        t.schedule,
        t.weeks,
        t.is_active,
        t.fhir_resource,
        t.version_id,
        t.last_updated,
        t.created_at,
        t.updated_at
      FROM tips t
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 0;
    
    if (category) {
      paramCount++;
      query += ` AND t.category = $${paramCount}`;
      params.push(category);
    }
    
    if (is_active !== undefined) {
      paramCount++;
      query += ` AND t.is_active = $${paramCount}`;
      params.push(is_active === 'true');
    }
    
    if (trimester) {
      paramCount++;
      query += ` AND (t.trimester = $${paramCount} OR t.trimester IS NULL)`;
      params.push(trimester);
    }
    
    query += ` ORDER BY t.created_at DESC`;
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching tips:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch tips data',
      message: err.message 
    });
  }
});

// Chat Threads - Updated to match new schema
app.get('/chat_threads', async (req, res) => {
  try {
    // First check if table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'chat_threads'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      return res.json({
        success: true,
        data: [],
        total: 0,
        timestamp: new Date().toISOString(),
        message: 'chat_threads table does not exist yet'
      });
    }
    
    // Try with JOIN first, fallback to simple query if JOIN fails
    let result;
    try {
      result = await pool.query(`
      SELECT 
        ct.id,
        ct.fhir_id,
        ct.dak_thread_id,
        ct.user_id,
        ct.health_worker_id,
        ct.patient_id,
        ct.organization_id,
        ct.last_message,
        ct.last_message_time,
        ct.unread_count,
        ct.updated_by,
        ct.fhir_resource,
        ct.version_id,
        ct.last_updated,
        ct.created_at,
        ct.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM chat_threads ct
      LEFT JOIN patient p ON ct.patient_id = p.patient_id
      ORDER BY ct.last_message_time DESC NULLS LAST, ct.created_at DESC
    `);
    } catch (joinErr) {
      // If JOIN fails, try without JOIN
      console.warn('JOIN failed, trying without patient table:', joinErr.message);
      result = await pool.query(`
        SELECT 
          id,
          fhir_id,
          dak_thread_id,
          user_id,
          health_worker_id,
          patient_id,
          organization_id,
          last_message,
          last_message_time,
          unread_count,
          updated_by,
          fhir_resource,
          version_id,
          last_updated,
          created_at,
          updated_at
        FROM chat_threads
        ORDER BY last_message_time DESC NULLS LAST, created_at DESC
      `);
      
      // Add null patient fields
      result.rows = result.rows.map(row => ({
        ...row,
        patient_name: null,
        patient_identifier: null
      }));
    }
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching chat_threads:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch chat_threads data',
      message: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

// Chat Messages - Updated to match new schema
app.get('/chat_messages', async (req, res) => {
  try {
    // First check if table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'chat_messages'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      return res.json({
        success: true,
        data: [],
        total: 0,
        timestamp: new Date().toISOString(),
        message: 'chat_messages table does not exist yet'
      });
    }
    
    // Try with JOIN first, fallback to simple query if JOIN fails
    let result;
    try {
      result = await pool.query(`
      SELECT 
        cm.id,
        cm.fhir_id,
        cm.dak_message_id,
        cm.thread_id,
        cm.sender_id,
        cm.receiver_id,
        cm.sender_type,
        cm.patient_id,
        cm.organization_id,
        cm.message,
        cm.is_read,
        cm.fhir_resource,
        cm.version_id,
        cm.last_updated,
        cm.created_at,
        cm.updated_at,
        p.name as sender_name,
        p.identifier as sender_identifier
      FROM chat_messages cm
      LEFT JOIN patient p ON cm.patient_id = p.patient_id
      ORDER BY cm.created_at DESC
    `);
    } catch (joinErr) {
      // If JOIN fails, try without JOIN
      console.warn('JOIN failed, trying without patient table:', joinErr.message);
      result = await pool.query(`
        SELECT 
          id,
          fhir_id,
          dak_message_id,
          thread_id,
          sender_id,
          receiver_id,
          sender_type,
          patient_id,
          organization_id,
          message,
          is_read,
          fhir_resource,
          version_id,
          last_updated,
          created_at,
          updated_at
        FROM chat_messages
        ORDER BY created_at DESC
      `);
      
      // Add null patient fields
      result.rows = result.rows.map(row => ({
        ...row,
        sender_name: null,
        sender_identifier: null
      }));
    }
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching chat_messages:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch chat_messages data',
      message: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

// Reports - Updated to match new schema
app.get('/reports', async (req, res) => {
  try {
    const { is_read, deleted } = req.query;
    let query = `
      SELECT 
        id,
        fhir_id,
        dak_report_id,
        client_number,
        client_name,
        phone_number,
        report_type,
        facility_name,
        organization_id,
        description,
        is_anonymous,
        is_read,
        last_read_at,
        reply,
        reply_sent_at,
        reply_sent_by,
        deleted,
        deleted_at,
        fhir_resource,
        version_id,
        last_updated,
        created_at,
        updated_at
      FROM reports 
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 0;
    
    if (is_read !== undefined) {
      paramCount++;
      query += ` AND is_read = $${paramCount}`;
      params.push(is_read === 'true');
    }
    
    if (deleted === 'false' || deleted === undefined) {
      query += ` AND (deleted = FALSE OR deleted IS NULL)`;
    } else if (deleted === 'true') {
      query += ` AND deleted = TRUE`;
    }
    
    query += ` ORDER BY created_at DESC`;
    
    const result = await pool.query(query, params);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching reports:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch reports data',
      message: err.message 
    });
  }
});

// Admins - Updated to match new schema
app.get('/admins', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        a.id,
        a.fhir_id,
        a.dak_admin_id,
        a.username,
        a.email,
        a.full_name,
        a.role,
        a.practitioner_identifier,
        a.is_active,
        a.last_login,
        a.fhir_resource,
        a.version_id,
        a.last_updated,
        a.created_at,
        a.updated_at
      FROM admins a
      ORDER BY a.created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching admins:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch admins data',
      message: err.message 
    });
  }
});

// FHIR Resources
app.get('/fhir_resources', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        fr.id,
        fr.resource_type,
        fr.resource_id,
        fr.data,
        fr.meta,
        fr.created_at,
        fr.updated_at
      FROM fhir_resources fr
      ORDER BY fr.created_at DESC
    `);
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching fhir_resources:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch fhir_resources data',
      message: err.message 
    });
  }
});

// Chat messages (legacy endpoint for backward compatibility)
app.get('/chat_message', async (req, res) => {
  try {
    // First check if table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'chat_message'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      return res.json({
        success: true,
        data: [],
        total: 0,
        timestamp: new Date().toISOString(),
        message: 'chat_message table does not exist yet'
      });
    }
    
    // Try with JOIN first, fallback to simple query if JOIN fails
    let result;
    try {
      result = await pool.query(`
      SELECT 
        cm.id,
        cm.chat_id,
        cm.sender_id,
        cm.receiver_id,
        cm.message,
        cm.reply,
        cm.is_read,
        cm.who_guideline,
        cm.dak_guideline,
        cm.fhir_resource,
        cm.created_at,
        cm.updated_at,
          cm.timestamp,
        p.name as sender_name,
        p.identifier as sender_identifier
      FROM chat_message cm
        LEFT JOIN patient p ON cm.sender_id = p.patient_id OR cm.sender_id = p.identifier
        ORDER BY COALESCE(cm.timestamp, cm.created_at) DESC
      `);
    } catch (joinErr) {
      // If JOIN fails, try without JOIN
      console.warn('JOIN failed, trying without patient table:', joinErr.message);
      result = await pool.query(`
        SELECT 
          id,
          chat_id,
          sender_id,
          receiver_id,
          message,
          reply,
          is_read,
          who_guideline,
          dak_guideline,
          fhir_resource,
          created_at,
          updated_at,
          timestamp
        FROM chat_message
        ORDER BY COALESCE(timestamp, created_at) DESC
      `);
      
      // Add null patient fields
      result.rows = result.rows.map(row => ({
        ...row,
        sender_name: null,
        sender_identifier: null
      }));
    }
    
    res.json({
      success: true,
      data: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching chat_message:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch chat_message data',
      message: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

// Individual ID endpoints for new tables

// Observation by ID
app.get('/observation/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        o.*,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM observation o
      LEFT JOIN patient p ON o.patient_id = p.patient_id
      WHERE o.observation_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Observation not found',
        message: `No observation found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching observation:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch observation data',
      message: err.message 
    });
  }
});

// Condition by ID
app.get('/condition/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        c.*,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM condition c
      LEFT JOIN patient p ON c.patient_id = p.patient_id
      WHERE c.condition_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Condition not found',
        message: `No condition found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching condition:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch condition data',
      message: err.message 
    });
  }
});

// Procedure by ID
app.get('/procedure/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        pr.*,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM procedure pr
      LEFT JOIN patient p ON pr.patient_id = p.patient_id
      WHERE pr.procedure_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Procedure not found',
        message: `No procedure found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching procedure:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch procedure data',
      message: err.message 
    });
  }
});

// Medication Statement by ID
app.get('/medication_statement/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        ms.*,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM medication_statement ms
      LEFT JOIN patient p ON ms.patient_id = p.patient_id
      WHERE ms.medication_statement_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Medication statement not found',
        message: `No medication statement found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching medication_statement:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch medication_statement data',
      message: err.message 
    });
  }
});

// DAK Contact Schedule by ID
app.get('/dak_contact_schedule/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        dcs.*,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM dak_contact_schedule dcs
      LEFT JOIN patient p ON dcs.patient_id = p.patient_id
      WHERE dcs.contact_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'DAK contact schedule not found',
        message: `No DAK contact schedule found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_contact_schedule:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_contact_schedule data',
      message: err.message 
    });
  }
});

// DAK Risk Assessment by ID
app.get('/dak_risk_assessment/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        dra.*,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM dak_risk_assessment dra
      LEFT JOIN patient p ON dra.patient_id = p.patient_id
      WHERE dra.risk_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'DAK risk assessment not found',
        message: `No DAK risk assessment found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_risk_assessment:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_risk_assessment data',
      message: err.message 
    });
  }
});

// DAK Quality Indicators by ID
app.get('/dak_quality_indicators/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        dqi.*,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM dak_quality_indicators dqi
      LEFT JOIN patient p ON dqi.patient_id = p.patient_id
      WHERE dqi.indicator_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'DAK quality indicator not found',
        message: `No DAK quality indicator found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_quality_indicators:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_quality_indicators data',
      message: err.message 
    });
  }
});

// DAK Configuration by ID
app.get('/dak_configuration/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT * FROM dak_configuration WHERE config_id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'DAK configuration not found',
        message: `No DAK configuration found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching dak_configuration:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch dak_configuration data',
      message: err.message 
    });
  }
});

// Tips by ID - Updated to match new schema
app.get('/tips/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        id,
        fhir_id,
        dak_tip_id,
        title,
        category,
        content,
        trimester,
        visit,
        schedule,
        weeks,
        is_active,
        fhir_resource,
        version_id,
        last_updated,
        created_at,
        updated_at
      FROM tips 
      WHERE id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Tip not found',
        message: `No tip found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching tips:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch tips data',
      message: err.message 
    });
  }
});

// Chat Threads by ID - Updated to match new schema
app.get('/chat_threads/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        ct.id,
        ct.fhir_id,
        ct.dak_thread_id,
        ct.user_id,
        ct.health_worker_id,
        ct.patient_id,
        ct.organization_id,
        ct.last_message,
        ct.last_message_time,
        ct.unread_count,
        ct.updated_by,
        ct.fhir_resource,
        ct.version_id,
        ct.last_updated,
        ct.created_at,
        ct.updated_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM chat_threads ct
      LEFT JOIN patient p ON ct.patient_id = p.patient_id
      WHERE ct.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Chat thread not found',
        message: `No chat thread found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching chat_threads:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch chat_threads data',
      message: err.message 
    });
  }
});

// Chat Messages by ID - Updated to match new schema
app.get('/chat_messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        cm.id,
        cm.fhir_id,
        cm.dak_message_id,
        cm.thread_id,
        cm.sender_id,
        cm.receiver_id,
        cm.sender_type,
        cm.patient_id,
        cm.organization_id,
        cm.message,
        cm.is_read,
        cm.fhir_resource,
        cm.version_id,
        cm.last_updated,
        cm.created_at,
        cm.updated_at,
        p.name as sender_name,
        p.identifier as sender_identifier
      FROM chat_messages cm
      LEFT JOIN patient p ON cm.patient_id = p.patient_id
      WHERE cm.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Chat message not found',
        message: `No chat message found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching chat_messages:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch chat_messages data',
      message: err.message 
    });
  }
});

// Reports by ID - Updated to match new schema
app.get('/reports/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        id,
        fhir_id,
        dak_report_id,
        client_number,
        client_name,
        phone_number,
        report_type,
        facility_name,
        organization_id,
        description,
        is_anonymous,
        is_read,
        last_read_at,
        reply,
        reply_sent_at,
        reply_sent_by,
        deleted,
        deleted_at,
        fhir_resource,
        version_id,
        last_updated,
        created_at,
        updated_at
      FROM reports 
      WHERE id = $1 AND (deleted = FALSE OR deleted IS NULL)
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Report not found',
        message: `No report found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching reports:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch reports data',
      message: err.message 
    });
  }
});

// Admins by ID - Updated to match new schema
app.get('/admins/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT 
        id,
        fhir_id,
        dak_admin_id,
        username,
        email,
        full_name,
        role,
        practitioner_identifier,
        is_active,
        last_login,
        fhir_resource,
        version_id,
        last_updated,
        created_at,
        updated_at
      FROM admins 
      WHERE id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'Admin not found',
        message: `No admin found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching admins:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch admins data',
      message: err.message 
    });
  }
});

// Update Admin (password, email, etc.)
app.put('/admins/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { email, password, full_name, role, username } = req.body;
    
    // Build dynamic update query
    const updates = [];
    const values = [];
    let paramIndex = 1;
    
    if (email) {
      updates.push(`email = $${paramIndex++}`);
      values.push(email);
    }
    if (password) {
      const password_hash = await bcrypt.hash(password, 10);
      updates.push(`password_hash = $${paramIndex++}`);
      values.push(password_hash);
    }
    if (full_name) {
      updates.push(`full_name = $${paramIndex++}`);
      values.push(full_name);
    }
    if (role) {
      updates.push(`role = $${paramIndex++}`);
      values.push(role);
    }
    if (username) {
      updates.push(`username = $${paramIndex++}`);
      values.push(username);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update',
        message: 'Please provide at least one field to update (email, password, full_name, role, username)'
      });
    }
    
    values.push(id);
    const query = `UPDATE admins SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = $${paramIndex} RETURNING id, username, email, full_name, role`;
    
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Admin not found',
        message: `No admin found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      message: 'Admin updated successfully',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error updating admin:', err);
    res.status(500).json({
      success: false,
      error: 'Failed to update admin',
      message: err.message
    });
  }
});

// FHIR Resources by ID
app.get('/fhir_resources/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT * FROM fhir_resources WHERE id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'FHIR resource not found',
        message: `No FHIR resource found with ID: ${id}`
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0],
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error fetching fhir_resources:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch fhir_resources data',
      message: err.message 
    });
  }
});

// FHIR R4 Resource Search Endpoint
app.get('/fhir/:resourceType', async (req, res) => {
  const { resourceType } = req.params;
  const queryParams = req.query;

  try {
    // Validate resource type
    const validResourceTypes = ['Patient', 'Observation', 'Encounter', 'Condition', 'Communication', 'Organization', 'Procedure'];
    if (!validResourceTypes.includes(resourceType)) {
      return res.status(400).json({
        resourceType: 'OperationOutcome',
        issue: [
          {
            severity: 'error',
            code: 'not-supported',
            diagnostics: `Resource type ${resourceType} is not supported`
          }
        ]
      });
    }

    // Fetch data from database and convert to FHIR resources
    let resources = [];
    
    if (resourceType === 'Patient') {
      // Build search query based on FHIR search parameters
      let whereConditions = [];
      let searchParams = [];
      let paramCount = 1;
      
      // Handle FHIR search parameters
      if (queryParams.name) {
        whereConditions.push(`(name ILIKE $${paramCount} OR first_name ILIKE $${paramCount} OR last_name ILIKE $${paramCount})`);
        searchParams.push(`%${queryParams.name}%`);
        paramCount++;
      }
      
      if (queryParams.identifier) {
        whereConditions.push(`identifier = $${paramCount}`);
        searchParams.push(queryParams.identifier);
        paramCount++;
      }
      
      if (queryParams.gender) {
        whereConditions.push(`gender = $${paramCount}`);
        searchParams.push(queryParams.gender);
        paramCount++;
      }
      
      if (queryParams.birthdate) {
        whereConditions.push(`birth_date = $${paramCount}`);
        searchParams.push(queryParams.birthdate);
        paramCount++;
      }
      
      if (queryParams.telecom) {
        whereConditions.push(`(phone ILIKE $${paramCount} OR email ILIKE $${paramCount})`);
        searchParams.push(`%${queryParams.telecom}%`);
        paramCount++;
      }
      
      if (queryParams.address) {
        whereConditions.push(`(address ILIKE $${paramCount} OR village ILIKE $${paramCount} OR district ILIKE $${paramCount})`);
        searchParams.push(`%${queryParams.address}%`);
        paramCount++;
      }
      
      const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';
      
      const result = await pool.query(`
        SELECT 
          patient_id,
          fhir_id,
          identifier,
          name,
          first_name,
          last_name,
          middle_name,
          gender,
          birth_date,
          age,
          phone,
          email,
          address,
          village,
          chiefdom,
          district,
          province,
          country,
          created_at,
          updated_at
        FROM patient 
        ${whereClause}
        ORDER BY created_at DESC
      `, searchParams);
      
      // Convert database records to FHIR Patient resources
      resources = result.rows.map(row => ({
        resourceType: 'Patient',
        id: row.fhir_id || `patient-${row.patient_id}`,
        identifier: [
          {
            use: 'usual',
            system: 'https://healthymamaapp.com/patient-identifier',
            value: row.identifier
          }
        ],
        name: [
          {
            use: 'official',
            family: row.last_name || row.name.split(' ').pop(),
            given: row.first_name ? [row.first_name] : row.name.split(' ').slice(0, -1)
          }
        ],
        gender: row.gender,
        birthDate: row.birth_date,
        telecom: [
          ...(row.phone ? [{
            system: 'phone',
            value: row.phone,
            use: 'mobile'
          }] : []),
          ...(row.email ? [{
            system: 'email',
            value: row.email,
            use: 'home'
          }] : [])
        ],
        address: [
          {
            use: 'home',
            text: row.address || `${row.village}, ${row.chiefdom}, ${row.district}, ${row.province}, ${row.country}`,
            line: [row.address || ''],
            city: row.village,
            district: row.district,
            state: row.province,
            country: row.country
          }
        ],
        meta: {
          lastUpdated: row.updated_at || row.created_at
        }
      }));
    } else if (resourceType === 'Observation') {
      const result = await pool.query(`
        SELECT 
          observation_id,
          fhir_id,
          encounter_id,
          patient_id,
          observation_type,
          observation_code,
          observation_name,
          value_string,
          value_number,
          value_date,
          value_boolean,
          unit,
          reference_range,
          interpretation,
          status,
          created_at,
          updated_at
        FROM observation 
        ORDER BY created_at DESC
      `);
      
      resources = result.rows.map(row => ({
        resourceType: 'Observation',
        id: row.fhir_id || `observation-${row.observation_id}`,
        status: row.status || 'final',
        code: {
          coding: [
            {
              system: 'http://loinc.org',
              code: row.observation_code || 'unknown',
              display: row.observation_name || row.observation_type
            }
          ]
        },
        subject: {
          reference: `Patient/${row.patient_id}`,
          type: 'Patient'
        },
        encounter: row.encounter_id ? {
          reference: `Encounter/${row.encounter_id}`,
          type: 'Encounter'
        } : undefined,
        valueString: row.value_string,
        valueQuantity: row.value_number ? {
          value: row.value_number,
          unit: row.unit || '',
          system: 'http://unitsofmeasure.org',
          code: row.unit || ''
        } : undefined,
        valueDateTime: row.value_date,
        valueBoolean: row.value_boolean,
        referenceRange: row.reference_range ? [
          {
            text: row.reference_range
          }
        ] : undefined,
        interpretation: row.interpretation ? [
          {
            coding: [
              {
                system: 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
                code: row.interpretation.toLowerCase(),
                display: row.interpretation
              }
            ]
          }
        ] : undefined,
        meta: {
          lastUpdated: row.updated_at || row.created_at
        }
      }));
    } else if (resourceType === 'Encounter') {
      const result = await pool.query(`
        SELECT 
          encounter_id,
          fhir_id,
          patient_id,
          organization_id,
          encounter_type,
          status,
          start_date,
          end_date,
          encounter_reason,
          chief_complaint,
          created_at,
          updated_at
        FROM encounter 
        ORDER BY created_at DESC
      `);
      
      resources = result.rows.map(row => ({
        resourceType: 'Encounter',
        id: row.fhir_id || `encounter-${row.encounter_id}`,
        status: row.status || 'finished',
        class: {
          system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
          code: row.encounter_type === 'anc_visit' ? 'AMB' : 'AMB',
          display: row.encounter_type === 'anc_visit' ? 'Ambulatory' : 'Ambulatory'
        },
        subject: {
          reference: `Patient/${row.patient_id}`,
          type: 'Patient'
        },
        serviceProvider: row.organization_id ? {
          reference: `Organization/${row.organization_id}`,
          type: 'Organization'
        } : undefined,
        reasonCode: row.encounter_reason ? [
          {
            text: row.encounter_reason
          }
        ] : undefined,
        chiefComplaint: row.chief_complaint ? [
          {
            text: row.chief_complaint
          }
        ] : undefined,
        period: {
          start: row.start_date,
          end: row.end_date
        },
        meta: {
          lastUpdated: row.updated_at || row.created_at
        }
      }));
    } else if (resourceType === 'Condition') {
      const result = await pool.query(`
        SELECT 
          condition_id,
          fhir_id,
          patient_id,
          encounter_id,
          condition_code,
          condition_name,
          condition_category,
          severity,
          status,
          onset_date,
          resolution_date,
          created_at,
          updated_at
        FROM condition 
        ORDER BY created_at DESC
      `);
      
      resources = result.rows.map(row => ({
        resourceType: 'Condition',
        id: row.fhir_id || `condition-${row.condition_id}`,
        clinicalStatus: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/condition-clinical',
              code: row.status === 'active' ? 'active' : 'resolved',
              display: row.status === 'active' ? 'Active' : 'Resolved'
            }
          ]
        },
        verificationStatus: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
              code: 'confirmed',
              display: 'Confirmed'
            }
          ]
        },
        category: row.condition_category ? [
          {
            coding: [
              {
                system: 'http://terminology.hl7.org/CodeSystem/condition-category',
                code: row.condition_category.toLowerCase(),
                display: row.condition_category
              }
            ]
          }
        ] : undefined,
        severity: row.severity ? {
          coding: [
            {
              system: 'http://snomed.info/sct',
              code: row.severity.toLowerCase(),
              display: row.severity
            }
          ]
        } : undefined,
        code: {
          coding: [
            {
              system: 'http://hl7.org/fhir/sid/icd-10',
              code: row.condition_code || 'unknown',
              display: row.condition_name
            }
          ]
        },
        subject: {
          reference: `Patient/${row.patient_id}`,
          type: 'Patient'
        },
        encounter: row.encounter_id ? {
          reference: `Encounter/${row.encounter_id}`,
          type: 'Encounter'
        } : undefined,
        onsetDateTime: row.onset_date,
        abatementDateTime: row.resolution_date,
        meta: {
          lastUpdated: row.updated_at || row.created_at
        }
      }));
    } else if (resourceType === 'Communication') {
      const result = await pool.query(`
        SELECT 
          id,
          fhir_id,
          thread_id,
          sender_id,
          receiver_id,
          sender_type,
          patient_id,
          organization_id,
          message,
          is_read,
          created_at,
          updated_at
        FROM chat_messages 
        ORDER BY created_at DESC
      `);
      
      resources = result.rows.map(row => ({
        resourceType: 'Communication',
        id: row.fhir_id || `communication-${row.id}`,
        status: 'completed',
        sent: row.created_at,
        sender: {
          reference: row.sender_type === 'patient' ? `Patient/${row.patient_id}` : `Practitioner/${row.sender_id}`,
          type: row.sender_type === 'patient' ? 'Patient' : 'Practitioner'
        },
        recipient: {
          reference: row.sender_type === 'patient' ? `Practitioner/${row.receiver_id}` : `Patient/${row.patient_id}`,
          type: row.sender_type === 'patient' ? 'Practitioner' : 'Patient'
        },
        subject: row.patient_id ? {
          reference: `Patient/${row.patient_id}`,
          type: 'Patient'
        } : undefined,
        payload: [
          {
            contentString: row.message
          }
        ],
        meta: {
          lastUpdated: row.updated_at || row.created_at
        }
      }));
    } else if (resourceType === 'Organization') {
      const result = await pool.query(`
        SELECT 
          organization_id,
          fhir_id,
          name,
          type,
          address,
          phone,
          email,
          website,
          registration_number,
          license_number,
          facility_level,
          ownership_type,
          catchment_area,
          services_offered,
          created_at,
          updated_at
        FROM organization 
        ORDER BY created_at DESC
      `);
      
      resources = result.rows.map(row => ({
        resourceType: 'Organization',
        id: row.fhir_id || `organization-${row.organization_id}`,
        name: row.name,
        type: [
          {
            coding: [
              {
                system: 'http://terminology.hl7.org/CodeSystem/organization-type',
                code: row.type.toLowerCase().replace(' ', '-'),
                display: row.type
              }
            ]
          }
        ],
        address: row.address ? [
          {
            use: 'work',
            text: row.address,
            type: 'physical'
          }
        ] : undefined,
        telecom: [
          ...(row.phone ? [{
            system: 'phone',
            value: row.phone,
            use: 'work'
          }] : []),
          ...(row.email ? [{
            system: 'email',
            value: row.email,
            use: 'work'
          }] : []),
          ...(row.website ? [{
            system: 'url',
            value: row.website,
            use: 'work'
          }] : [])
        ],
        identifier: [
          ...(row.registration_number ? [{
            use: 'official',
            system: 'https://healthymamaapp.com/organization-registration',
            value: row.registration_number
          }] : []),
          ...(row.license_number ? [{
            use: 'secondary',
            system: 'https://healthymamaapp.com/organization-license',
            value: row.license_number
          }] : [])
        ],
        meta: {
          lastUpdated: row.updated_at || row.created_at
        }
      }));
    } else if (resourceType === 'Procedure') {
      const result = await pool.query(`
        SELECT 
          procedure_id,
          fhir_id,
          patient_id,
          encounter_id,
          procedure_code,
          procedure_name,
          procedure_category,
          status,
          performed_date,
          performed_time,
          indication,
          complications,
          outcome,
          created_at,
          updated_at
        FROM procedure 
        ORDER BY created_at DESC
      `);
      
      resources = result.rows.map(row => ({
        resourceType: 'Procedure',
        id: row.fhir_id || `procedure-${row.procedure_id}`,
        status: row.status || 'completed',
        code: {
          coding: [
            {
              system: 'http://www.ama-assn.org/go/cpt',
              code: row.procedure_code || 'unknown',
              display: row.procedure_name
            }
          ]
        },
        category: row.procedure_category ? {
          coding: [
            {
              system: 'http://snomed.info/sct',
              code: row.procedure_category.toLowerCase().replace(' ', '-'),
              display: row.procedure_category
            }
          ]
        } : undefined,
        subject: {
          reference: `Patient/${row.patient_id}`,
          type: 'Patient'
        },
        encounter: row.encounter_id ? {
          reference: `Encounter/${row.encounter_id}`,
          type: 'Encounter'
        } : undefined,
        performedDateTime: row.performed_date && row.performed_time ? 
          `${row.performed_date}T${row.performed_time}` : row.performed_date,
        reasonCode: row.indication ? [
          {
            text: row.indication
          }
        ] : undefined,
        complication: row.complications ? [
          {
            text: row.complications
          }
        ] : undefined,
        outcome: row.outcome ? {
          coding: [
            {
              system: 'http://snomed.info/sct',
              code: row.outcome.toLowerCase().replace(' ', '-'),
              display: row.outcome
            }
          ]
        } : undefined,
        meta: {
          lastUpdated: row.updated_at || row.created_at
        }
      }));
    }
    
    // Create FHIR R4 compliant Bundle response
    const bundle = {
      resourceType: 'Bundle',
      id: uuidv4(),
      type: 'searchset',
      total: resources.length,
      link: [
        {
          relation: 'self',
          url: `${req.protocol}://${req.get('host')}${req.originalUrl}`
        }
      ],
      entry: resources.map(resource => ({
        fullUrl: `${req.protocol}://${req.get('host')}/fhir/${resourceType}/${resource.id}`,
        resource: resource
      }))
    };
    
    res.set('Content-Type', 'application/fhir+json');
    res.json(bundle);
  } catch (error) {
    console.error('Error fetching FHIR resources:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error fetching FHIR resources'
        }
      ]
    });
  }
});

// FHIR R4 Read Resource Endpoint
app.get('/fhir/:resourceType/:id', async (req, res) => {
  const { resourceType, id } = req.params;
  
  try {
    // For now, return not found since fhir_resources table doesn't exist
    // TODO: Implement proper FHIR resource creation from existing tables
    return res.status(404).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'not-found',
          diagnostics: `Resource ${resourceType}/${id} not found`
        }
      ]
    });
  } catch (error) {
    console.error('Error reading FHIR resource:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error reading FHIR resource'
        }
      ]
    });
  }
});

// FHIR R4 Create Resource Endpoint
app.post('/fhir/:resourceType', async (req, res) => {
  const { resourceType } = req.params;
  const resource = req.body;
  
  try {
    // Validate resource type
    const validResourceTypes = ['Patient', 'Observation', 'Encounter', 'Condition', 'Communication', 'Organization', 'Procedure'];
    if (!validResourceTypes.includes(resourceType)) {
      return res.status(400).json({
        resourceType: 'OperationOutcome',
        issue: [
          {
            severity: 'error',
            code: 'not-supported',
            diagnostics: `Resource type ${resourceType} is not supported`
          }
        ]
      });
    }

    // Set resource type and ID
    resource.resourceType = resourceType;
    const resourceId = resource.id || uuidv4();
    resource.id = resourceId;

    // Validate resource using FHIR compliance module
    const validation = fhirCompliance.validateFhirResource(resource);
    if (!validation.valid) {
      return res.status(400).json({
        resourceType: 'OperationOutcome',
        issue: validation.errors.map(error => ({
          severity: 'error',
          code: 'invalid',
          diagnostics: error
        }))
      });
    }

    // Additional FHIR validation
    const fhirValidation = fhir.validate(resource);
    if (!fhirValidation.valid) {
      return res.status(400).json({
        resourceType: 'OperationOutcome',
        issue: [
          {
            severity: 'error',
            code: 'invalid',
            diagnostics: 'Invalid FHIR resource structure',
            details: fhirValidation
          }
        ]
      });
    }

    // For now, return not implemented since fhir_resources table doesn't exist
    // TODO: Implement proper FHIR resource creation from existing tables
    return res.status(501).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'not-supported',
          diagnostics: 'FHIR resource creation not yet implemented'
        }
      ]
    });
  } catch (error) {
    console.error('Error creating FHIR resource:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error creating FHIR resource'
        }
      ]
    });
  }
});

// Update FHIR resource
app.put('/fhir/:resourceType/:id', async (req, res) => {
  const { resourceType, id } = req.params;
  const resource = req.body;
  resource.id = id;

  // For now, return not implemented since fhir_resources table doesn't exist
  return res.status(501).json({
    resourceType: 'OperationOutcome',
    issue: [
      {
        severity: 'error',
        code: 'not-supported',
        diagnostics: 'FHIR resource update not yet implemented'
      }
    ]
  });
});

// FHIR R4 Delete Resource Endpoint
app.delete('/fhir/:resourceType/:id', async (req, res) => {
  const { resourceType, id } = req.params;
  
  try {
    // For now, return not implemented since fhir_resources table doesn't exist
    return res.status(501).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'not-supported',
          diagnostics: 'FHIR resource deletion not yet implemented'
        }
      ]
    });
  } catch (error) {
    console.error('Error deleting FHIR resource:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error deleting FHIR resource'
        }
      ]
    });
  }
});

// FHIR R4 Operations
app.post('/fhir/:resourceType/$validate', async (req, res) => {
  const { resourceType } = req.params;
  const resource = req.body;
  
  try {
    // Validate resource type
    const validResourceTypes = ['Patient', 'Observation', 'Encounter', 'Condition', 'Communication', 'Organization', 'Procedure'];
    if (!validResourceTypes.includes(resourceType)) {
      return res.status(400).json({
        resourceType: 'OperationOutcome',
        issue: [
          {
            severity: 'error',
            code: 'not-supported',
            diagnostics: `Resource type ${resourceType} is not supported`
          }
        ]
      });
    }

    // Validate resource
    const validation = fhirCompliance.validateFhirResource(resource);
    const fhirValidation = fhir.validate(resource);
    
    const operationOutcome = {
      resourceType: 'OperationOutcome',
      issue: []
    };

    if (!validation.valid) {
      operationOutcome.issue.push(...validation.errors.map(error => ({
        severity: 'error',
        code: 'invalid',
        diagnostics: error
      })));
    }

    if (!fhirValidation.valid) {
      operationOutcome.issue.push({
        severity: 'error',
        code: 'invalid',
        diagnostics: 'FHIR structure validation failed',
        details: fhirValidation
      });
    }

    if (operationOutcome.issue.length === 0) {
      operationOutcome.issue.push({
        severity: 'information',
        code: 'informational',
        diagnostics: 'Resource validation successful'
      });
    }

    res.set('Content-Type', 'application/fhir+json');
    res.json(operationOutcome);
  } catch (error) {
    console.error('Error validating FHIR resource:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error validating FHIR resource'
        }
      ]
    });
  }
});

// FHIR R4 Patient Everything Operation
app.get('/fhir/Patient/:id/$everything', async (req, res) => {
  const { id } = req.params;
  const { start, end } = req.query;
  
  try {
    // Get patient
    const patientResult = await pool.query(
      'SELECT data FROM fhir_resources WHERE resource_type = $1 AND resource_id = $2',
      ['Patient', id]
    );
    
    if (patientResult.rows.length === 0) {
      return res.status(404).json({
        resourceType: 'OperationOutcome',
        issue: [
          {
            severity: 'error',
            code: 'not-found',
            diagnostics: `Patient ${id} not found`
          }
        ]
      });
    }

    const patient = patientResult.rows[0].data;
    
    // Get all related resources
    const relatedResources = [];
    
    // Get observations
    const obsResult = await pool.query(
      'SELECT data FROM fhir_resources WHERE resource_type = $1 AND data->>\'subject\' = $2',
      ['Observation', `Patient/${id}`]
    );
    relatedResources.push(...obsResult.rows.map(row => row.data));
    
    // Get encounters
    const encResult = await pool.query(
      'SELECT data FROM fhir_resources WHERE resource_type = $1 AND data->>\'subject\' = $2',
      ['Encounter', `Patient/${id}`]
    );
    relatedResources.push(...encResult.rows.map(row => row.data));
    
    // Get conditions
    const condResult = await pool.query(
      'SELECT data FROM fhir_resources WHERE resource_type = $1 AND data->>\'subject\' = $2',
      ['Condition', `Patient/${id}`]
    );
    relatedResources.push(...condResult.rows.map(row => row.data));
    
    // Get communications
    const commResult = await pool.query(
      'SELECT data FROM fhir_resources WHERE resource_type = $1 AND (data->>\'subject\' = $2 OR data->>\'sender\' = $2 OR data->>\'recipient\' = $2)',
      ['Communication', `Patient/${id}`]
    );
    relatedResources.push(...commResult.rows.map(row => row.data));
    
    // Create bundle
    const bundle = {
      resourceType: 'Bundle',
      id: uuidv4(),
      type: 'searchset',
      total: relatedResources.length + 1,
      entry: [
        {
          fullUrl: `${req.protocol}://${req.get('host')}/fhir/Patient/${id}`,
          resource: patient
        },
        ...relatedResources.map(resource => ({
          fullUrl: `${req.protocol}://${req.get('host')}/fhir/${resource.resourceType}/${resource.id}`,
          resource: resource
        }))
      ]
    };
    
    res.set('Content-Type', 'application/fhir+json');
    res.json(bundle);
  } catch (error) {
    console.error('Error in Patient $everything operation:', error);
    res.status(500).json({
      resourceType: 'OperationOutcome',
      issue: [
        {
          severity: 'error',
          code: 'exception',
          diagnostics: 'Error in Patient $everything operation'
        }
      ]
    });
  }
});

// Get all messages for a chat
app.get('/chat/:chatId/messages', async (req, res) => {
  try {
    // Verify JWT token
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided. Please log in.' });
    }
    
    let decoded;
    try {
      decoded = jwt.verify(token, SECRET_KEY);
    } catch (jwtErr) {
      return res.status(401).json({ error: 'Invalid or expired token. Please log in again.' });
    }
    
  const { chatId } = req.params;
    
    // Verify that the chatId matches the logged-in user
    // Get patient info from token to verify ownership
    let patientIdFromToken = decoded.id;
    let patientIdentifier = decoded.identifier;
    let patientPhone = decoded.phone;
    
    // If we don't have patient_id directly, look it up
    if (!patientIdFromToken && (patientIdentifier || patientPhone)) {
      const patientCheck = await pool.query(
        'SELECT patient_id, identifier, phone FROM patient WHERE identifier = $1 OR phone = $1 LIMIT 1',
        [patientIdentifier || patientPhone]
      );
      if (patientCheck.rows.length > 0) {
        patientIdFromToken = patientCheck.rows[0].patient_id;
        patientIdentifier = patientCheck.rows[0].identifier;
        patientPhone = patientCheck.rows[0].phone;
      }
    }
    
    // Verify chatId matches one of the user's identifiers
    const validIdentifiers = [
      patientIdFromToken?.toString(),
      patientIdentifier,
      patientPhone,
      decoded.national_id
    ].filter(Boolean);
    
    // First, try to find the patient for chatId
    const chatIdCheck = await pool.query(
      'SELECT patient_id, identifier, phone FROM patient WHERE identifier = $1 OR phone = $1 OR patient_id::text = $1 LIMIT 1',
      [chatId]
    );
    
    if (chatIdCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    
    const chatPatientId = chatIdCheck.rows[0].patient_id;
    const chatPatientIdentifier = chatIdCheck.rows[0].identifier;
    const chatPatientPhone = chatIdCheck.rows[0].phone;
    
    // Verify that the chatId's patient_id matches the logged-in user's patient_id
    if (chatPatientId !== patientIdFromToken) {
      // Also check if identifiers match as fallback
      const validIdentifiers = [
        patientIdFromToken?.toString(),
        patientIdentifier,
        patientPhone,
        decoded.national_id
      ].filter(Boolean);
      
      const chatIdentifiers = [
        chatPatientId?.toString(),
        chatPatientIdentifier,
        chatPatientPhone
      ].filter(Boolean);
      
      // Check if any identifier matches
      const hasMatch = validIdentifiers.some(id => chatIdentifiers.includes(id));
      
      if (!hasMatch) {
        return res.status(403).json({ error: 'You can only access your own messages.' });
      }
    }
    
    // Find patient by identifier to get patient_id
    const patientResult = await pool.query(
      'SELECT patient_id FROM patient WHERE identifier = $1 OR phone = $1 LIMIT 1',
      [chatId]
    );
    
    if (patientResult.rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    
    const patientId = patientResult.rows[0].patient_id;
    
    // Find or create thread for this patient
    let threadResult = await pool.query(
      `SELECT id FROM chat_threads 
       WHERE patient_id = $1 
       ORDER BY created_at DESC 
       LIMIT 1`,
      [patientId]
    );
    
    let threadId;
    if (threadResult.rows.length === 0) {
      // Create new thread
      const newThread = await pool.query(
        `INSERT INTO chat_threads 
         (fhir_id, user_id, health_worker_id, patient_id, last_message_time, unread_count)
         VALUES ($1, $2, $3, $4, NOW(), 0)
         RETURNING id`,
        [uuidv4(), chatId, 'health_worker', patientId]
      );
      threadId = newThread.rows[0].id;
    } else {
      threadId = threadResult.rows[0].id;
    }
    
    // Get messages for this thread
    const result = await pool.query(
      `SELECT 
        id,
        fhir_id,
        thread_id,
        sender_id,
        receiver_id,
        sender_type,
        patient_id,
        organization_id,
        message,
        is_read,
        dak_message_id,
        fhir_resource,
        version_id,
        created_at,
        updated_at,
        last_updated
       FROM chat_messages 
       WHERE thread_id = $1 
       ORDER BY created_at ASC`,
      [threadId]
    );
    
    // Format response for frontend compatibility
    const formattedMessages = result.rows.map(row => ({
      id: row.id,
      fhir_id: row.fhir_id,
      thread_id: row.thread_id,
      sender_id: row.sender_id,
      receiver_id: row.receiver_id,
      message: row.message,
      is_read: row.is_read,
      timestamp: row.created_at || row.last_updated,
      created_at: row.created_at,
      updated_at: row.updated_at,
      status: row.is_read ? 'read' : 'sent'
    }));
    
    res.json(formattedMessages);
  } catch (err) {
    console.error('Error fetching chat messages:', err);
    res.status(500).json({ error: 'Failed to fetch chat messages', message: err.message });
  }
});

// Send a new message
app.post('/chat/:chatId/messages', async (req, res) => {
  try {
    // Verify JWT token
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided. Please log in.' });
    }
    
    let decoded;
    try {
      decoded = jwt.verify(token, SECRET_KEY);
    } catch (jwtErr) {
      return res.status(401).json({ error: 'Invalid or expired token. Please log in again.' });
    }
    
  const { chatId } = req.params;
  const {
    sender_id,
    receiver_id,
    message,
    who_guideline,
    dak_guideline,
    fhir_resource
  } = req.body;
    
    // Verify that the chatId matches the logged-in user
    // Get patient info from token to verify ownership
    let patientIdFromToken = decoded.id;
    let patientIdentifier = decoded.identifier;
    let patientPhone = decoded.phone;
    
    // If we don't have patient_id directly, look it up
    if (!patientIdFromToken && (patientIdentifier || patientPhone)) {
      const patientCheck = await pool.query(
        'SELECT patient_id, identifier, phone FROM patient WHERE identifier = $1 OR phone = $1 LIMIT 1',
        [patientIdentifier || patientPhone]
      );
      if (patientCheck.rows.length > 0) {
        patientIdFromToken = patientCheck.rows[0].patient_id;
        patientIdentifier = patientCheck.rows[0].identifier;
        patientPhone = patientCheck.rows[0].phone;
      }
    }
    
    // Verify chatId matches one of the user's identifiers
    // First, try to find the patient for chatId
    const chatIdCheck = await pool.query(
      'SELECT patient_id, identifier, phone FROM patient WHERE identifier = $1 OR phone = $1 OR patient_id::text = $1 LIMIT 1',
      [chatId]
    );
    
    if (chatIdCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    
    const chatPatientId = chatIdCheck.rows[0].patient_id;
    const chatPatientIdentifier = chatIdCheck.rows[0].identifier;
    const chatPatientPhone = chatIdCheck.rows[0].phone;
    
    // Verify that the chatId's patient_id matches the logged-in user's patient_id
    if (chatPatientId !== patientIdFromToken) {
      // Also check if identifiers match as fallback
      const validIdentifiers = [
        patientIdFromToken?.toString(),
        patientIdentifier,
        patientPhone,
        decoded.national_id
      ].filter(Boolean);
      
      const chatIdentifiers = [
        chatPatientId?.toString(),
        chatPatientIdentifier,
        chatPatientPhone
      ].filter(Boolean);
      
      // Check if any identifier matches
      const hasMatch = validIdentifiers.some(id => chatIdentifiers.includes(id));
      
      if (!hasMatch) {
        return res.status(403).json({ error: 'You can only send messages from your own account.' });
      }
    }
    
    if (!message || !sender_id || !receiver_id) {
      return res.status(400).json({ error: 'Missing required fields: message, sender_id, receiver_id' });
    }
    
    // Find patient by identifier to get patient_id
    const patientResult = await pool.query(
      'SELECT patient_id FROM patient WHERE identifier = $1 OR phone = $1 LIMIT 1',
      [chatId]
    );
    
    if (patientResult.rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    
    const patientId = patientResult.rows[0].patient_id;
    
    // Find or create thread for this patient
    let threadResult = await pool.query(
      `SELECT id FROM chat_threads 
       WHERE patient_id = $1 
       ORDER BY created_at DESC 
       LIMIT 1`,
      [patientId]
    );
    
    let threadId;
    if (threadResult.rows.length === 0) {
      // Create new thread
      const newThread = await pool.query(
        `INSERT INTO chat_threads 
         (fhir_id, user_id, health_worker_id, patient_id, last_message, last_message_time, unread_count)
         VALUES ($1, $2, $3, $4, $5, NOW(), 0)
         RETURNING id`,
        [uuidv4(), chatId, receiver_id || 'health_worker', patientId, message]
      );
      threadId = newThread.rows[0].id;
    } else {
      threadId = threadResult.rows[0].id;
      // Update thread with last message
      await pool.query(
        `UPDATE chat_threads 
         SET last_message = $1, last_message_time = NOW(), unread_count = unread_count + 1
         WHERE id = $2`,
        [message, threadId]
      );
    }
    
    // Determine sender type
    const senderType = sender_id === chatId ? 'patient' : 'health_worker';
    
    // Create FHIR resource if not provided
    const fhirResourceData = fhir_resource || {
      resourceType: 'Communication',
      status: 'completed',
      category: {
        coding: [{
          system: 'http://who.int/dak/anc',
          code: 'patient-communication',
          display: 'Patient Communication'
        }]
      },
      subject: { reference: `Patient/${patientId}` },
      sent: new Date().toISOString()
    };
    
    // Insert message
  const result = await pool.query(
      `INSERT INTO chat_messages
        (fhir_id, thread_id, sender_id, receiver_id, sender_type, patient_id, message, is_read, fhir_resource)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING *`,
      [
        uuidv4(),
        threadId,
        sender_id,
        receiver_id,
        senderType,
        patientId,
        message,
        false,
        JSON.stringify(fhirResourceData)
      ]
    );
    
    // Format response for frontend compatibility
    const formattedMessage = {
      id: result.rows[0].id,
      fhir_id: result.rows[0].fhir_id,
      thread_id: result.rows[0].thread_id,
      sender_id: result.rows[0].sender_id,
      receiver_id: result.rows[0].receiver_id,
      message: result.rows[0].message,
      is_read: result.rows[0].is_read,
      timestamp: result.rows[0].created_at || result.rows[0].last_updated,
      created_at: result.rows[0].created_at,
      updated_at: result.rows[0].updated_at,
      status: 'sent',
      fhir_resource: result.rows[0].fhir_resource
    };
    
    res.status(201).json(formattedMessage);
  } catch (err) {
    console.error('Error sending chat message:', err);
    res.status(500).json({ error: 'Failed to send chat message', message: err.message });
  }
});

// Removed duplicate listen call - using the one below with PORT env var

app.get('/admin/patient/:id/full', async (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  const patientId = req.params.id;

  // Get patient info
  const patientResult = await pool.query('SELECT * FROM patient WHERE patient_id = $1', [patientId]);
  if (patientResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });
  const patient = patientResult.rows[0];

  // Get current pregnancy (latest by edd_date)
  const pregnancyResult = await pool.query(
    'SELECT * FROM pregnancy WHERE patient_id = $1 ORDER BY edd_date DESC LIMIT 1', [patientId]
  );
  const pregnancy = pregnancyResult.rows[0] || null;

  // Get all ANC visits for this patient (for the current pregnancy)
  let ancVisits = [];
  if (pregnancy) {
    const ancResult = await pool.query(
      `SELECT av.* FROM anc_visit av
       JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
       WHERE pr.patient_id = $1 AND pr.pregnancy_id = $2
       ORDER BY av.visit_number ASC`,
      [patientId, pregnancy.pregnancy_id]
    );
    ancVisits = ancResult.rows;
  }

  // Get delivery info for this pregnancy
  let delivery = null;
  if (pregnancy) {
    const deliveryResult = await pool.query(
      'SELECT * FROM delivery WHERE pregnancy_id = $1', [pregnancy.pregnancy_id]
    );
    delivery = deliveryResult.rows[0] || null;
  }

  // Get neonate info for this delivery
  let neonates = [];
  if (delivery) {
    const neonateResult = await pool.query(
      'SELECT * FROM neonate WHERE delivery_id = $1', [delivery.delivery_id]
    );
    neonates = neonateResult.rows;
  }

  // Get postnatal visits for this delivery
  let postnatalVisits = [];
  if (delivery) {
    const postnatalResult = await pool.query(
      'SELECT * FROM postnatal_care WHERE delivery_id = $1', [delivery.delivery_id]
    );
    postnatalVisits = postnatalResult.rows;
  }

  // Decision support alerts (reuse your function)
  const decisionSupportAlerts = pregnancy ? generateDecisionSupportAlerts(pregnancy, ancVisits) : [];

  res.json({
    patient,
    pregnancy,
    ancVisits,
    delivery,
    neonates,
    postnatalVisits,
    decisionSupportAlerts
  });
});
// Server startup moved to end of file after all routes are defined

app.get('/api/chat_message', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM chat_message');
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching chat_message:', err);
    res.status(500).json({ error: 'Failed to fetch chat_message data' });
  }
});

app.post('/api/chat_message/chat/:chatId', async (req, res) => {
  try {
    // Check if table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'chat_message'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      return res.status(404).json({ 
        error: 'chat_message table does not exist',
        message: 'Please run the database migration to create the chat_message table'
      });
    }
    
    const { chatId } = req.params;
    const { sender_id, receiver_id, message, who_guideline, dak_guideline, fhir_resource, reply, is_read } = req.body;
    
    // Validate required fields
    if (!message && !reply) {
      return res.status(400).json({ error: 'message or reply is required' });
    }
    if (!sender_id) {
      return res.status(400).json({ error: 'sender_id is required' });
    }
    if (!receiver_id) {
      return res.status(400).json({ error: 'receiver_id is required' });
    }
    
    const result = await pool.query(
      `INSERT INTO chat_message
        (chat_id, sender_id, receiver_id, message, who_guideline, dak_guideline, fhir_resource, reply, is_read, created_at, timestamp)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
       RETURNING *`,
      [
        chatId, 
        sender_id, 
        receiver_id, 
        message || reply || '', 
        who_guideline || null, 
        dak_guideline || null, 
        fhir_resource ? JSON.stringify(fhir_resource) : null, 
        reply || null, 
        is_read !== undefined ? is_read : false
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error posting chat message:', err);
    res.status(500).json({ 
      error: 'Failed to post chat message',
      message: err.message,
      details: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

app.get('/api/chat_message/chat/:chatId', async (req, res) => {
  try {
    const { chatId } = req.params;
    const result = await pool.query(
      'SELECT * FROM chat_message WHERE chat_id = $1 ORDER BY timestamp ASC',
      [chatId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching chat messages by chatId:', err);
    res.status(500).json({ error: 'Failed to fetch chat messages' });
  }
});

// Admin endpoint for sending messages to chat_messages table (new schema)
app.post('/api/admin/chat_messages', async (req, res) => {
  try {
    const { thread_id, sender_id, receiver_id, message, patient_id } = req.body;
    
    // Validate required fields
    if (!thread_id) {
      return res.status(400).json({ error: 'thread_id is required' });
    }
    if (!message) {
      return res.status(400).json({ error: 'message is required' });
    }
    if (!sender_id) {
      return res.status(400).json({ error: 'sender_id is required' });
    }
    if (!receiver_id) {
      return res.status(400).json({ error: 'receiver_id is required' });
    }
    
    // Check if chat_messages table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'chat_messages'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      return res.status(404).json({ 
        error: 'chat_messages table does not exist',
        message: 'Please run the database migration to create the chat_messages table'
      });
    }
    
    // Check if thread exists
    const threadCheck = await pool.query(
      'SELECT id FROM chat_threads WHERE id = $1',
      [thread_id]
    );
    
    if (threadCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Chat thread not found' });
    }
    
    // Determine sender type
    const senderType = sender_id === 'health_worker' || sender_id.includes('health_worker') ? 'health_worker' : 'patient';
    
    // Insert message
    const result = await pool.query(
      `INSERT INTO chat_messages
        (fhir_id, thread_id, sender_id, receiver_id, sender_type, patient_id, message, is_read)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        uuidv4(),
        thread_id,
        sender_id,
        receiver_id,
        senderType,
        patient_id || null,
        message,
        false
      ]
    );
    
    // Update thread with last message
    await pool.query(
      `UPDATE chat_threads 
       SET last_message = $1, last_message_time = NOW(), unread_count = unread_count + 1
       WHERE id = $2`,
      [message, thread_id]
    );
    
    res.status(201).json({
      id: result.rows[0].id,
      thread_id: result.rows[0].thread_id,
      sender_id: result.rows[0].sender_id,
      receiver_id: result.rows[0].receiver_id,
      message: result.rows[0].message,
      is_read: result.rows[0].is_read,
      timestamp: result.rows[0].created_at,
      created_at: result.rows[0].created_at,
    });
  } catch (err) {
    console.error('Error posting admin chat message:', err);
    res.status(500).json({ 
      error: 'Failed to post chat message',
      message: err.message,
      details: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
  }
});

app.patch('/api/chat_message/:id/read', async (req, res) => {
  try {
    const { id } = req.params;
    const { is_read } = req.body;
    const result = await pool.query(
      'UPDATE chat_message SET is_read = $1 WHERE id = $2 RETURNING *',
      [is_read, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Chat message not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating is_read:', err);
    res.status(500).json({ error: 'Failed to update is_read' });
  }
});

app.post('/api/chat_message/reply/:originalMessageId', async (req, res) => {
  try {
    const { originalMessageId } = req.params;
    const { reply, health_worker_id } = req.body; // health_worker_id is the sender of the reply

    // Fetch the original message to get chat_id and sender_id
    const originalResult = await pool.query(
      'SELECT * FROM chat_message WHERE id = $1',
      [originalMessageId]
    );
    if (originalResult.rows.length === 0) {
      return res.status(404).json({ error: 'Original message not found' });
    }
    const original = originalResult.rows[0];

    // Insert the reply message
    const result = await pool.query(
      `INSERT INTO chat_message
        (chat_id, sender_id, receiver_id, message, reply, is_read)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        original.chat_id,
        health_worker_id,         // sender is the health worker
        original.sender_id,       // receiver is the original sender (from the app)
        reply,                    // the reply message
        originalMessageId,        // reference to the original message
        false                     // is_read
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error posting reply:', err);
    res.status(500).json({ error: 'Failed to post reply' });
  }
});

// Tips Endpoints - Updated to match new merged schema (nutrition_tips + health_tips -> tips)
app.post('/api/tips', async (req, res) => {
  try {
    const { title, content, category, trimester, visit, schedule, weeks, is_active, fhir_resource } = req.body;
    const fhirId = uuidv4();
    const dakTipId = `dak-tip-${Date.now()}`;
    
    const result = await pool.query(
      `INSERT INTO tips
        (fhir_id, dak_tip_id, title, category, content, trimester, visit, schedule, weeks, is_active, fhir_resource)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, TRUE), $11)
       RETURNING *`,
      [
        fhirId,
        dakTipId,
        title,
        category, // 'nutrition' or 'health'
        content,
        trimester || null,
        visit || null,
        schedule || null,
        weeks || null,
        is_active,
        fhir_resource ? JSON.stringify(fhir_resource) : null
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error saving tip:', err);
    res.status(500).json({ error: 'Failed to save tip', details: err.message });
  }
});

app.get('/api/tips', async (req, res) => {
  try {
    const { category, is_active, trimester } = req.query;
    let query = 'SELECT * FROM tips WHERE 1=1';
    const params = [];
    let paramCount = 0;
    
    if (category) {
      paramCount++;
      query += ` AND category = $${paramCount}`;
      params.push(category);
    }
    
    if (is_active !== undefined) {
      paramCount++;
      query += ` AND is_active = $${paramCount}`;
      params.push(is_active === 'true');
    }
    
    if (trimester) {
      paramCount++;
      query += ` AND (trimester = $${paramCount} OR trimester IS NULL)`;
      params.push(trimester);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching tips:', err);
    res.status(500).json({ error: 'Failed to fetch tips', details: err.message });
  }
});

// Tips by ID
app.get('/api/tips/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM tips WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tip not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching tip:', err);
    res.status(500).json({ error: 'Failed to fetch tip', details: err.message });
  }
});

app.put('/api/tips/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, category, trimester, visit, schedule, weeks, is_active, fhir_resource } = req.body;
    const result = await pool.query(
      `UPDATE tips SET
        title = COALESCE($1, title),
        content = COALESCE($2, content),
        category = COALESCE($3, category),
        trimester = COALESCE($4, trimester),
        visit = COALESCE($5, visit),
        schedule = COALESCE($6, schedule),
        weeks = COALESCE($7, weeks),
        is_active = COALESCE($8, is_active),
        fhir_resource = COALESCE($9, fhir_resource)
       WHERE id = $10 RETURNING *`,
      [title, content, category, trimester, visit, schedule, weeks, is_active, fhir_resource ? JSON.stringify(fhir_resource) : null, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tip not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating tip:', err);
    res.status(500).json({ error: 'Failed to update tip', details: err.message });
  }
});

app.delete('/api/tips/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM tips WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tip not found' });
    }
    res.json({ message: 'Tip deleted', tip: result.rows[0] });
  } catch (err) {
    console.error('Error deleting tip:', err);
    res.status(500).json({ error: 'Failed to delete tip', details: err.message });
  }
});

// Legacy endpoints for backward compatibility - redirect to tips
app.post('/api/nutrition_tips', async (req, res) => {
  req.body.category = 'nutrition';
  // Create a new request object with category set
  const newReq = { ...req, body: { ...req.body, category: 'nutrition' } };
  // Call the tips endpoint handler directly
  const { title, content, trimester, visit, schedule, weeks, is_active, fhir_resource } = req.body;
  const fhirId = uuidv4();
  const dakTipId = `dak-tip-${Date.now()}`;
  
  try {
    const result = await pool.query(
      `INSERT INTO tips
        (fhir_id, dak_tip_id, title, category, content, trimester, visit, schedule, weeks, is_active, fhir_resource)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, TRUE), $11)
       RETURNING *`,
      [
        fhirId,
        dakTipId,
        title,
        'nutrition',
        content,
        trimester || null,
        visit || null,
        schedule || null,
        weeks || null,
        is_active,
        fhir_resource ? JSON.stringify(fhir_resource) : null
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error saving nutrition tip:', err);
    res.status(500).json({ error: 'Failed to save nutrition tip', details: err.message });
  }
});

app.get('/api/nutrition_tips', async (req, res) => {
  try {
    const { is_active, trimester } = req.query;
    let query = "SELECT * FROM tips WHERE category = 'nutrition'";
    const params = [];
    let paramCount = 0;
    
    if (is_active !== undefined) {
      paramCount++;
      query += ` AND is_active = $${paramCount}`;
      params.push(is_active === 'true');
    }
    
    if (trimester) {
      paramCount++;
      query += ` AND (trimester = $${paramCount} OR trimester IS NULL)`;
      params.push(trimester);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching nutrition tips:', err);
    res.status(500).json({ error: 'Failed to fetch nutrition tips', details: err.message });
  }
});

app.post('/api/health_tips', async (req, res) => {
  const { title, content, trimester, visit, schedule, weeks, is_active, fhir_resource } = req.body;
  const fhirId = uuidv4();
  const dakTipId = `dak-tip-${Date.now()}`;
  
  try {
    const result = await pool.query(
      `INSERT INTO tips
        (fhir_id, dak_tip_id, title, category, content, trimester, visit, schedule, weeks, is_active, fhir_resource)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, TRUE), $11)
       RETURNING *`,
      [
        fhirId,
        dakTipId,
        title,
        'health',
        content,
        trimester || null,
        visit || null,
        schedule || null,
        weeks || null,
        is_active,
        fhir_resource ? JSON.stringify(fhir_resource) : null
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error saving health tip:', err);
    res.status(500).json({ error: 'Failed to save health tip', details: err.message });
  }
});

app.get('/api/health_tips', async (req, res) => {
  try {
    const { is_active, trimester } = req.query;
    let query = "SELECT * FROM tips WHERE category = 'health'";
    const params = [];
    let paramCount = 0;
    
    if (is_active !== undefined) {
      paramCount++;
      query += ` AND is_active = $${paramCount}`;
      params.push(is_active === 'true');
    }
    
    if (trimester) {
      paramCount++;
      query += ` AND (trimester = $${paramCount} OR trimester IS NULL)`;
      params.push(trimester);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching health tips:', err);
    res.status(500).json({ error: 'Failed to fetch health tips', details: err.message });
  }
});

// Notifications Endpoints - Updated to match new schema
app.post('/api/notifications', async (req, res) => {
  try {
    const { title, message, target_categories, type, status, scheduled_at, trimester, visit, weeks, is_read, patient_id, organization_id, recipient_id, fhir_resource } = req.body;
    const fhirId = uuidv4();
    const dakNotificationId = `dak-notification-${Date.now()}`;
    
    const result = await pool.query(
      `INSERT INTO notifications
        (fhir_id, dak_notification_id, patient_id, organization_id, title, message, target_categories, type, status, scheduled_at, trimester, visit, weeks, is_read, recipient_id, fhir_resource)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, COALESCE($14, FALSE), $15, $16)
       RETURNING *`,
      [
        fhirId,
        dakNotificationId,
        patient_id || null,
        organization_id || null,
        title,
        message,
        target_categories || null,
        type || 'general',
        status || 'sent',
        scheduled_at || null,
        trimester || null,
        visit || null,
        weeks || null,
        is_read,
        recipient_id || null,
        fhir_resource ? JSON.stringify(fhir_resource) : null
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating notification:', err);
    res.status(500).json({ error: 'Failed to create notification', details: err.message });
  }
});

app.get('/api/notifications', async (req, res) => {
  try {
    // Extract patient_id from JWT token
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    let patientId = null;
    let patientIdentifier = null;
    let patientPhone = null;
    
    try {
      const decoded = jwt.verify(token, SECRET_KEY);
      patientId = decoded.id;
      patientIdentifier = decoded.identifier;
      patientPhone = decoded.phone;
      
      // Fallback: if token doesn't have id, try to resolve from identifier or phone
      if (!patientId) {
        if (patientIdentifier) {
          const r = await pool.query('SELECT patient_id FROM patient WHERE identifier = $1', [patientIdentifier]);
          if (r.rows.length > 0) patientId = r.rows[0].patient_id;
        }
        if (!patientId && patientPhone) {
          const r = await pool.query('SELECT patient_id FROM patient WHERE phone = $1', [patientPhone]);
          if (r.rows.length > 0) patientId = r.rows[0].patient_id;
        }
      }
    } catch (jwtErr) {
      console.error('JWT verification error:', jwtErr);
      return res.status(401).json({ error: 'Invalid token' });
    }

    if (!patientId) {
      return res.status(401).json({ error: 'Could not identify patient from token' });
    }

    // Get patient's current pregnancy data for filtering
    const patientResult = await pool.query(
      'SELECT patient_id, identifier FROM patient WHERE patient_id = $1',
      [patientId]
    );
    
    if (patientResult.rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    const patient = patientResult.rows[0];
    
    // Get patient's current pregnancy info for filtering
    const pregnancyResult = await pool.query(
      'SELECT * FROM pregnancy WHERE patient_id = $1 ORDER BY created_at DESC LIMIT 1',
      [patientId]
    );
    
    const pregnancy = pregnancyResult.rows.length > 0 ? pregnancyResult.rows[0] : null;
    
    // Calculate trimester from gestational weeks (1-12 = first, 13-27 = second, 28+ = third)
    let currentTrimester = null;
    let currentWeeks = null;
    if (pregnancy) {
      // Use current_gestation_weeks if available, otherwise calculate from lmp_date
      if (pregnancy.current_gestation_weeks) {
        currentWeeks = pregnancy.current_gestation_weeks;
      } else if (pregnancy.lmp_date) {
        const lmpDate = new Date(pregnancy.lmp_date);
        const now = new Date();
        const diffTime = Math.abs(now - lmpDate);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        currentWeeks = Math.floor(diffDays / 7);
      }
      
      // Calculate trimester from weeks
      if (currentWeeks !== null) {
        if (currentWeeks <= 12) {
          currentTrimester = 'first';
        } else if (currentWeeks <= 27) {
          currentTrimester = 'second';
        } else {
          currentTrimester = 'third';
        }
      }
    }
    
    // Get latest ANC visit number (join through pregnancy)
    const ancVisitResult = await pool.query(
      `SELECT av.visit_number 
       FROM anc_visit av
       JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
       WHERE pr.patient_id = $1 
       ORDER BY av.visit_number DESC LIMIT 1`,
      [patientId]
    );
    const latestVisitNumber = ancVisitResult.rows.length > 0 ? ancVisitResult.rows[0].visit_number : null;

    // Query notifications - filter by patient-specific criteria
    // Get notifications that match the patient's current state or are general notifications
    const conditions = [
      // Notifications for all patients (no specific targeting)
      // Check if array is NULL or empty using PostgreSQL array functions
      "(target_categories IS NULL OR array_length(target_categories, 1) IS NULL OR cardinality(target_categories) = 0)"
    ];
    const queryParams = [];
    let paramIndex = 1;
    
    // Add trimester condition if available
    if (currentTrimester) {
      conditions.push(`(trimester IS NOT NULL AND trimester::text = $${paramIndex})`);
      queryParams.push(currentTrimester);
      paramIndex++;
    }
    
    // Add visit condition if available
    if (latestVisitNumber !== null) {
      conditions.push(`(visit IS NOT NULL AND visit = $${paramIndex})`);
      queryParams.push(latestVisitNumber);
      paramIndex++;
    }
    
    // Add weeks condition if available
    if (currentWeeks !== null) {
      conditions.push(`(weeks IS NOT NULL AND weeks = $${paramIndex})`);
      queryParams.push(currentWeeks);
      paramIndex++;
    }
    
    const query = `
      SELECT * FROM notifications 
      WHERE (${conditions.join(' OR ')})
      ORDER BY created_at DESC
    `;
    
    // If notifications table has patient_id column, also filter by that
    try {
      const result = await pool.query(query, queryParams);
    res.json(result.rows);
    } catch (queryErr) {
      // If the query fails (e.g., table doesn't exist or column doesn't exist),
      // try a simpler query
      console.warn('Complex notification query failed, trying simple query:', queryErr.message);
      try {
        const simpleResult = await pool.query('SELECT * FROM notifications ORDER BY created_at DESC LIMIT 100');
        res.json(simpleResult.rows);
      } catch (simpleErr) {
        // If table doesn't exist, return empty array
        if (simpleErr.message.includes('does not exist') || simpleErr.message.includes('relation')) {
          console.warn('Notifications table does not exist, returning empty array');
          res.json([]);
        } else {
          throw simpleErr;
        }
      }
    }
  } catch (err) {
    console.error('Error fetching notifications:', err);
    res.status(500).json({ error: 'Failed to fetch notifications', details: err.message });
  }
});

app.get('/api/notifications/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM notifications WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching notification:', err);
    res.status(500).json({ error: 'Failed to fetch notification' });
  }
});

app.put('/api/notifications/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, message, target_categories, type, status, scheduled_at, trimester, visit, weeks, is_read, read_at } = req.body;
    const result = await pool.query(
      `UPDATE notifications SET
        title = COALESCE($1, title),
        message = COALESCE($2, message),
        target_categories = COALESCE($3, target_categories),
        type = COALESCE($4, type),
        status = COALESCE($5, status),
        scheduled_at = COALESCE($6, scheduled_at),
        trimester = COALESCE($7, trimester),
        visit = COALESCE($8, visit),
        weeks = COALESCE($9, weeks),
        is_read = COALESCE($10, is_read),
        read_at = CASE WHEN $10 = TRUE AND read_at IS NULL THEN NOW() ELSE read_at END
       WHERE id = $11 RETURNING *`,
      [title, message, target_categories, type, status, scheduled_at, trimester, visit, weeks, is_read, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating notification:', err);
    res.status(500).json({ error: 'Failed to update notification', details: err.message });
  }
});

app.delete('/api/notifications/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM notifications WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    res.json({ message: 'Notification deleted', notification: result.rows[0] });
  } catch (err) {
    console.error('Error deleting notification:', err);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
});

// =====================================================
// MOBILE APP ENDPOINTS
// =====================================================

// Mobile Patients List
app.get('/patients', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        patient_id,
        fhir_id,
        identifier,
        name,
        first_name,
        last_name,
        gender,
        birth_date,
        age,
        phone,
        village,
        chiefdom,
        district,
        registration_date,
        created_at
      FROM patient 
      ORDER BY created_at DESC
    `);
    
    res.json({
      success: true,
      patients: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching patients:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch patients',
      message: error.message 
    });
  }
});

// Mobile Appointments List
app.get('/appointments', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        av.anc_visit_id,
        av.visit_number,
        av.visit_date,
        av.gestation_weeks,
        av.weight_kg,
        av.blood_pressure_systolic,
        av.blood_pressure_diastolic,
        av.fundal_height_cm,
        av.fetal_heart_rate,
        av.risk_level,
        av.next_visit_date,
        av.provider_name,
        av.created_at,
        p.name as patient_name,
        p.identifier,
        p.phone,
        p.village,
        p.district
      FROM anc_visit av
      LEFT JOIN pregnancy pr ON av.pregnancy_id = pr.pregnancy_id
      LEFT JOIN patient p ON pr.patient_id = p.patient_id
      ORDER BY av.visit_date DESC
    `);
    
    res.json({
      success: true,
      appointments: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching appointments:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch appointments',
      message: error.message 
    });
  }
});

// Mobile Messages List
app.get('/messages', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        cm.id,
        cm.chat_id,
        cm.sender_id,
        cm.receiver_id,
        cm.message,
        cm.reply,
        cm.is_read,
        cm.who_guideline,
        cm.dak_guideline,
        cm.fhir_resource,
        cm.created_at,
        p.name as patient_name,
        p.identifier as patient_identifier
      FROM chat_message cm
      LEFT JOIN patient p ON cm.sender_id = p.patient_id
      ORDER BY cm.created_at DESC
    `);
    
    res.json({
      success: true,
      messages: result.rows,
      total: result.rows.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch messages',
      message: error.message 
    });
  }
});

// =====================================================
// ADMIN DASHBOARD ENDPOINTS
// =====================================================

// Admin Dashboard
app.get('/admin/dashboard', async (req, res) => {
  try {
    const [
      patientCount,
      visitCount,
      fhirResourceCount,
      dakCompliance
    ] = await Promise.all([
      pool.query('SELECT COUNT(*) as count FROM patient'),
      pool.query('SELECT COUNT(*) as count FROM anc_visit'),
      pool.query('SELECT 0 as count'), // fhir_resources table doesn't exist yet
      pool.query('SELECT COUNT(*) as count FROM dak_quality_indicators')
    ]);

    res.json({
      success: true,
      dashboard: {
        totalPatients: parseInt(patientCount.rows[0].count),
        totalVisits: parseInt(visitCount.rows[0].count),
        totalFhirResources: parseInt(fhirResourceCount.rows[0].count),
        dakIndicators: parseInt(dakCompliance.rows[0].count),
        lastUpdated: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

// Admin Analytics
app.get('/admin/analytics', async (req, res) => {
  try {
    const [
      monthlyVisits,
      riskDistribution,
      fhirResourceTypes
    ] = await Promise.all([
      pool.query(`
        SELECT 
          DATE_TRUNC('month', visit_date) as month,
          COUNT(*) as visits
        FROM anc_visit 
        GROUP BY DATE_TRUNC('month', visit_date)
        ORDER BY month DESC
        LIMIT 12
      `),
      pool.query(`
        SELECT 
          risk_level,
          COUNT(*) as count
        FROM patient 
        GROUP BY risk_level
      `),
      pool.query('SELECT \'not_implemented\' as resource_type, 0 as count') // fhir_resources table doesn't exist yet
    ]);

    res.json({
      success: true,
      analytics: {
        monthlyVisits: monthlyVisits.rows,
        riskDistribution: riskDistribution.rows,
        fhirResourceTypes: fhirResourceTypes.rows,
        generatedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Error fetching analytics data:', error);
    res.status(500).json({ error: 'Failed to fetch analytics data' });
  }
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start Server - MUST be at the end after all routes are defined
const PORT = process.env.PORT || 3000;

// Debug port configuration
if (process.env.NODE_ENV !== 'production') {
  console.log('Port Configuration:', {
    envPort: process.env.PORT,
    finalPort: PORT,
    nodeEnv: process.env.NODE_ENV
  });
}

// Add error handling for server startup
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  // Don't exit in production to keep the container running
  if (process.env.NODE_ENV !== 'production') {
    process.exit(1);
  }
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  // Don't exit in production to keep the container running
  if (process.env.NODE_ENV !== 'production') {
    process.exit(1);
  }
});

try {
  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`FHIR server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Database URL: ${process.env.DATABASE_URL ? 'Set' : 'Not set'}`);
    console.log(`Server ready at http://0.0.0.0:${PORT}`);
  });

  // Handle server errors
  server.on('error', (error) => {
    console.error('Server error:', error);
    if (error.code === 'EADDRINUSE') {
      console.error(`Port ${PORT} is already in use`);
    }
    process.exit(1);
  });

} catch (error) {
  console.error('Failed to start server:', error);
  process.exit(1);
}
