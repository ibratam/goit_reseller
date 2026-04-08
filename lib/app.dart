import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/config/api_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/brand_background.dart';
import 'features/auth/data/api_auth_service.dart';
import 'features/auth/data/biometric_login_service.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/data/auth_session_storage.dart';
import 'features/auth/domain/auth_session.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/customers/data/api_customer_repository.dart';
import 'features/customers/data/customer_repository.dart';
import 'features/customers/presentation/dashboard_page.dart';
import 'features/transactions/data/api_transaction_repository.dart';
import 'features/transactions/data/transaction_repository.dart';

class GoitResellerApp extends StatefulWidget {
  const GoitResellerApp({super.key});

  @override
  State<GoitResellerApp> createState() => _GoitResellerAppState();
}

class _GoitResellerAppState extends State<GoitResellerApp>
    with WidgetsBindingObserver {
  final _authenticatedNavigatorKey = GlobalKey<NavigatorState>();
  final _unauthenticatedNavigatorKey = GlobalKey<NavigatorState>();
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final AuthSessionStorage _authSessionStorage;
  late final BiometricLoginService _biometricLoginService;
  late final CustomerRepository _customerRepository;
  late final TransactionRepository _transactionRepository;
  AuthSession? _session;
  DateTime? _sessionExpiresAt;
  Locale? _locale;
  Timer? _sessionExpiryTimer;
  bool _isRestoringSession = true;
  bool _isClearingSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apiClient = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      httpClient: http.Client(),
      onUnauthorized: _handleUnauthorized,
    );
    _authService = ApiAuthService(_apiClient);
    _authSessionStorage = AuthSessionStorage();
    _biometricLoginService = DeviceBiometricLoginService();
    _customerRepository = ApiCustomerRepository(_apiClient);
    _transactionRepository = ApiTransactionRepository(_apiClient);
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionExpiryTimer?.cancel();
    _apiClient.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_expireSessionIfNeeded());
    }
  }

  Future<void> _restoreSession() async {
    final storedSession = await _authSessionStorage.loadSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = storedSession?.session;
      _sessionExpiresAt = storedSession?.expiresAt;
      _isRestoringSession = false;
    });

    _scheduleSessionExpiry(_sessionExpiresAt);
  }

  Future<void> _persistSession(
    AuthSession session, {
    required DateTime expiresAt,
  }) {
    return _authSessionStorage.saveSession(session, expiresAt: expiresAt);
  }

  void _scheduleSessionExpiry(DateTime? expiresAt) {
    _sessionExpiryTimer?.cancel();

    if (expiresAt == null) {
      return;
    }

    final duration = expiresAt.difference(DateTime.now());
    if (duration <= Duration.zero) {
      unawaited(_expireSession());
      return;
    }

    _sessionExpiryTimer = Timer(duration, () {
      unawaited(_expireSession());
    });
  }

  Future<void> _expireSessionIfNeeded() async {
    final expiresAt = _sessionExpiresAt;
    if (expiresAt == null || DateTime.now().isBefore(expiresAt)) {
      return;
    }

    await _expireSession();
  }

  Future<void> _expireSession() async {
    if (_isClearingSession) {
      return;
    }

    _isClearingSession = true;
    try {
      _sessionExpiryTimer?.cancel();
      await _authSessionStorage.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _session = null;
        _sessionExpiresAt = null;
      });
    } finally {
      _isClearingSession = false;
    }
  }

  void _handleLoggedIn(AuthSession session) {
    final expiresAt = DateTime.now().add(AuthSessionStorage.sessionLifetime);

    setState(() {
      _session = session;
      _sessionExpiresAt = expiresAt;
    });

    _scheduleSessionExpiry(expiresAt);
    unawaited(_persistSession(session, expiresAt: expiresAt));
  }

  void _handleLoggedOut() {
    if (_isClearingSession) {
      return;
    }

    _isClearingSession = true;
    _sessionExpiryTimer?.cancel();

    setState(() {
      _session = null;
      _sessionExpiresAt = null;
    });

    unawaited(_clearSessionStorage());
  }

  Future<void> _clearSessionStorage() async {
    try {
      await _authSessionStorage.clear();
    } finally {
      _isClearingSession = false;
    }
  }

  void _handleUnauthorized() {
    unawaited(_expireSession());
  }

  void _changeLocale(Locale locale) {
    if (_locale?.languageCode == locale.languageCode) {
      return;
    }

    setState(() {
      _locale = locale;
    });
  }

  Locale get _currentLocale {
    final candidate = _locale ?? WidgetsBinding.instance.platformDispatcher.locale;

    for (final supportedLocale in AppLocalizations.supportedLocales) {
      if (supportedLocale.languageCode == candidate.languageCode) {
        return supportedLocale;
      }
    }

    return AppLocalizations.supportedLocales.first;
  }

  Future<void> _refreshCurrentUser() async {
    await _expireSessionIfNeeded();

    final currentSession = _session;
    if (currentSession == null) {
      return;
    }

    final user = await _authService.fetchCurrentUser(currentSession);
    if (!mounted) {
      return;
    }

    setState(() {
      _session = currentSession.copyWith(user: user);
    });

    final expiresAt = _sessionExpiresAt;
    if (expiresAt != null) {
      unawaited(
        _persistSession(
          _session!,
          expiresAt: expiresAt,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSession =
        _session != null &&
        _sessionExpiresAt != null &&
        DateTime.now().isBefore(_sessionExpiresAt!);
    final navigatorKey = hasActiveSession
        ? _authenticatedNavigatorKey
        : _unauthenticatedNavigatorKey;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: _locale,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return supportedLocales.first;
        }

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        return supportedLocales.first;
      },
      home: _isRestoringSession
          ? const _AppBootstrapScreen()
          : !hasActiveSession
          ? LoginPage(
              authService: _authService,
              biometricLoginService: _biometricLoginService,
              currentLocale: _currentLocale,
              onLoggedIn: _handleLoggedIn,
              onLocaleChanged: _changeLocale,
            )
          : DashboardPage(
              session: _session!,
              authService: _authService,
              customerRepository: _customerRepository,
              currentLocale: _currentLocale,
              transactionRepository: _transactionRepository,
              onLoggedOut: _handleLoggedOut,
              onRefreshCurrentUser: _refreshCurrentUser,
              onLocaleChanged: _changeLocale,
            ),
    );
  }
}

class _AppBootstrapScreen extends StatelessWidget {
  const _AppBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BrandedBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandLogo(width: 220),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
