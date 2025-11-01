class AppConfig {
  // Backend URL configuration
  static const String backendUrl = 'http://localhost:3000';

  // Alternative URLs for different environments
  static const String localNetworkUrl = 'http://192.168.1.145:3000';
  static const String productionUrl =
      'https://health-fhir-backend-production-6ae1.up.railway.app';

  // Get the appropriate backend URL based on environment
  static String getBackendUrl() {
    // For production, use Railway server
    return productionUrl;

    // For development, use localhost
    // return backendUrl;

    // For local network testing, use your IP
    // return localNetworkUrl;
  }

  // API endpoints
  static String getApiUrl(String endpoint) {
    return '${getBackendUrl()}$endpoint';
  }
}
