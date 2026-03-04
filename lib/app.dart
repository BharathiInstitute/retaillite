/// Main app widget with providers and theme
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/features/settings/providers/theme_settings_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/router/app_router.dart';
import 'package:retaillite/shared/widgets/announcement_banner.dart';
import 'package:retaillite/shared/widgets/update_banner.dart';
import 'package:retaillite/shared/widgets/update_dialog.dart';

class LiteApp extends ConsumerWidget {
  const LiteApp({super.key});

  /// Timestamp of last dialog check (reset after 6 hours)
  static DateTime? _lastDialogCheck;

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

    // Check if Windows — only wrap with UpdateBanner on Windows
    final isWindows = !kIsWeb && Platform.isWindows;

    return MaterialApp.router(
      title: AppConstants.appName,
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
        Widget content = GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(fontScale)),
            child: child ?? const SizedBox.shrink(),
          ),
        );

        // Wrap with AnnouncementBanner for Remote Config messages (all platforms)
        content = AnnouncementBanner(child: content);

        // Wrap with UpdateBanner on Windows for Layer 5 persistent banner
        if (isWindows) {
          content = UpdateBanner(child: content);

          // Layer 4: Show update dialog periodically (every 6 hours)
          final now = DateTime.now();
          final shouldCheck =
              _lastDialogCheck == null ||
              now.difference(_lastDialogCheck!).inHours >= 6;
          if (shouldCheck) {
            _lastDialogCheck = now;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) {
                  UpdateDialog.checkAndShow(context);
                }
              });
            });
          }
        }

        return content;
      },
    );
  }
}
