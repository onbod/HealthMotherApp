// Admin Dashboard Configuration
export const config = {
  // API Configuration
  api: {
    baseUrl: process.env.NEXT_PUBLIC_API_URL || 'https://health-fhir-backend-production.up.railway.app',
    endpoints: {
      login: '/admin/login',
      patients: '/fhir/Patient',
      fhir: '/fhir',
      metadata: '/metadata',
    }
  },
  
  // App Configuration
  app: {
    name: 'HealthyMother Admin Dashboard',
    version: '1.0.0',
    description: 'Maternal Health Management System'
  }
};

// Helper function to get full API URL
export const getApiUrl = (endpoint: string): string => {
  return `${config.api.baseUrl}${endpoint}`;
}; 