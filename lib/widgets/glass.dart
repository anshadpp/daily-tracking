import 'package:flutter/material.dart';

/// Lightweight card — no blur, no gradient tricks. Works on every device.
class Glass extends StatelessWidget {
  final Widget child;
  final double blur; // ignored, kept for API compat
  final double opacity; // ignored
  final BorderRadius borderRadius;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final Border? border;

  const Glass({
    super.key,
    required this.child,
    this.blur = 0,
    this.opacity = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.tint,
    this.padding = EdgeInsets.zero,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? cs.surfaceContainerLow,
        borderRadius: borderRadius,
        border: border ??
            Border.all(color: cs.outlineVariant.withOpacity(0.3), width: 0.5),
      ),
      child: child,
    );
  }
}

/// Simple gradient background.
class GlassBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  const GlassBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: child,
    );
  }
}
