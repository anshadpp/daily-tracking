import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/glass.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    _logo.forward();
    _ring.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    _text.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: const HomeScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logo.dispose();
    _ring.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedLogo(logo: _logo, ring: _ring),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _text,
                builder: (_, __) => Opacity(
                  opacity: Curves.easeOut.transform(_text.value),
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - _text.value)),
                    child: Column(
                      children: [
                        const Text(
                          'Daily Tracker',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Build your day, one block at a time',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              AnimatedBuilder(
                animation: _text,
                builder: (_, __) => Opacity(
                  opacity: Curves.easeOut.transform(_text.value),
                  child: const _LoadingDots(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  final AnimationController logo;
  final AnimationController ring;
  const _AnimatedLogo({required this.logo, required this.ring});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([logo, ring]),
      builder: (_, __) {
        final s = Curves.easeOutBack.transform(logo.value.clamp(0, 1));
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer orbit ring
              Transform.rotate(
                angle: ring.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: _OrbitPainter(
                    progress: ring.value,
                    color: cs.primary,
                  ),
                ),
              ),
              // Glow halo
              Container(
                width: 150 * s,
                height: 150 * s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withOpacity(0.35 * logo.value),
                      cs.primary.withOpacity(0),
                    ],
                  ),
                ),
              ),
              // Logo
              Transform.scale(
                scale: s.clamp(0.0, 1.0),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.35),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.primary,
                        alignment: Alignment.center,
                        child: const Icon(Icons.checklist_rounded,
                            color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color color;
  _OrbitPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    final track = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r, track);

    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0), color, color.withOpacity(0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      math.pi * 1.6,
      false,
      sweep,
    );

    // dot
    final dotAngle = -math.pi / 2 + math.pi * 1.6;
    final dot = Paint()..color = color;
    canvas.drawCircle(
      center + Offset(math.cos(dotAngle) * r, math.sin(dotAngle) * r),
      5,
      dot,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.progress != progress || old.color != color;
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final offset = (i * 0.25);
          final v = ((_c.value - offset) % 1).clamp(0.0, 1.0);
          final scale = 0.6 + 0.4 * math.sin(v * math.pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withOpacity(0.4 + 0.6 * scale),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
