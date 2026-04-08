import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_background.dart';
import '../../../core/widgets/language_menu_button.dart';
import '../../../core/widgets/theme_mode_toggle_button.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../data/customer_repository.dart';
import '../domain/customer_service_record.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_history.dart';
import '../../transactions/presentation/transactions_page.dart';
import '../presentation/customer_list_page.dart';
import 'customer_search_page.dart';

String _pad(int n) => n.toString().padLeft(2, '0');

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.session,
    required this.authService,
    required this.customerRepository,
    required this.transactionRepository,
    required this.currentLocale,
    required this.onLoggedOut,
    required this.onRefreshCurrentUser,
    required this.onLocaleChanged,
    required this.onThemeToggle,
    super.key,
  });

  final AuthSession session;
  final AuthService authService;
  final CustomerRepository customerRepository;
  final TransactionRepository transactionRepository;
  final Locale currentLocale;
  final VoidCallback onLoggedOut;
  final Future<void> Function() onRefreshCurrentUser;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<Brightness> onThemeToggle;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  bool _isRefreshingAccount = false;
  bool _isLoggingOut = false;
  String? _errorText;

  int _expiredCount = 0;
  int _expiringIn3DaysCount = 0;
  int _todayTransactionsCount = 0;
  double _todayRevenue = 0;
  List<UserTransaction> _recentTransactions = const [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final now = DateTime.now();
    final today = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';

    try {
      final results = await Future.wait([
        widget.customerRepository.searchCustomers(
          session: widget.session,
          expired: true,
          limit: 1000,
        ),
        widget.customerRepository.searchCustomers(
          session: widget.session,
          expiresInDays: 3,
          limit: 1000,
        ),
        widget.transactionRepository.fetchTransactions(
          session: widget.session,
          query: TransactionHistoryQuery(
            startDate: today,
            endDate: today,
            perPage: 50,
          ),
          page: 1,
        ),
      ]);

      if (!mounted) return;

      final expiredList = results[0] as List<CustomerServiceRecord>;
      final threeDayList = results[1] as List<CustomerServiceRecord>;
      final txResponse = results[2] as TransactionHistoryResponse;

      final revenue = txResponse.transactions.fold<double>(
        0,
        (sum, tx) => sum + tx.effectiveAmount,
      );

      setState(() {
        _expiredCount = expiredList.length;
        _expiringIn3DaysCount = threeDayList.length;
        _todayTransactionsCount = txResponse.meta.total > 0
            ? txResponse.meta.total
            : txResponse.transactions.length;
        _todayRevenue = revenue;
        _recentTransactions = txResponse.transactions.take(5).toList();
        _isLoading = false;
      });
    } on CustomerSearchException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
        _isLoading = false;
      });
    } on TransactionException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = context.l10n.failedToLoadCustomers;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCurrentUser({bool silent = false}) async {
    if (_isRefreshingAccount) return;

    setState(() => _isRefreshingAccount = true);

    try {
      await widget.onRefreshCurrentUser();
    } on AuthException catch (error) {
      if (!silent && mounted) {
        _showMessage(context.l10n.localizeDynamicMessage(error.message));
      }
    } catch (_) {
      if (!silent && mounted) {
        _showMessage(context.l10n.unableToRefreshAccount);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingAccount = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await widget.authService.logout(widget.session);
    } catch (_) {
    } finally {
      if (mounted) widget.onLoggedOut();
    }
  }

  void _showMessage(String message) {
    final localizedMessage = context.l10n.localizeDynamicMessage(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(localizedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final user = widget.session.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          ThemeModeToggleButton(
            onToggle: widget.onThemeToggle,
          ),
          LanguageMenuButton(
            currentLocale: widget.currentLocale,
            onLocaleChanged: widget.onLocaleChanged,
          ),
          IconButton(
            onPressed:
                _isRefreshingAccount ? null : () => _refreshCurrentUser(),
            icon: _isRefreshingAccount
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: l10n.refreshUserTooltip,
          ),
        ],
      ),
      drawer: _buildDrawer(context, l10n),
      body: BrandedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _errorText != null
                      ? _buildError(l10n)
                      : ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            _buildUserCard(theme, l10n, user),
                            const SizedBox(height: 20),
                            _buildStatCards(theme, l10n),
                            const SizedBox(height: 20),
                            _buildRecentTransactions(theme, l10n),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(ThemeData theme, AppLocalizations l10n, AppUser user) {
    final mobile = user.mobile?.trim();
    final signedInAsValue = _buildSignedInAsValue(l10n, user);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.appPanelColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.appPanelBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name.isEmpty ? user.username : user.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.appStrongTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.signedInAs(signedInAsValue),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.appMutedTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final columnCount = switch (availableWidth) {
                  < 440 => 1,
                  < 760 => 2,
                  _ => 3,
                };
                const spacing = 12.0;
                final tileWidth =
                    (availableWidth - (spacing * (columnCount - 1))) /
                        columnCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _DashboardInfoTile(
                        label: l10n.mobileLabel,
                        value: (mobile != null && mobile.isNotEmpty)
                            ? mobile
                            : l10n.notConfigured,
                        icon: Icons.call_outlined,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _DashboardInfoTile(
                        label: l10n.creditLabel,
                        value: formatMoney(user.creditBalance),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _DashboardInfoTile(
                        label: l10n.debitLabel,
                        value: formatMoney(user.debitBalance),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _buildSignedInAsValue(AppLocalizations l10n, AppUser user) {
    final userType = user.userType?.trim();
    if (userType != null && userType.isNotEmpty) {
      if (l10n.isArabic) {
        return l10n.localizeValue(userType);
      }
      return formatApiMessage(userType, fallback: userType).toLowerCase();
    }

    return user.username;
  }

  Widget _buildStatCards(ThemeData theme, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = switch (constraints.maxWidth) {
          < 360 => 1,
          < 760 => 2,
          _ => 4,
        };
        const spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: tileWidth,
              child: _StatCard(
                icon: Icons.event_busy_outlined,
                iconColor: const Color(0xFFDC2626),
                label: l10n.expiredCustomersTitle,
                value: '$_expiredCount',
                subtitle: _expiredCount == 1
                    ? l10n.customersWord
                    : l10n.customersWordPlural,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CustomerListPage(
                        session: widget.session,
                        customerRepository: widget.customerRepository,
                        filter: CustomerListFilter.expired,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _StatCard(
                icon: Icons.schedule_outlined,
                iconColor: const Color(0xFFF59E0B),
                label: l10n.expiringIn3DaysLabel,
                value: '$_expiringIn3DaysCount',
                subtitle: _expiringIn3DaysCount == 1
                    ? l10n.customersWord
                    : l10n.customersWordPlural,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CustomerListPage(
                        session: widget.session,
                        customerRepository: widget.customerRepository,
                        filter: CustomerListFilter.expiringSoon,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _StatCard(
                icon: Icons.trending_up_outlined,
                iconColor: const Color(0xFF0F766E),
                label: l10n.todayRevenueLabel,
                value: formatMoney(_todayRevenue),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _StatCard(
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF6366F1),
                label: l10n.todayTransactionsLabel,
                value: '$_todayTransactionsCount',
                onTap: _openTransactionsPage,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactions(ThemeData theme, AppLocalizations l10n) {
    return Card(
      shape: theme.appCardShape(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.todayTransactionsLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openTransactionsPage,
                  child: Text(l10n.showAllLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    l10n.noTransactionsToday,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.appSubtleTextColor,
                    ),
                  ),
                ),
              )
            else
              ..._recentTransactions.map(
                (tx) => _TransactionTile(transaction: tx),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTransactionsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionsPage(
          currentLocale: widget.currentLocale,
          onLocaleChanged: widget.onLocaleChanged,
          onThemeToggle: widget.onThemeToggle,
          session: widget.session,
          transactionRepository: widget.transactionRepository,
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          shape: Theme.of(context).appCardShape(),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: 16),
                Text(
                  l10n.localizeDynamicMessage(_errorText!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).appMutedTextColor,
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.search),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context, AppLocalizations l10n) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Color(0xFF0F766E),
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
              accountName: Text(
                widget.session.user.name.isEmpty
                    ? widget.session.user.username
                    : widget.session.user.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              accountEmail: Text(widget.session.user.username),
              decoration: const BoxDecoration(color: Color(0xFF0F766E)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(l10n.dashboardTitle),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.manage_search_outlined),
              title: Text(l10n.customerSearchTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerSearchPage(
                      session: widget.session,
                      authService: widget.authService,
                      customerRepository: widget.customerRepository,
                      currentLocale: widget.currentLocale,
                      transactionRepository: widget.transactionRepository,
                      onLoggedOut: widget.onLoggedOut,
                      onRefreshCurrentUser: widget.onRefreshCurrentUser,
                      onLocaleChanged: widget.onLocaleChanged,
                      onThemeToggle: widget.onThemeToggle,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(l10n.expiringCustomersTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerListPage(
                      session: widget.session,
                      customerRepository: widget.customerRepository,
                      filter: CustomerListFilter.expiringSoon,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: Text(l10n.expiredCustomersTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerListPage(
                      session: widget.session,
                      customerRepository: widget.customerRepository,
                      filter: CustomerListFilter.expired,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l10n.transactionsTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionsPage(
                      currentLocale: widget.currentLocale,
                      onLocaleChanged: widget.onLocaleChanged,
                      onThemeToggle: widget.onThemeToggle,
                      session: widget.session,
                      transactionRepository: widget.transactionRepository,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(l10n.refreshUserTooltip),
              onTap: () {
                Navigator.of(context).pop();
                _refreshCurrentUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              title: Text(l10n.logoutTooltip,
                  style: const TextStyle(color: Color(0xFFDC2626))),
              onTap: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;

        return Card(
          shape: theme.appCardShape(),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(compact ? 14 : 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: compact ? 110 : 126,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: compact ? 24 : 28),
                    SizedBox(height: compact ? 8 : 12),
                    Text(
                      label,
                      maxLines: compact ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.appSubtleTextColor,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: (compact
                                ? theme.textTheme.titleLarge
                                : theme.textTheme.headlineSmall)
                            ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.appStrongTextColor,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.appFaintTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardInfoTile extends StatelessWidget {
  const _DashboardInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.appSoftSurfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0F8B82)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.appStrongTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.appMutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final UserTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.resolvedFromName ?? l10n.fromLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (transaction.resolvedToName != null)
                      Text(
                        transaction.resolvedToName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.appSubtleTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                formatMoney(transaction.effectiveAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          if (transaction.operationType != null ||
              transaction.paymentMethod != null) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (transaction.operationType != null)
                  Text(
                    l10n.localizeValue(transaction.operationType!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.appFaintTextColor,
                    ),
                  ),
                if (transaction.paymentMethod != null)
                  Text(
                    l10n.localizeValue(transaction.paymentMethod!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.appFaintTextColor,
                    ),
                  ),
                if (transaction.createdAt != null)
                  Text(
                    transaction.createdAt!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.appFaintTextColor,
                    ),
                  ),
              ],
            ),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }
}
