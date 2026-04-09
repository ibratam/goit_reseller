import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_background.dart';
import '../../../core/widgets/language_menu_button.dart';
import '../../../core/widgets/theme_mode_toggle_button.dart';
import '../../auth/domain/auth_session.dart';
import '../data/transaction_excel_exporter.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_history.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.onThemeToggle,
    required this.session,
    required this.transactionRepository,
    super.key,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<Brightness> onThemeToggle;
  final AuthSession session;
  final TransactionRepository transactionRepository;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _operationTypeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  TransactionHistoryQuery _query = const TransactionHistoryQuery();
  TransactionHistoryResponse? _response;
  final TransactionExcelExporter _excelExporter = TransactionExcelExporter();
  bool _isLoading = false;
  bool _isExporting = false;
  bool _filtersExpanded = false;
  String? _errorText;

  String? _transactionType;
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _operationTypeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions({int page = 1}) async {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await widget.transactionRepository.fetchTransactions(
        session: widget.session,
        query: _query,
        page: page,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
      });
    } on TransactionException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.message;
        _response = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = context.l10n.localizeDynamicMessage(
          'Unable to load transactions.',
        );
        _response = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _query = TransactionHistoryQuery(
        perPage: _query.perPage,
        transactionType: _normalizeFilter(_transactionType),
        operationType: _normalizeFilter(_operationTypeController.text),
        paymentMethod: _normalizeFilter(_paymentMethod),
        startDate: _normalizeFilter(_startDateController.text),
        endDate: _normalizeFilter(_endDateController.text),
      );
    });

    _loadTransactions();
  }

  void _clearFilters() {
    _operationTypeController.clear();
    _startDateController.clear();
    _endDateController.clear();

    setState(() {
      _transactionType = null;
      _paymentMethod = null;
      _query = TransactionHistoryQuery(perPage: _query.perPage);
    });

    _loadTransactions();
  }

  Future<List<UserTransaction>> _fetchTransactionsForExport() async {
    final exportQuery = _query.copyWith(perPage: 100);
    final firstPage = await widget.transactionRepository.fetchTransactions(
      session: widget.session,
      query: exportQuery,
      page: 1,
    );

    final allTransactions = <UserTransaction>[
      ...firstPage.transactions,
    ];

    for (var page = 2; page <= firstPage.meta.lastPage; page++) {
      final nextPage = await widget.transactionRepository.fetchTransactions(
        session: widget.session,
        query: exportQuery,
        page: page,
      );
      allTransactions.addAll(nextPage.transactions);
    }

    return allTransactions;
  }

  Future<void> _exportTransactions() async {
    final l10n = context.l10n;
    if (_isLoading || _isExporting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isExporting = true;
    });

    try {
      final transactions = await _fetchTransactionsForExport();
      if (transactions.isEmpty) {
        if (mounted) {
          _showMessage(l10n.noTransactionsToExport);
        }
        return;
      }

      final exportFile = _excelExporter.buildWorkbook(transactions);
      await SharePlus.instance.share(
        ShareParams(
          title: l10n.transactionsTitle,
          subject: l10n.transactionsTitle,
          text: l10n.transactionsExported(transactions.length),
          files: [
            XFile.fromData(
              exportFile.bytes,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              name: exportFile.fileName,
            ),
          ],
          fileNameOverrides: [exportFile.fileName],
          sharePositionOrigin: _sharePositionOrigin(),
        ),
      );

      if (mounted) {
        _showMessage(l10n.transactionsExported(transactions.length));
      }
    } on TransactionException catch (error) {
      if (mounted) {
        _showMessage(context.l10n.localizeDynamicMessage(error.message));
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.unableToExportTransactions);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Rect? _sharePositionOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return null;
    }

    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initialDate = _parseDate(controller.text) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      controller.text = _formatDate(pickedDate);
    });
  }

  String? _normalizeFilter(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim());
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final response = _response;
    final meta = response?.meta ?? const TransactionMeta();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionsTitle),
        actions: [
          IconButton(
            onPressed: _isLoading || _isExporting ? null : _exportTransactions,
            tooltip: l10n.exportTransactionsTooltip,
            icon: _isExporting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
          ThemeModeToggleButton(
            onToggle: widget.onThemeToggle,
          ),
          LanguageMenuButton(
            currentLocale: widget.currentLocale,
            onLocaleChanged: widget.onLocaleChanged,
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
                    shape: theme.appCardShape(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _filtersExpanded = !_filtersExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.filterTransactions,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        // const SizedBox(height: 12),
                                        // Text(
                                        //   l10n.filterTransactionsSubtitle,
                                        //   style: theme.textTheme.bodyLarge
                                        //       ?.copyWith(
                                        //     color: theme.appMutedTextColor,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _filtersExpanded = !_filtersExpanded;
                                      });
                                    },
                                    tooltip: _filtersExpanded
                                        ? l10n.hideFilters
                                        : l10n.showFilters,
                                    icon: AnimatedRotation(
                                      turns: _filtersExpanded ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 180),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isCompact = constraints.maxWidth < 720;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          SizedBox(
                                            width: isCompact
                                                ? double.infinity
                                                : 220,
                                            child: DropdownButtonFormField<int>(
                                              key: ValueKey(
                                                'per-page-${_query.perPage}',
                                              ),
                                              initialValue: _query.perPage,
                                              decoration: InputDecoration(
                                                labelText: l10n.perPageLabel,
                                                prefixIcon: const Icon(
                                                  Icons.format_list_numbered,
                                                ),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 10,
                                                  child: Text('10'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 20,
                                                  child: Text('20'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 50,
                                                  child: Text('50'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 100,
                                                  child: Text('100'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                if (value == null) {
                                                  return;
                                                }
                                                setState(() {
                                                  _query = _query.copyWith(
                                                    perPage: value,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                          // SizedBox(
                                          //   width: isCompact
                                          //       ? double.infinity
                                          //       : 220,
                                          //   child: DropdownButtonFormField<
                                          //       String?>(
                                          //     key: ValueKey(
                                          //       'transaction-type-${_transactionType ?? 'all'}',
                                          //     ),
                                          //     initialValue: _transactionType,
                                          //     decoration: InputDecoration(
                                          //       labelText:
                                          //           l10n.transactionTypeLabel,
                                          //       prefixIcon: const Icon(
                                          //           Icons.swap_horiz),
                                          //     ),
                                          //     items: [
                                          //       DropdownMenuItem<String?>(
                                          //         value: null,
                                          //         child: Text(l10n.allLabel),
                                          //       ),
                                          //       DropdownMenuItem<String?>(
                                          //         value: 'credit',
                                          //         child: Text(l10n.creditLabel),
                                          //       ),
                                          //       DropdownMenuItem<String?>(
                                          //         value: 'debit',
                                          //         child: Text(l10n.debitLabel),
                                          //       ),
                                          //     ],
                                          //     onChanged: (value) {
                                          //       setState(() {
                                          //         _transactionType = value;
                                          //       });
                                          //     },
                                          //   ),
                                          // ),
                                          // SizedBox(
                                          //   width: isCompact
                                          //       ? double.infinity
                                          //       : 220,
                                          //   child: DropdownButtonFormField<
                                          //       String?>(
                                          //     key: ValueKey(
                                          //       'payment-method-${_paymentMethod ?? 'all'}',
                                          //     ),
                                          //     initialValue: _paymentMethod,
                                          //     decoration: InputDecoration(
                                          //       labelText:
                                          //           l10n.paymentMethodLabel,
                                          //       prefixIcon: const Icon(
                                          //         Icons.payments_outlined,
                                          //       ),
                                          //     ),
                                          //     items: [
                                          //       DropdownMenuItem<String?>(
                                          //         value: null,
                                          //         child: Text(l10n.allLabel),
                                          //       ),
                                          //       DropdownMenuItem<String?>(
                                          //         value: 'cash',
                                          //         child: Text(l10n.cashLabel),
                                          //       ),
                                          //       DropdownMenuItem<String?>(
                                          //         value: 'cheque',
                                          //         child: Text(l10n.chequeLabel),
                                          //       ),
                                          //     ],
                                          //     onChanged: (value) {
                                          //       setState(() {
                                          //         _paymentMethod = value;
                                          //       });
                                          //     },
                                          //   ),
                                          // ),
                                          // SizedBox(
                                          //   width: isCompact
                                          //       ? double.infinity
                                          //       : 220,
                                          //   child: TextField(
                                          //     controller:
                                          //         _operationTypeController,
                                          //     decoration: InputDecoration(
                                          //       labelText:
                                          //           l10n.operationTypeLabel,
                                          //       prefixIcon:
                                          //           const Icon(Icons.tune),
                                          //     ),
                                          //   ),
                                          // ),
                                          SizedBox(
                                            width: isCompact
                                                ? double.infinity
                                                : 220,
                                            child: TextField(
                                              controller: _startDateController,
                                              readOnly: true,
                                              decoration: InputDecoration(
                                                labelText: l10n.startDateLabel,
                                                prefixIcon: const Icon(
                                                  Icons.event_outlined,
                                                ),
                                                suffixIcon: IconButton(
                                                  onPressed:
                                                      _startDateController
                                                              .text.isEmpty
                                                          ? null
                                                          : () {
                                                              _startDateController
                                                                  .clear();
                                                              setState(() {});
                                                            },
                                                  icon: const Icon(Icons.close),
                                                ),
                                              ),
                                              onTap: () => _pickDate(
                                                  _startDateController),
                                            ),
                                          ),
                                          SizedBox(
                                            width: isCompact
                                                ? double.infinity
                                                : 220,
                                            child: TextField(
                                              controller: _endDateController,
                                              readOnly: true,
                                              decoration: InputDecoration(
                                                labelText: l10n.endDateLabel,
                                                prefixIcon: const Icon(
                                                  Icons.event_busy_outlined,
                                                ),
                                                suffixIcon: IconButton(
                                                  onPressed: _endDateController
                                                          .text.isEmpty
                                                      ? null
                                                      : () {
                                                          _endDateController
                                                              .clear();
                                                          setState(() {});
                                                        },
                                                  icon: const Icon(Icons.close),
                                                ),
                                              ),
                                              onTap: () =>
                                                  _pickDate(_endDateController),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          SizedBox(
                                            width: isCompact
                                                ? double.infinity
                                                : 160,
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _applyFilters,
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 18,
                                                      width: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Text(l10n.apply),
                                            ),
                                          ),
                                          SizedBox(
                                            width: isCompact
                                                ? double.infinity
                                                : 160,
                                            child: OutlinedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _clearFilters,
                                              child: Text(l10n.clear),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_errorText != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.localizeDynamicMessage(
                                              _errorText!),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
                            secondChild: const SizedBox.shrink(),
                            crossFadeState: _filtersExpanded
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 180),
                            sizeCurve: Curves.easeInOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (response != null)
                    Card(
                      shape: theme.appCardShape(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetaChip(
                              label: l10n.totalLabel,
                              value: '${meta.total}',
                            ),
                            _MetaChip(
                              label: l10n.pageLabel,
                              value: '${meta.currentPage} / ${meta.lastPage}',
                            ),
                            _MetaChip(
                              label: l10n.perPageLabel,
                              value: '${meta.perPage}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_isLoading && response == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (response == null || response.transactions.isEmpty)
                    _TransactionsEmptyState(
                      title: _errorText == null
                          ? l10n.noTransactionsFound
                          : l10n.transactionsUnavailable,
                      description: _errorText == null
                          ? l10n.noTransactionsMatchedFilters
                          : l10n.unusableTransactionList,
                    )
                  else ...[
                    ...response.transactions.map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TransactionCard(transaction: transaction),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading || meta.currentPage <= 1
                                ? null
                                : () => _loadTransactions(
                                      page: meta.currentPage - 1,
                                    ),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(l10n.previous),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading || meta.currentPage >= meta.lastPage
                                    ? null
                                    : () => _loadTransactions(
                                          page: meta.currentPage + 1,
                                        ),
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(l10n.next),
                          ),
                        ),
                      ],
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final UserTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit =
        (transaction.transactionType ?? '').toLowerCase() == 'credit';
    final titleNumber = transaction.transactionNumber ?? transaction.number;
    final resolvedType = transaction.transactionType ??
        (transaction.credit > 0
            ? 'credit'
            : transaction.debit > 0
                ? 'debit'
                : 'transaction');

    return Card(
      shape: theme.appCardShape(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.l10n.transactionNumber(titleNumber),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _TypePill(
                  label: resolvedType,
                  backgroundColor: isCredit
                      ? const Color(0xFFECFDF3)
                      : const Color(0xFFFEF3F2),
                  textColor: isCredit
                      ? const Color(0xFF027A48)
                      : const Color(0xFFB42318),
                ),
                if (transaction.paymentMethod != null)
                  _TypePill(
                    label: transaction.paymentMethod!,
                    backgroundColor: const Color(0xFFF4F3FF),
                    textColor: const Color(0xFF5925DC),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (transaction.createdAt != null)
              Text(
                transaction.createdAt!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.appMutedTextColor,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetaChip(
                  label: context.l10n.amountChipLabel,
                  value: formatMoney(transaction.effectiveAmount),
                ),
                if (transaction.resolvedFromName != null)
                  _MetaChip(
                    label: context.l10n.fromLabel,
                    value: transaction.resolvedFromName!,
                  ),
                if (transaction.resolvedToName != null)
                  _MetaChip(
                    label: context.l10n.toLabel,
                    value: transaction.resolvedToName!,
                  ),
                if (transaction.transfersCount > 0)
                  _MetaChip(
                    label: context.l10n.transfersLabel,
                    value: '${transaction.transfersCount}',
                  ),
                if (transaction.hasLegacyBalanceFields) ...[
                  _MetaChip(
                    label: context.l10n.debitLabel,
                    value: formatMoney(transaction.debit),
                  ),
                  _MetaChip(
                    label: context.l10n.creditLabel,
                    value: formatMoney(transaction.credit),
                  ),
                  _MetaChip(
                    label: context.l10n.balanceLabel,
                    value: formatMoney(transaction.balance),
                  ),
                  _MetaChip(
                    label: context.l10n.lastBalanceLabel,
                    value: formatMoney(transaction.lastBalance),
                  ),
                  if (transaction.operationType != null)
                    _MetaChip(
                      label: context.l10n.operationLabel,
                      value: context.l10n.localizeValue(
                        transaction.operationType!,
                      ),
                    ),
                  if (transaction.chequeDate != null)
                    _MetaChip(
                      label: context.l10n.chequeDateShortLabel,
                      value: transaction.chequeDate!,
                    ),
                ],
              ],
            ),
            if (transaction.note != null) ...[
              const SizedBox(height: 16),
              Text(
                transaction.note!,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            if (transaction.transfers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                context.l10n.transfersLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...transaction.transfers.map(
                (transfer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TransferCard(transfer: transfer),
                ),
              ),
            ] else if (transaction.fromAccount != null ||
                transaction.toAccount != null) ...[
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 700;

                  if (isCompact) {
                    return Column(
                      children: [
                        _AccountCard(
                          title: context.l10n.fromAccountTitle,
                          account: transaction.fromAccount,
                        ),
                        const SizedBox(height: 12),
                        _AccountCard(
                          title: context.l10n.toAccountTitle,
                          account: transaction.toAccount,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _AccountCard(
                          title: context.l10n.fromAccountTitle,
                          account: transaction.fromAccount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccountCard(
                          title: context.l10n.toAccountTitle,
                          account: transaction.toAccount,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.title,
    required this.account,
  });

  final String title;
  final TransactionAccount? account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appSoftSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (account == null)
            Text(
              context.l10n.noAccountDetails,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appSubtleTextColor,
              ),
            )
          else ...[
            Text(account!.informationName ?? account!.name),
            const SizedBox(height: 6),
            Text(
              context.l10n.accountTypeLabel(
                context.l10n.localizeValue(account!.accountType ?? '-'),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appSubtleTextColor,
              ),
            ),
            Text(
              context.l10n.accountNatureLabel(
                context.l10n.localizeValue(account!.accountNature ?? '-'),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appSubtleTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer});

  final TransactionTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromLabel = transfer.fromAccount?.informationName ??
        transfer.fromAccount?.name ??
        '-';
    final toLabel =
        transfer.toAccount?.informationName ?? transfer.toAccount?.name ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appSoftSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.transferAmount(formatMoney(transfer.amount)),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.transferFrom(fromLabel)),
          const SizedBox(height: 4),
          Text(context.l10n.transferTo(toLabel)),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.appSoftSurfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _TransactionsEmptyState extends StatelessWidget {
  const _TransactionsEmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: theme.appCardShape(),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
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
                color: theme.appMutedTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
