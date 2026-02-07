/// Main app widget with providers and theme
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/theme/app_theme.dart';
import 'package:retaillite/core/theme/web_theme.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/router/app_router.dart';

class LiteApp extends ConsumerWidget {
  const LiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // Check if running on Web or Desktop
    final isWebOrDesktop =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return MaterialApp.router(
      title: 'LITE',
      debugShowCheckedModeBanner: false,
      theme: isWebOrDesktop ? WebTheme.light : AppTheme.light,
      darkTheme: AppTheme.dark, // Fallback to compatible dark theme
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: settings.locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
