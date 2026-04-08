import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricSignInType {
  generic,
  face,
  fingerprint,
}

enum BiometricAuthenticationResult {
  success,
  cancelled,
  unavailable,
  failed,
}

class SavedBiometricCredentials {
  const SavedBiometricCredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

class BiometricLoginAvailability {
  const BiometricLoginAvailability({
    required this.isSupported,
    required this.hasSavedCredentials,
    required this.type,
    this.savedUsername,
  });

  const BiometricLoginAvailability.unavailable()
      : isSupported = false,
        hasSavedCredentials = false,
        type = BiometricSignInType.generic,
        savedUsername = null;

  final bool isSupported;
  final bool hasSavedCredentials;
  final BiometricSignInType type;
  final String? savedUsername;

  bool get canSignIn => isSupported && hasSavedCredentials;
}

abstract class BiometricLoginService {
  Future<BiometricLoginAvailability> getAvailability();

  Future<SavedBiometricCredentials?> loadSavedCredentials();

  Future<void> saveCredentials({
    required String username,
    required String password,
  });

  Future<void> clearCredentials();

  Future<BiometricAuthenticationResult> authenticate({
    required String localizedReason,
  });
}

class DeviceBiometricLoginService implements BiometricLoginService {
  DeviceBiometricLoginService({
    LocalAuthentication? localAuthentication,
    FlutterSecureStorage? secureStorage,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _usernameKey = 'auth.biometric.username';
  static const String _passwordKey = 'auth.biometric.password';

  final LocalAuthentication _localAuthentication;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<BiometricLoginAvailability> getAvailability() async {
    final credentials = await loadSavedCredentials();
    final biometricState = await _readBiometricState();

    return BiometricLoginAvailability(
      isSupported: biometricState.isSupported,
      hasSavedCredentials: credentials != null,
      type: biometricState.type,
      savedUsername: credentials?.username,
    );
  }

  @override
  Future<SavedBiometricCredentials?> loadSavedCredentials() async {
    try {
      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (username == null ||
          username.trim().isEmpty ||
          password == null ||
          password.isEmpty) {
        return null;
      }

      return SavedBiometricCredentials(
        username: username.trim(),
        password: password,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      return;
    }

    try {
      await _secureStorage.write(key: _usernameKey, value: trimmedUsername);
      await _secureStorage.write(key: _passwordKey, value: password);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _usernameKey);
      await _secureStorage.delete(key: _passwordKey);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  Future<BiometricAuthenticationResult> authenticate({
    required String localizedReason,
  }) async {
    if (kIsWeb) {
      return BiometricAuthenticationResult.unavailable;
    }

    try {
      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      return didAuthenticate
          ? BiometricAuthenticationResult.success
          : BiometricAuthenticationResult.cancelled;
    } on LocalAuthException catch (error) {
      if (_isUnavailableError(error.code)) {
        return BiometricAuthenticationResult.unavailable;
      }
      if (_isCancelledError(error.code)) {
        return BiometricAuthenticationResult.cancelled;
      }
      return BiometricAuthenticationResult.failed;
    } on MissingPluginException {
      return BiometricAuthenticationResult.unavailable;
    } on PlatformException {
      return BiometricAuthenticationResult.failed;
    }
  }

  Future<_BiometricState> _readBiometricState() async {
    if (kIsWeb) {
      return const _BiometricState.unsupported();
    }

    try {
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      final isSupported = canCheckBiometrics || isDeviceSupported;
      if (!isSupported) {
        return const _BiometricState.unsupported();
      }

      final enrolledBiometrics = await _safeGetAvailableBiometrics();
      return _BiometricState(
        isSupported: canCheckBiometrics || enrolledBiometrics.isNotEmpty,
        type: _resolveType(enrolledBiometrics),
      );
    } on LocalAuthException {
      return const _BiometricState.unsupported();
    } on MissingPluginException {
      return const _BiometricState.unsupported();
    } on PlatformException {
      return const _BiometricState.unsupported();
    }
  }

  Future<List<BiometricType>> _safeGetAvailableBiometrics() async {
    try {
      return await _localAuthentication.getAvailableBiometrics();
    } on LocalAuthException {
      return const [];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  BiometricSignInType _resolveType(List<BiometricType> biometrics) {
    if (biometrics.contains(BiometricType.face)) {
      return BiometricSignInType.face;
    }
    if (biometrics.contains(BiometricType.fingerprint)) {
      return BiometricSignInType.fingerprint;
    }
    return BiometricSignInType.generic;
  }

  bool _isUnavailableError(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.uiUnavailable:
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return true;
      default:
        return false;
    }
  }

  bool _isCancelledError(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.userRequestedFallback:
        return true;
      default:
        return false;
    }
  }
}

class _BiometricState {
  const _BiometricState({
    required this.isSupported,
    required this.type,
  });

  const _BiometricState.unsupported()
      : isSupported = false,
        type = BiometricSignInType.generic;

  final bool isSupported;
  final BiometricSignInType type;
}
