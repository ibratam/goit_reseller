import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({
    required this.currentLocale,
    required this.onLocaleChanged,
    super.key,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = currentLocale.languageCode.toLowerCase() == 'ar';
    final targetLocale = isArabic ? const Locale('en') : const Locale('ar');
    final targetLabel = l10n.languageOptionLabel(targetLocale.languageCode);

    return Tooltip(
      message: l10n.changeLanguageTooltip,
      child: TextButton(
        onPressed: () => onLocaleChanged(targetLocale),
        style: TextButton.styleFrom(
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 20),
            const SizedBox(height: 2),
            Text(
              targetLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
