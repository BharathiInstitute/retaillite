import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:retaillite/core/design/design_system.dart';

/// A reusable widget that displays the store logo from a path (HTTP URL or local file),
/// falling back to a storefront icon if no logo is set.
class ShopLogoWidget extends StatelessWidget {
  final String? logoPath;
  final double size;
  final double borderRadius;
  final double iconSize;

  const ShopLogoWidget({
    super.key,
    required this.logoPath,
    this.size = 36,
    this.borderRadius = 8,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath != null && logoPath!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.transparent : AppColors.primary,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo ? _buildLogoImage() : _buildFallbackIcon(),
    );
  }

  Widget _buildLogoImage() {
    if (logoPath!.startsWith('http')) {
      return Image.network(
        logoPath!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackIcon(),
      );
    }
    // Local file (non-web only)
    if (!kIsWeb) {
      final file = File(logoPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackIcon(),
        );
      }
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(Icons.storefront, color: Colors.white, size: iconSize),
      ),
    );
  }
}
