import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class ThemeModeToggleButton extends StatelessWidget {
  const ThemeModeToggleButton({
    required this.onToggle,
    super.key,
  });

  final ValueChanged<Brightness> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return Tooltip(
      message: isDarkMode
          ? l10n.switchToLightModeTooltip
          : l10n.switchToDarkModeTooltip,
      child: IconButton(
        onPressed: () => onToggle(brightness),
        icon: Icon(
          isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        ),
      ),
    );
  }
}
