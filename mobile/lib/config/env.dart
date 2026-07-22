class Env {
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  
  static const String appName = 'AfriRange AI';
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}

class EnvConfig {
  static const String baseUrl = Env.apiUrl;
  static const String appName = Env.appName;
  static const bool isProduction = Env.isProduction;
}
