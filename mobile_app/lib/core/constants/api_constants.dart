class ApiConstants {
  static const String nodeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //   defaultValue: 'https://sentinel-backend-s3yl.onrender.com',
    defaultValue: 'http://localhost:3000',
  );
}
