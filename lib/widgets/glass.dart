import 'dart:ui';

import 'package:flutter/material.dart';

class Glass extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final Border? border;

  const Glass({
    super.key,
    required this.child,
    this.blur = 8,
    this.opacity = 0.55,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.tint,
    this.padding = EdgeInsets.zero,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseTint = tint ??
        (brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.55));
    final borderColor = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.5);

    // Simple container — no BackdropFilter for performance + compatibility
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseTint.withOpacity(opacity),
        borderRadius: borderRadius,
        border: border ?? Border.all(color: borderColor, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brightness == Brightness.dark
              ? [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.02),
                ]
              : [
                  Colors.white.withOpacity(0.65),
                  Colors.white.withOpacity(0.20),
                ],
        ),
      ),
      child: child,
    );
  }
}

class GlassBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  const GlassBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = colors ??
        (dark
            ? [
                const Color(0xFF0A1A1F),
                const Color(0xFF0F0F1F),
                cs.primary.withOpacity(0.20),
              ]
            : [
                const Color(0xFFE9F5EA),
                const Color(0xFFDFEAF4),
                cs.primary.withOpacity(0.08),
              ]);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: child,
    );
  }
}
