import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:storybook_flutter/src/plugins/plugin.dart';

class ThemePanelModePlugin extends Plugin {
  ThemePanelModePlugin()
      : super(
          icon: _buildIcon,
          onPressed: _onPressed,
        );
}

Widget _buildIcon(BuildContext context) {
  final IconData icon;
  switch (AdaptiveTheme.of(context).modeChangeNotifier.value) {
    case AdaptiveThemeMode.system:
      icon = Icons.brightness_auto_outlined;
      break;
    case AdaptiveThemeMode.light:
      icon = Icons.brightness_5_outlined;
      break;
    case AdaptiveThemeMode.dark:
      icon = Icons.brightness_2_rounded;
      break;
  }

  return Icon(icon);
}

void _onPressed(BuildContext context) {
  AdaptiveTheme.of(context).toggleThemeMode();
}
