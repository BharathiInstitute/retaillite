/// Performance optimization utilities
library;

import 'package:flutter/material.dart';

/// Optimized list builder with automatic disposal and lazy loading
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? separator;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final bool isLoading;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separator,
    this.emptyWidget,
    this.loadingWidget,
    this.isLoading = false,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Performance: Only build items as needed
      itemCount: items.length + (isLoading ? 1 : 0),
      // Performance: Automatic extent estimation
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return loadingWidget ??
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
        }

        final item = items[index];
        final widget = itemBuilder(context, item, index);

        if (separator != null && index < items.length - 1) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [widget, separator!],
          );
        }

        return widget;
      },
    );
  }
}

/// Optimized grid with lazy loading support
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final bool isLoading;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.emptyWidget,
    this.loadingWidget,
    this.isLoading = false,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      // Performance optimizations
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: items.length,
      itemBuilder: (context, index) =>
          itemBuilder(context, items[index], index),
    );
  }
}

/// Cached image widget with placeholder
class CachedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (imageUrl == null || imageUrl!.isEmpty) {
      image = errorWidget ?? _buildPlaceholder();
    } else if (imageUrl!.startsWith('http')) {
      image = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // Performance: Use cacheWidth/Height for memory optimization
        cacheWidth: width?.toInt(),
        cacheHeight: height?.toInt(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildPlaceholder();
        },
      );
    } else {
      image = Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildPlaceholder();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}

/// Debounced search callback
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Performance tips mixin for stateful widgets
mixin PerformanceOptimizations<T extends StatefulWidget> on State<T> {
  /// Debouncer for search operations
  late final Debouncer _searchDebouncer = Debouncer();

  /// Debounced search
  void debouncedSearch(VoidCallback action) {
    _searchDebouncer.run(action);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }
}

/// Timer for debouncing
class Timer {
  final Duration duration;
  final VoidCallback callback;
  bool _isActive = false;

  Timer(this.duration, this.callback) {
    _isActive = true;
    Future.delayed(duration, () {
      if (_isActive) callback();
    });
  }

  void cancel() {
    _isActive = false;
  }
}
