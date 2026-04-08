import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/customer_service_record.dart';

class CustomerServiceCard extends StatelessWidget {
  const CustomerServiceCard({
    required this.record,
    this.onAddCredit,
    this.onExtendService,
    this.isExtendingService = false,
    super.key,
  });

  final CustomerServiceRecord record;
  final VoidCallback? onAddCredit;
  final VoidCallback? onExtendService;
  final bool isExtendingService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: theme.appCardShape(),
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
                      : '${record.service.name} \u2022 ${record.subscriptionName}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.appMutedTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (record.status != null)
                      StatusPill(
                        label: record.status!,
                        backgroundColor: const Color(0xFFF0FDFA),
                        textColor: const Color(0xFF115E59),
                      ),
                    if (record.radiusStatus != null)
                      StatusPill(
                        label: record.radiusStatus!,
                        backgroundColor: const Color(0xFFEFF6FF),
                        textColor: const Color(0xFF1D4ED8),
                      ),
                    StatusPill(
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
                DetailChip(
                  label: context.l10n.mobileLabel,
                  value: record.mobile,
                  icon: Icons.phone_outlined,
                ),
                if (record.username.isNotEmpty)
                  DetailChip(
                    label: context.l10n.usernameFieldLabel,
                    value: record.username,
                    icon: Icons.alternate_email,
                  ),
                if (record.effectivePrice != null)
                  DetailChip(
                    label: context.l10n.priceLabel,
                    value: formatMoney(record.effectivePrice),
                    icon: Icons.sell_outlined,
                  ),
                DetailChip(
                  label: context.l10n.creditLabel,
                  value: formatMoney(record.creditBalance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                DetailChip(
                  label: context.l10n.debitLabel,
                  value: formatMoney(record.debitBalance),
                  icon: Icons.payments_outlined,
                ),
                if (record.startDate != null)
                  DetailChip(
                    label: context.l10n.startLabel,
                    value: record.startDate!,
                    icon: Icons.event_available_outlined,
                  ),
                if (record.endDate != null)
                  DetailChip(
                    label: context.l10n.endLabel,
                    value: record.endDate!,
                    icon: Icons.event_busy_outlined,
                  ),
              ],
            ),
            if (onAddCredit != null || onExtendService != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    if (onExtendService != null)
                      OutlinedButton.icon(
                        onPressed: isExtendingService ? null : onExtendService,
                        icon: isExtendingService
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.event_repeat_outlined),
                        label: Text(context.l10n.extendServiceAction),
                      ),
                    if (onAddCredit != null)
                      ElevatedButton.icon(
                        onPressed: onAddCredit,
                        icon: const Icon(Icons.add_card),
                        label: Text(context.l10n.addCredit),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DetailChip extends StatelessWidget {
  const DetailChip({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
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
        color: theme.appSoftSurfaceColor,
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

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    super.key,
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

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    required this.title,
    required this.description,
    super.key,
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
