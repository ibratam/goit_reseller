import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_background.dart';
import '../../../core/widgets/language_menu_button.dart';
import '../../../core/widgets/theme_mode_toggle_button.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/auth_session.dart';
import '../data/customer_repository.dart';
import '../domain/credit_transaction_result.dart';
import '../domain/customer_service_record.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transactions_page.dart';
import 'customer_list_page.dart';
import 'dashboard_page.dart';
import 'widgets/customer_service_card.dart';

enum _ServiceStatusFilter { all, expiringSoon, expired }

class CustomerSearchPage extends StatefulWidget {
  const CustomerSearchPage({
    required this.session,
    required this.authService,
    required this.customerRepository,
    required this.currentLocale,
    required this.transactionRepository,
    required this.onLoggedOut,
    required this.onRefreshCurrentUser,
    required this.onLocaleChanged,
    required this.onThemeToggle,
    super.key,
  });

  final AuthSession session;
  final AuthService authService;
  final CustomerRepository customerRepository;
  final Locale currentLocale;
  final TransactionRepository transactionRepository;
  final VoidCallback onLoggedOut;
  final Future<void> Function() onRefreshCurrentUser;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<Brightness> onThemeToggle;

  @override
  State<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  final _customerNameController = TextEditingController();
  final _mobileController = TextEditingController();

  List<CustomerServiceRecord> _results = const [];
  final Set<int> _extendingServiceIds = <int>{};
  _ServiceStatusFilter _serviceStatusFilter = _ServiceStatusFilter.all;
  bool _isSearching = false;
  bool _isRefreshingAccount = false;
  bool _isLoggingOut = false;
  String? _errorText;
  String _lastCriteria = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCurrentUser(silent: true);
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final l10n = context.l10n;
    final customerName = _customerNameController.text.trim();
    final mobile = _mobileController.text.trim();
    final hasStatusFilter = _serviceStatusFilter != _ServiceStatusFilter.all;

    if ((customerName.isEmpty && mobile.isEmpty && !hasStatusFilter) ||
        _isSearching) {
      setState(() {
        _results = const [];
        _lastCriteria = '';
        _errorText = l10n.enterCustomerNameOrMobileOrBoth;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _errorText = null;
      _lastCriteria = _buildCriteriaLabel(
        customerName: customerName,
        mobile: mobile,
        serviceFilter: _selectedServiceFilterLabel(l10n),
      );
    });

    try {
      final results = await widget.customerRepository.searchCustomers(
        session: widget.session,
        customerName: customerName.isEmpty ? null : customerName,
        mobile: mobile.isEmpty ? null : mobile,
        expired:
            _serviceStatusFilter == _ServiceStatusFilter.expired ? true : null,
        expiresInDays: _serviceStatusFilter == _ServiceStatusFilter.expiringSoon
            ? 3
            : null,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
      });
    } on CustomerSearchException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.message;
        _results = const [];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = l10n.searchFailedTryAgain;
        _results = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _refreshCurrentUser({bool silent = false}) async {
    if (_isRefreshingAccount) {
      return;
    }

    setState(() {
      _isRefreshingAccount = true;
    });

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
        setState(() {
          _isRefreshingAccount = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.authService.logout(widget.session);
    } catch (_) {
      // Clear the local session even if the server-side logout fails.
    } finally {
      if (mounted) {
        widget.onLoggedOut();
      }
    }
  }

  Future<void> _openAddCreditDialog(CustomerServiceRecord record) async {
    final result = await showDialog<CreditTransactionResult>(
      context: context,
      builder: (context) {
        return _AddCreditDialog(
          session: widget.session,
          customerRepository: widget.customerRepository,
          record: record,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _results = _results
          .map(
            (item) => item.id == result.subscriptionId
                ? item.copyWith(
                    creditBalance: result.creditBalance,
                    debitBalance: result.debitBalance,
                  )
                : item,
          )
          .toList(growable: false);
    });

    _showMessage(
      context.l10n.transactionCompleted(
        result.transactionNumber,
        formatMoney(result.creditBalance),
      ),
    );

    await _refreshCurrentUser(silent: true);
  }

  Future<void> _extendService(CustomerServiceRecord record) async {
    final l10n = context.l10n;
    if (_extendingServiceIds.contains(record.id)) {
      return;
    }

    setState(() {
      _extendingServiceIds.add(record.id);
    });

    try {
      final result = await widget.customerRepository.extendService(
        session: widget.session,
        customerServiceId: record.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = _results
            .map(
              (item) => item.id == record.id
                  ? item.copyWith(
                      startDate: result.startExtendedDate,
                      endDate: result.endExtendedDate,
                    )
                  : item,
            )
            .toList(growable: false);
      });

      _showMessage(
        l10n.serviceExtendedUntil(result.endExtendedDate),
      );
    } on CustomerSearchException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.unableToExtendService);
      }
    } finally {
      if (mounted) {
        setState(() {
          _extendingServiceIds.remove(record.id);
        });
      }
    }
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

  Future<void> _openExpiringCustomersPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerListPage(
          session: widget.session,
          customerRepository: widget.customerRepository,
          filter: CustomerListFilter.expiringSoon,
        ),
      ),
    );
  }

  Future<void> _openExpiredCustomersPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerListPage(
          session: widget.session,
          customerRepository: widget.customerRepository,
          filter: CustomerListFilter.expired,
        ),
      ),
    );
  }

  Drawer _buildDrawer(
      BuildContext context, AppLocalizations l10n, dynamic user) {
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
              decoration: const BoxDecoration(
                color: Color(0xFF0F766E),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(l10n.dashboardTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => DashboardPage(
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
              leading: const Icon(Icons.manage_search_outlined),
              title: Text(l10n.customerSearchTitle),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(l10n.expiringCustomersTitle),
              onTap: () {
                Navigator.of(context).pop();
                _openExpiringCustomersPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: Text(l10n.expiredCustomersTitle),
              onTap: () {
                Navigator.of(context).pop();
                _openExpiredCustomersPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l10n.transactionsTitle),
              onTap: () {
                Navigator.of(context).pop();
                _openTransactionsPage();
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
              title: Text(
                l10n.logoutTooltip,
                style: const TextStyle(color: Color(0xFFDC2626)),
              ),
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

  void _showMessage(String message) {
    final localizedMessage = context.l10n.localizeDynamicMessage(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(localizedMessage)));
  }

  bool get _hasSearch => _lastCriteria.isNotEmpty;

  String _buildCriteriaLabel({
    required String customerName,
    required String mobile,
    String? serviceFilter,
  }) {
    return context.l10n.searchCriteria(
      customerName: customerName,
      mobile: mobile,
      serviceFilter: serviceFilter,
    );
  }

  String? _selectedServiceFilterLabel(AppLocalizations l10n) {
    switch (_serviceStatusFilter) {
      case _ServiceStatusFilter.all:
        return null;
      case _ServiceStatusFilter.expiringSoon:
        return l10n.expiringIn3DaysLabel;
      case _ServiceStatusFilter.expired:
        return l10n.expiredCustomersTitle;
    }
  }

  Widget _buildServiceStatusFilters(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.serviceStatusFilterLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ChoiceChip(
              label: Text(l10n.allLabel),
              selected: _serviceStatusFilter == _ServiceStatusFilter.all,
              onSelected: (_) {
                setState(() {
                  _serviceStatusFilter = _ServiceStatusFilter.all;
                });
              },
            ),
            ChoiceChip(
              label: Text(l10n.expiringIn3DaysLabel),
              selected:
                  _serviceStatusFilter == _ServiceStatusFilter.expiringSoon,
              onSelected: (_) {
                setState(() {
                  _serviceStatusFilter = _ServiceStatusFilter.expiringSoon;
                });
              },
            ),
            ChoiceChip(
              label: Text(l10n.expiredCustomersTitle),
              selected: _serviceStatusFilter == _ServiceStatusFilter.expired,
              onSelected: (_) {
                setState(() {
                  _serviceStatusFilter = _ServiceStatusFilter.expired;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final user = widget.session.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customerSearchTitle),
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
      drawer: _buildDrawer(context, l10n, user),
      body: BrandedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    shape: theme.appCardShape(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 720;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.searchCustomerServicesTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Text(
                              //   l10n.searchCustomerServicesSubtitle,
                              //   style: theme.textTheme.bodyLarge?.copyWith(
                              //     color: const Color(0xFF4B5563),
                              //   ),
                              // ),
                              // const SizedBox(height: 24),
                              if (isCompact) ...[
                                TextField(
                                  controller: _customerNameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.customerNameLabel,
                                    prefixIcon: const Icon(
                                        Icons.person_search_outlined),
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _mobileController,
                                  decoration: InputDecoration(
                                    labelText: l10n.mobileNumberLabel,
                                    prefixIcon:
                                        const Icon(Icons.phone_outlined),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (_) => _search(),
                                ),
                                const SizedBox(height: 12),
                                _buildServiceStatusFilters(l10n),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _isSearching ? null : _search,
                                  child: _isSearching
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(l10n.search),
                                ),
                              ] else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _customerNameController,
                                        decoration: InputDecoration(
                                          labelText: l10n.customerNameLabel,
                                          prefixIcon: const Icon(
                                            Icons.person_search_outlined,
                                          ),
                                        ),
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _mobileController,
                                        decoration: InputDecoration(
                                          labelText: l10n.mobileNumberLabel,
                                          prefixIcon:
                                              const Icon(Icons.phone_outlined),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.search,
                                        onSubmitted: (_) => _search(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 140,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isSearching ? null : _search,
                                        child: _isSearching
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(l10n.search),
                                      ),
                                    ),
                                  ],
                                ),
                              if (!isCompact) ...[
                                const SizedBox(height: 16),
                                _buildServiceStatusFilters(l10n),
                              ],
                              if (_errorText != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  l10n.localizeDynamicMessage(_errorText!),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (!_hasSearch)
                    EmptyStateCard(
                      title: l10n.noSearchYet,
                      description: l10n.noSearchYetDescription,
                    )
                  else if (_results.isEmpty)
                    EmptyStateCard(
                      title: l10n.noResultsFound,
                      description: l10n.noSubscriptionMatched(_lastCriteria),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.resultCount(_results.length),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ..._results.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomerServiceCard(
                          record: record,
                          onAddCredit: () => _openAddCreditDialog(record),
                          onExtendService: () => _extendService(record),
                          isExtendingService:
                              _extendingServiceIds.contains(record.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCreditDialog extends StatefulWidget {
  const _AddCreditDialog({
    required this.session,
    required this.customerRepository,
    required this.record,
  });

  final AuthSession session;
  final CustomerRepository customerRepository;
  final CustomerServiceRecord record;

  @override
  State<_AddCreditDialog> createState() => _AddCreditDialogState();
}

class _AddCreditDialogState extends State<_AddCreditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _chequeDateController = TextEditingController();

  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_noteController.text.isEmpty) {
      _noteController.text = context.l10n.apiRechargeNote;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _chequeDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final result = await widget.customerRepository.addCredit(
        session: widget.session,
        customerServiceId: widget.record.id,
        amount: double.parse(_amountController.text.trim()),
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim(),
        chequeDate: _paymentMethod == 'cheque'
            ? _chequeDateController.text.trim()
            : null,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(result);
    } on CustomerSearchException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = l10n.unableToAddCredit;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.addCreditTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.record.customer.name} • ${widget.record.mobile}',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.amountLabel,
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return l10n.enterValidAmount;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: l10n.paymentMethodLabel,
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text(l10n.cashLabel),
                    ),
                    DropdownMenuItem(
                      value: 'cheque',
                      child: Text(l10n.chequeLabel),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _paymentMethod = value;
                      if (_paymentMethod != 'cheque') {
                        _chequeDateController.clear();
                      }
                    });
                  },
                ),
                if (_paymentMethod == 'cheque') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _chequeDateController,
                    decoration: InputDecoration(
                      labelText: l10n.chequeDateLabel,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      if (_paymentMethod != 'cheque') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return l10n.enterChequeDate;
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteLabel,
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 2,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.localizeDynamicMessage(_errorText!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.submit),
        ),
      ],
    );
  }
}
