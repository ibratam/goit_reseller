import 'env_config.dart';

class ApiConfig {
  static const String _baseUrlFromDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _deviceNameFromDefine = String.fromEnvironment(
    'API_DEVICE_NAME',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_baseUrlFromDefine.trim().isNotEmpty) {
      return _baseUrlFromDefine;
    }

    return EnvConfig.get('API_BASE_URL') ?? 'http://con.goit.ps:8090';
  }

  static String get deviceName {
    if (_deviceNameFromDefine.trim().isNotEmpty) {
      return _deviceNameFromDefine;
    }

    return EnvConfig.get('API_DEVICE_NAME') ?? 'mobile-app';
  }

  static bool get hasBaseUrl => baseUrl.trim().isNotEmpty;
}
