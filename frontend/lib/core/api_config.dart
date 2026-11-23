import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConfig {
  ApiConfig._();

  static const String _productionUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_productionUrl.isNotEmpty) {
      return _productionUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }

    return 'http://localhost:8080/api/v1';
  }
}