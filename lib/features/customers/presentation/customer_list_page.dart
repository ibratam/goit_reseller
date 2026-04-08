import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/brand_background.dart';
import '../../auth/domain/auth_session.dart';
import '../data/customer_repository.dart';
import '../domain/customer_service_record.dart';
import 'widgets/customer_service_card.dart';

enum CustomerListFilter { expiringSoon, expired }

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({
    required this.session,
    required this.customerRepository,
    required this.filter,
    super.key,
  });

  final AuthSession session;
  final CustomerRepository customerRepository;
  final CustomerListFilter filter;

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<CustomerServiceRecord> _records = const [];
  final Set<int> _extendingServiceIds = <int>{};
  bool _isLoading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final results = await widget.customerRepository.searchCustomers(
        session: widget.session,
        expired: widget.filter == CustomerListFilter.expired ? true : null,
        expiresInDays: widget.filter == CustomerListFilter.expiringSoon ? 3 : null,
        limit: 100,
      );

      if (!mounted) return;
      setState(() {
        _records = results;
      });
    } on CustomerSearchException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = context.l10n.failedToLoadCustomers;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

      if (!mounted) return;

      setState(() {
        _records = _records
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.serviceExtendedUntil(result.endExtendedDate))),
        );
    } on CustomerSearchException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.localizeDynamicMessage(error.message))),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.unableToExtendService)),
        );
    } finally {
      if (mounted) {
        setState(() {
          _extendingServiceIds.remove(record.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final title = widget.filter == CustomerListFilter.expiringSoon
        ? l10n.expiringCustomersTitle
        : l10n.expiredCustomersTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: BrandedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: _buildContent(theme, l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorText != null) {
      return _buildError(l10n);
    }

    if (_records.isEmpty) {
      return _buildEmpty(l10n);
    }

    return _buildList(theme, l10n);
  }

  Widget _buildError(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.localizeDynamicMessage(_errorText!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF4B5563),
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadCustomers,
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

  Widget _buildEmpty(AppLocalizations l10n) {
    final icon = widget.filter == CustomerListFilter.expiringSoon
        ? Icons.schedule_outlined
        : Icons.event_busy_outlined;
    final message = widget.filter == CustomerListFilter.expiringSoon
        ? l10n.noExpiringSubscriptions
        : l10n.noExpiredSubscriptions;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(icon, size: 48, color: const Color(0xFF0F766E)),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(ThemeData theme, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            l10n.resultCount(_records.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ..._records.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomerServiceCard(
              record: record,
              onExtendService: () => _extendService(record),
              isExtendingService: _extendingServiceIds.contains(record.id),
            ),
          ),
        ),
      ],
    );
  }
}
