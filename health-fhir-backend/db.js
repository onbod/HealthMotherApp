require('dotenv').config();
const { Pool } = require('pg');

// Database configuration for both local and Railway
let dbConfig;

if (process.env.DATABASE_URL) {
  // Use connection string for Railway (more reliable)
  dbConfig = {
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false } // Railway requires SSL but with self-signed certs
  };
} else {
  // Fallback for local development
  dbConfig = {
    host: 'localhost',
    port: 5432,
    database: 'health_fhir',
    user: 'postgres',
    password: 'password',
    ssl: false
  };
}

// Create connection pool with error handling
let pool;

try {
  pool = new Pool(dbConfig);
  
  // Log configuration for debugging
  console.log('Database configuration:', {
    hasConnectionString: !!dbConfig.connectionString,
    host: dbConfig.host,
    port: dbConfig.port,
    database: dbConfig.database,
    user: dbConfig.user,
    ssl: dbConfig.ssl,
    nodeEnv: process.env.NODE_ENV
  });
} catch (error) {
  console.error('Failed to create database pool:', error);
  // Create a mock pool for graceful degradation
  pool = {
    query: () => Promise.reject(new Error('Database not available'))
  };
}

// Handle pool errors
pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  if (process.env.NODE_ENV !== 'production') {
    process.exit(-1);
  }
});

module.exports = pool;
