/// Theme Settings Screen - User customization for colors, fonts, sizes
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/settings/providers/theme_settings_provider.dart';
import 'package:retaillite/models/theme_settings_model.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        actions: [
          TextButton(
            onPressed: () => notifier.resetToDefaults(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSizes.pagePadding(context)),
        children: [
          // Theme Mode Section
          _buildSection(
            title: 'Theme Mode',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use System Theme'),
                  subtitle: const Text('Match your device settings'),
                  value: settings.useSystemTheme,
                  onChanged: (v) => notifier.setUseSystemTheme(v),
                ),
                if (!settings.useSystemTheme)
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark appearance'),
                    value: settings.useDarkMode,
                    onChanged: (v) => notifier.setDarkMode(v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Primary Color Section
          _buildSection(
            title: 'Primary Color',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ThemeSettingsModel.colorPresets.map((hex) {
                final isSelected = hex == settings.primaryColorHex;
                final color = Color(
                  int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                );
                return GestureDetector(
                  onTap: () => notifier.setPrimaryColor(hex),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Font Family Section
          _buildSection(
            title: 'Font Family',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ThemeSettingsModel.fontPresets.map((font) {
                final isSelected = font == settings.fontFamily;
                return ChoiceChip(
                  label: Text(font),
                  selected: isSelected,
                  onSelected: (_) => notifier.setFontFamily(font),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Font Size Section
          _buildSection(
            title: 'Font Size',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Aa', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: settings.fontSizeScale,
                        min: 0.85,
                        max: 1.15,
                        divisions: 2,
                        label: _getFontSizeLabel(settings.fontSizeScale),
                        onChanged: (v) => notifier.setFontSizeScale(v),
                      ),
                    ),
                    const Text('Aa', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Text(
                  _getFontSizeLabel(settings.fontSizeScale),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Preview Section
          _buildSection(
            title: 'Preview',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heading Text',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Body text looks like this. You can preview how your content will appear.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Primary'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Secondary'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _getFontSizeLabel(double scale) {
    if (scale <= 0.90) return 'Small';
    if (scale <= 1.05) return 'Compact';
    return 'Large';
  }
}
