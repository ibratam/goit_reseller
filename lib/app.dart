import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/config/api_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/api_auth_service.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/domain/auth_session.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/customers/data/api_customer_repository.dart';
import 'features/customers/data/customer_repository.dart';
import 'features/customers/presentation/customer_search_page.dart';
import 'features/transactions/data/api_transaction_repository.dart';
import 'features/transactions/data/transaction_repository.dart';

class GoitResellerApp extends StatefulWidget {
  const GoitResellerApp({super.key});

  @override
  State<GoitResellerApp> createState() => _GoitResellerAppState();
}

class _GoitResellerAppState extends State<GoitResellerApp> {
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final CustomerRepository _customerRepository;
  late final TransactionRepository _transactionRepository;
  AuthSession? _session;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      httpClient: http.Client(),
    );
    _authService = ApiAuthService(_apiClient);
    _customerRepository = ApiCustomerRepository(_apiClient);
    _transactionRepository = ApiTransactionRepository(_apiClient);
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  void _handleLoggedIn(AuthSession session) {
    setState(() {
      _session = session;
    });
  }

  void _handleLoggedOut() {
    setState(() {
      _session = null;
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: _session == null
          ? LoginPage(
              authService: _authService,
              currentLocale: _currentLocale,
              onLoggedIn: _handleLoggedIn,
              onLocaleChanged: _changeLocale,
            )
          : CustomerSearchPage(
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
