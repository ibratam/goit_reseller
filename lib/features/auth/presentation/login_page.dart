import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/brand_background.dart';
import '../data/biometric_login_service.dart';
import '../../../core/widgets/language_menu_button.dart';
import '../data/auth_service.dart';
import '../domain/auth_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.authService,
    required this.biometricLoginService,
    required this.currentLocale,
    required this.onLoggedIn,
    required this.onLocaleChanged,
    super.key,
  });

  final AuthService authService;
  final BiometricLoginService biometricLoginService;
  final Locale currentLocale;
  final ValueChanged<AuthSession> onLoggedIn;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isBiometricSubmitting = false;
  bool _isLoadingBiometrics = true;
  bool _obscurePassword = true;
  BiometricLoginAvailability _biometricAvailability =
      const BiometricLoginAvailability.unavailable();

  @override
  void initState() {
    super.initState();
    unawaited(_loadBiometricAvailability());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;

    if (!_formKey.currentState!.validate() ||
        _isSubmitting ||
        _isBiometricSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final session = await widget.authService.login(
        username: username,
        password: password,
      );

      await widget.biometricLoginService.saveCredentials(
        username: username,
        password: password,
      );

      if (!mounted) {
        return;
      }

      widget.onLoggedIn(session);
    } on AuthException catch (error) {
      _showMessage(l10n.localizeDynamicMessage(error.message));
    } catch (_) {
      _showMessage(l10n.loginFailedTryAgain);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _loadBiometricAvailability({
    bool showLoadingIndicator = true,
  }) async {
    if (showLoadingIndicator && mounted) {
      setState(() => _isLoadingBiometrics = true);
    }

    final availability = await widget.biometricLoginService.getAvailability();
    if (!mounted) {
      return;
    }

    final savedUsername = availability.savedUsername?.trim();
    if ((savedUsername?.isNotEmpty ?? false) &&
        _usernameController.text.trim().isEmpty) {
      _usernameController.text = savedUsername!;
    }

    setState(() {
      _biometricAvailability = availability;
      _isLoadingBiometrics = false;
    });
  }

  Future<void> _submitWithBiometrics() async {
    final l10n = context.l10n;

    if (_isSubmitting ||
        _isBiometricSubmitting ||
        !_biometricAvailability.canSignIn) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isBiometricSubmitting = true);

    try {
      final authResult = await widget.biometricLoginService.authenticate(
        localizedReason: l10n.biometricSignInReason,
      );

      if (authResult != BiometricAuthenticationResult.success) {
        if (mounted) {
          _showMessage(_messageForBiometricResult(l10n, authResult));
        }
        return;
      }

      final savedCredentials =
          await widget.biometricLoginService.loadSavedCredentials();
      if (savedCredentials == null) {
        if (mounted) {
          _showMessage(l10n.biometricLoginNeedsPassword);
        }
        return;
      }

      if (_usernameController.text.trim().isEmpty) {
        _usernameController.text = savedCredentials.username;
      }

      final session = await widget.authService.login(
        username: savedCredentials.username,
        password: savedCredentials.password,
      );

      if (!mounted) {
        return;
      }

      widget.onLoggedIn(session);
    } on AuthException {
      await widget.biometricLoginService.clearCredentials();
      if (mounted) {
        _showMessage(l10n.biometricLoginCredentialsExpired);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.biometricLoginFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isBiometricSubmitting = false);
      }
      unawaited(_loadBiometricAvailability(showLoadingIndicator: false));
    }
  }

  String _messageForBiometricResult(
    AppLocalizations l10n,
    BiometricAuthenticationResult result,
  ) {
    switch (result) {
      case BiometricAuthenticationResult.cancelled:
        return l10n.biometricLoginCancelled;
      case BiometricAuthenticationResult.unavailable:
        return l10n.biometricLoginUnavailable;
      case BiometricAuthenticationResult.failed:
        return l10n.biometricLoginFailed;
      case BiometricAuthenticationResult.success:
        return l10n.biometricLoginFailed;
    }
  }

  String _biometricButtonLabel(AppLocalizations l10n, TargetPlatform platform) {
    switch (_biometricAvailability.type) {
      case BiometricSignInType.face:
        return l10n.signInWithFaceId;
      case BiometricSignInType.fingerprint:
        return platform == TargetPlatform.iOS
            ? l10n.signInWithTouchId
            : l10n.signInWithFingerprint;
      case BiometricSignInType.generic:
        return l10n.signInWithBiometrics;
    }
  }

  IconData _biometricButtonIcon() {
    switch (_biometricAvailability.type) {
      case BiometricSignInType.face:
        return Icons.face_outlined;
      case BiometricSignInType.fingerprint:
        return Icons.fingerprint;
      case BiometricSignInType.generic:
        return Icons.verified_user_outlined;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final platform = theme.platform;

    return Scaffold(
      body: BrandedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    LanguageMenuButton(
                      currentLocale: widget.currentLocale,
                      onLocaleChanged: widget.onLocaleChanged,
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: BrandLogo(width: 240),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.loginTitle,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.loginSubtitle,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: l10n.usernameLabel,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.enterUsername;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: l10n.passwordLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.enterPassword;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isSubmitting || _isBiometricSubmitting
                                    ? null
                                    : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(l10n.signIn),
                              ),
                              if (!_isLoadingBiometrics &&
                                  _biometricAvailability.canSignIn) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed:
                                      _isSubmitting || _isBiometricSubmitting
                                          ? null
                                          : _submitWithBiometrics,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: _isBiometricSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(_biometricButtonIcon()),
                                  label: Text(
                                    _biometricButtonLabel(l10n, platform),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
