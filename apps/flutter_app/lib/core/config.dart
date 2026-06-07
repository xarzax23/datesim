const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);

const bool localAuthEnabled = bool.fromEnvironment(
  'LOCAL_AUTH_ENABLED',
  defaultValue: false,
);

const String localAuthToken = String.fromEnvironment(
  'LOCAL_AUTH_TOKEN',
  defaultValue: 'datesim-local-dev-token',
);
