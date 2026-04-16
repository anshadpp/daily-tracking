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
    this.blur = 12,  // reduced from 22 for better performance
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
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.6);

    return RepaintBoundary(
      child: ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseTint.withOpacity(opacity),
            borderRadius: borderRadius,
            border: border ?? Border.all(color: borderColor, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: brightness == Brightness.dark
                  ? [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ]
                  : [
                      Colors.white.withOpacity(0.7),
                      Colors.white.withOpacity(0.2),
                    ],
            ),
          ),
          child: child,
        ),
      ),
      ),
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
                cs.primary.withOpacity(0.25),
              ]
            : [
                const Color(0xFFE9F5EA),
                const Color(0xFFDFEAF4),
                cs.primary.withOpacity(0.12),
              ]);
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette,
              ),
            ),
          ),
        ),
        // soft orbs
        Positioned(
          top: -80,
          left: -60,
          child: _orb(220, cs.primary.withOpacity(dark ? 0.35 : 0.25)),
        ),
        Positioned(
          top: 180,
          right: -80,
          child: _orb(
            260,
            (dark ? const Color(0xFF6A1B9A) : const Color(0xFFEF6C00))
                .withOpacity(dark ? 0.35 : 0.2),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -40,
          child: _orb(
              240, const Color(0xFF1565C0).withOpacity(dark ? 0.30 : 0.18)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _orb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}
