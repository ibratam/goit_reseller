import 'package:flutter/services.dart';

class EnvConfig {
  EnvConfig._();

  static final Map<String, String> _values = <String, String>{};
  static bool _isLoaded = false;

  static Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    try {
      final source = await rootBundle.loadString('.env');
      _values
        ..clear()
        ..addAll(_parse(source));
    } catch (_) {
      // Falling back to compile-time defines and hardcoded defaults is fine.
    } finally {
      _isLoaded = true;
    }
  }

  static String? get(String key) {
    final value = _values[key]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static Map<String, String> _parse(String source) {
    final values = <String, String>{};

    for (final rawLine in source.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      if (key.isEmpty) {
        continue;
      }

      var value = line.substring(separatorIndex + 1).trim();
      if (value.length >= 2) {
        final startsWithDouble = value.startsWith('"') && value.endsWith('"');
        final startsWithSingle = value.startsWith("'") && value.endsWith("'");
        if (startsWithDouble || startsWithSingle) {
          value = value.substring(1, value.length - 1);
        }
      }

      values[key] = value;
    }

    return values;
  }
}
