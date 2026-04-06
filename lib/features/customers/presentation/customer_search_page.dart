import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_background.dart';
import '../../../core/widgets/language_menu_button.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/auth_session.dart';
import '../data/customer_repository.dart';
import '../domain/credit_transaction_result.dart';
import '../domain/customer_service_record.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transactions_page.dart';

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

  @override
  State<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  final _customerNameController = TextEditingController();
  final _mobileController = TextEditingController();

  List<CustomerServiceRecord> _results = const [];
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

    if ((customerName.isEmpty && mobile.isEmpty) || _isSearching) {
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
      );
    });

    try {
      final results = await widget.customerRepository.searchCustomers(
        session: widget.session,
        customerName: customerName.isEmpty ? null : customerName,
        mobile: mobile.isEmpty ? null : mobile,
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

  Future<void> _openTransactionsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionsPage(
          currentLocale: widget.currentLocale,
          onLocaleChanged: widget.onLocaleChanged,
          session: widget.session,
          transactionRepository: widget.transactionRepository,
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
  }) {
    return context.l10n.searchCriteria(
      customerName: customerName,
      mobile: mobile,
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
          LanguageMenuButton(
            currentLocale: widget.currentLocale,
            onLocaleChanged: widget.onLocaleChanged,
          ),
          IconButton(
            onPressed: _openTransactionsPage,
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: l10n.myTransactionsTooltip,
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
          IconButton(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            tooltip: l10n.logoutTooltip,
          ),
        ],
      ),
      body: BrandedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // const Center(
                  //   child: BrandLogo(width: 190),
                  // ),
                  // const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? user.username : user.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.signedInAs(user.username),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // _DetailChip(
                            //   label: l10n.userIdLabel,
                            //   value: '${user.id}',
                            //   icon: Icons.badge_outlined,
                            // ),
                            if (user.mobile != null)
                              _DetailChip(
                                label: l10n.mobileLabel,
                                value: user.mobile!,
                                icon: Icons.phone_outlined,
                              ),
                            // if (user.userType != null)
                            //   _DetailChip(
                            //     label: l10n.roleLabel,
                            //     value: l10n.localizeValue(user.userType!),
                            //     icon: Icons.admin_panel_settings_outlined,
                            //   ),
                            _DetailChip(
                              label: l10n.creditLabel,
                              value: formatMoney(user.creditBalance),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            _DetailChip(
                              label: l10n.debitLabel,
                              value: formatMoney(user.debitBalance),
                              icon: Icons.payments_outlined,
                            ),
                            // _DetailChip(
                            //   label: l10n.apiHostLabel,
                            //   value: _apiHostLabel.isEmpty
                            //       ? l10n.notConfigured
                            //       : _apiHostLabel,
                            //   icon: Icons.cloud_outlined,
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
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
                                  prefixIcon:
                                      const Icon(Icons.person_search_outlined),
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _mobileController,
                                decoration: InputDecoration(
                                  labelText: l10n.mobileNumberLabel,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _search(),
                              ),
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
                                  ),
                                ],
                              ),
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
                  _EmptyState(
                    title: l10n.noSearchYet,
                    description: l10n.noSearchYetDescription,
                  )
                else if (_results.isEmpty)
                  _EmptyState(
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
                      child: _CustomerServiceCard(
                        record: record,
                        onAddCredit: () => _openAddCreditDialog(record),
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

class _CustomerServiceCard extends StatelessWidget {
  const _CustomerServiceCard({
    required this.record,
    required this.onAddCredit,
  });

  final CustomerServiceRecord record;
  final VoidCallback onAddCredit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.customer.name.isEmpty
                      ? record.subscriptionName
                      : record.customer.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  record.service.name.isEmpty
                      ? record.subscriptionName
                      : '${record.service.name} • ${record.subscriptionName}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (record.status != null)
                      _StatusPill(
                        label: record.status!,
                        backgroundColor: const Color(0xFFF0FDFA),
                        textColor: const Color(0xFF115E59),
                      ),
                    if (record.radiusStatus != null)
                      _StatusPill(
                        label: record.radiusStatus!,
                        backgroundColor: const Color(0xFFEFF6FF),
                        textColor: const Color(0xFF1D4ED8),
                      ),
                    _StatusPill(
                      label: record.isOnline ? 'online' : 'offline',
                      backgroundColor: record.isOnline
                          ? const Color(0xFFECFDF3)
                          : const Color(0xFFF3F4F6),
                      textColor: record.isOnline
                          ? const Color(0xFF027A48)
                          : const Color(0xFF374151),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // _DetailChip(
                //   label: context.l10n.subscriptionIdLabel,
                //   value: '${record.id}',
                //   icon: Icons.tag_outlined,
                // ),
                // _DetailChip(
                //   label: context.l10n.customerIdLabel,
                //   value: '${record.customer.id}',
                //   icon: Icons.badge_outlined,
                // ),
                _DetailChip(
                  label: context.l10n.mobileLabel,
                  value: record.mobile,
                  icon: Icons.phone_outlined,
                ),
                if (record.username.isNotEmpty)
                  _DetailChip(
                    label: context.l10n.usernameFieldLabel,
                    value: record.username,
                    icon: Icons.alternate_email,
                  ),
                _DetailChip(
                  label: context.l10n.creditLabel,
                  value: formatMoney(record.creditBalance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _DetailChip(
                  label: context.l10n.debitLabel,
                  value: formatMoney(record.debitBalance),
                  icon: Icons.payments_outlined,
                ),
                if (record.startDate != null)
                  _DetailChip(
                    label: context.l10n.startLabel,
                    value: record.startDate!,
                    icon: Icons.event_available_outlined,
                  ),
                if (record.endDate != null)
                  _DetailChip(
                    label: context.l10n.endLabel,
                    value: record.endDate!,
                    icon: Icons.event_busy_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onAddCredit,
                icon: const Icon(Icons.add_card),
                label: Text(context.l10n.addCredit),
              ),
            ),
          ],
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

class _DetailChip extends StatelessWidget {
  const _DetailChip({
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

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.localizeValue(label),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.manage_search_outlined,
              size: 48,
              color: Color(0xFF0F766E),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
