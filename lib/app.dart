/// Main app widget with providers and theme
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/features/settings/providers/theme_settings_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/router/app_router.dart';

class LiteApp extends ConsumerWidget {
  const LiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // Dynamic theme from user settings
    final theme = ref.watch(appThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);
    final themeMode = ref.watch(userThemeModeProvider);

    // Get font scale from theme settings (0.8 - 1.4)
    final themeSettings = ref.watch(themeSettingsProvider);
    final fontScale = themeSettings.fontSizeScale;

    return MaterialApp.router(
      title: 'LITE',
      debugShowCheckedModeBanner: false,
      // Dynamic theme from user preferences
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: settings.locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // Apply global font scaling to ALL text in the app
      // Also dismiss keyboard on tap-outside (prevents stuck layout on mobile web)
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(fontScale)),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
