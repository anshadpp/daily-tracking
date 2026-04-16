import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/glass.dart';
import 'home_screen.dart';

// ~90 quotes — mix of Islamic wisdom, productivity, and personal growth.
// One per day, cycling.
const _quotes = [
  '"Indeed, with hardship comes ease." — Quran 94:6',
  '"The best among you are those who have the best manners." — Prophet Muhammad ﷺ',
  '"Discipline is the bridge between goals and accomplishment." — Jim Rohn',
  '"Whoever treads a path seeking knowledge, Allah will ease for him a path to Paradise." — Hadith',
  '"Do not waste water even if you were at a running stream." — Prophet Muhammad ﷺ',
  '"Your time is limited. Don\'t waste it living someone else\'s life." — Steve Jobs',
  '"Tie your camel first, then put your trust in Allah." — Hadith',
  '"The secret of getting ahead is getting started." — Mark Twain',
  '"Be in this world as if you were a stranger or a traveler." — Prophet Muhammad ﷺ',
  '"Small daily improvements are the key to staggering long-term results."',
  '"He who has no patience has nothing at all." — Arabic proverb',
  '"Focus on being productive, not busy."',
  '"The strongest among you is the one who controls his anger." — Prophet Muhammad ﷺ',
  '"If you want to go fast, go alone. If you want to go far, go together." — African proverb',
  '"Take advantage of five before five: your youth before old age…" — Hadith',
  '"We don\'t rise to the level of our goals, we fall to the level of our systems." — James Clear',
  '"Allah does not burden a soul beyond that it can bear." — Quran 2:286',
  '"The only way to do great work is to love what you do." — Steve Jobs',
  '"Seek knowledge from the cradle to the grave." — Islamic saying',
  '"Action is the foundational key to all success." — Pablo Picasso',
  '"And whoever puts their trust in Allah, He will be enough for them." — Quran 65:3',
  '"Done is better than perfect."',
  '"The best of deeds are those done consistently, even if small." — Prophet Muhammad ﷺ',
  '"A year from now you will wish you had started today." — Karen Lamb',
  '"Verily, Allah will not change the condition of a people until they change what is in themselves." — Quran 13:11',
  '"It does not matter how slowly you go as long as you do not stop." — Confucius',
  '"Make dua, then tie your camel. Trust, then work."',
  '"You are never too old to set another goal or dream a new dream." — C.S. Lewis',
  '"Every soul shall taste death." — Quran 3:185',
  '"Consistency beats intensity. Show up every day."',
  '"The believer\'s shade on the Day of Resurrection will be his charity." — Hadith',
  '"The way to get started is to quit talking and begin doing." — Walt Disney',
  '"And say: My Lord, increase me in knowledge." — Quran 20:114',
  '"Success is the sum of small efforts repeated day in and day out." — Robert Collier',
  '"Feed the hungry, visit the sick, and free the captives." — Prophet Muhammad ﷺ',
  '"Start where you are. Use what you have. Do what you can." — Arthur Ashe',
  '"Whoever is grateful, it is only for their own good." — Quran 27:40',
  '"Fall seven times, stand up eight." — Japanese proverb',
  '"The most beloved deeds to Allah are the most consistent, even if small." — Hadith',
  '"You don\'t have to be great to start, but you have to start to be great."',
  '"And We have certainly made the Quran easy for remembrance." — Quran 54:17',
  '"Your future is created by what you do today, not tomorrow."',
  '"Patience is half of faith." — Islamic wisdom',
  '"Hardships often prepare ordinary people for an extraordinary destiny." — C.S. Lewis',
  '"Speak good or remain silent." — Prophet Muhammad ﷺ',
  '"One day or day one. You decide."',
  '"The world is a provision, and the best provision is a righteous wife." — Hadith',
  '"A little progress each day adds up to big results."',
  '"O you who believe, seek help through patience and prayer." — Quran 2:153',
  '"What you do every day matters more than what you do once in a while."',
  '"Remove harm from the road; it is an act of charity." — Prophet Muhammad ﷺ',
  '"Don\'t count the days. Make the days count." — Muhammad Ali',
  '"He who does not thank people, does not thank Allah." — Hadith',
  '"The pain you feel today will be the strength you feel tomorrow."',
  '"So remember Me, and I will remember you." — Quran 2:152',
  '"Dream big. Start small. Act now."',
  '"None of you truly believes until he loves for his brother what he loves for himself." — Hadith',
  '"Success is not final, failure is not fatal: it is the courage to continue that counts." — Churchill',
  '"And whoever fears Allah, He will make a way out for him." — Quran 65:2',
  '"Invest in yourself. It pays the best interest."',
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  late final AnimationController _title = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final AnimationController _quote = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _particles = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  late final String _todayQuote;
  late final List<_Particle> _particleList;

  @override
  void initState() {
    super.initState();
    final dayIndex = DateTime.now()
        .difference(DateTime(2024))
        .inDays
        .abs() %
        _quotes.length;
    _todayQuote = _quotes[dayIndex];

    final rng = math.Random(DateTime.now().day);
    _particleList = List.generate(
        18, (_) => _Particle.random(rng));

    _run();
  }

  Future<void> _run() async {
    _particles.repeat();
    _logo.forward();
    _ring.repeat();
    await Future.delayed(const Duration(milliseconds: 500));
    _title.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _quote.forward();
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: const HomeScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logo.dispose();
    _ring.dispose();
    _title.dispose();
    _quote.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: GlassBackground(
        child: Stack(
          children: [
            // Floating particles
            AnimatedBuilder(
              animation: _particles,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(
                  particles: _particleList,
                  t: _particles.value,
                  color: cs.primary,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AnimatedLogo(logo: _logo, ring: _ring),
                    const SizedBox(height: 28),
                    // Title
                    AnimatedBuilder(
                      animation: _title,
                      builder: (_, __) {
                        final v = Curves.easeOutCubic.transform(
                            _title.value);
                        return Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - v)),
                            child: const Text(
                              'Daily Tracker',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    // Quote
                    AnimatedBuilder(
                      animation: _quote,
                      builder: (_, __) {
                        final v = Curves.easeOut.transform(
                            _quote.value);
                        // Show characters progressively (typewriter)
                        final charCount =
                            (_todayQuote.length * v).round();
                        return Opacity(
                          opacity: v.clamp(0, 1),
                          child: Glass(
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Icon(Icons.format_quote_rounded,
                                    size: 22,
                                    color: cs.primary.withOpacity(0.7)),
                                const SizedBox(height: 8),
                                Text(
                                  _todayQuote.substring(0, charCount),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                    color: cs.onSurface.withOpacity(0.85),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    // Loading dots
                    AnimatedBuilder(
                      animation: _title,
                      builder: (_, __) => Opacity(
                        opacity: _title.value,
                        child: const _LoadingDots(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x; // 0-1
  final double y; // 0-1
  final double speed; // multiplier
  final double size;
  final double phase;

  _Particle(
      {required this.x,
      required this.y,
      required this.speed,
      required this.size,
      required this.phase});

  factory _Particle.random(math.Random r) => _Particle(
        x: r.nextDouble(),
        y: r.nextDouble(),
        speed: 0.3 + r.nextDouble() * 0.7,
        size: 2 + r.nextDouble() * 4,
        phase: r.nextDouble() * math.pi * 2,
      );
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Color color;
  _ParticlePainter(
      {required this.particles, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yt = (p.y + t * p.speed * 0.3) % 1.0;
      final xt = p.x + math.sin(t * 2 * math.pi * p.speed + p.phase) * 0.03;
      final opacity =
          (0.15 + 0.35 * math.sin(t * 2 * math.pi + p.phase).abs())
              .clamp(0.0, 1.0);
      final paint = Paint()..color = color.withOpacity(opacity);
      canvas.drawCircle(
        Offset(xt * size.width, yt * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
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
        // Pulse glow
        final pulse = 0.85 + 0.15 * math.sin(ring.value * math.pi * 2);
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer orbit ring
              Transform.rotate(
                angle: ring.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _OrbitPainter(
                    progress: ring.value,
                    color: cs.primary,
                  ),
                ),
              ),
              // Glow halo
              Container(
                width: 160 * s * pulse,
                height: 160 * s * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withOpacity(0.4 * logo.value),
                      cs.primary.withOpacity(0),
                    ],
                  ),
                ),
              ),
              // Logo
              Transform.scale(
                scale: s.clamp(0.0, 1.0),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.4 * pulse),
                        blurRadius: 44,
                        spreadRadius: 6,
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
      ..color = color.withOpacity(0.10)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r, track);

    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0), color, color.withOpacity(0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      math.pi * 1.6,
      false,
      sweep,
    );

    // Orbiting dot
    final dotAngle = -math.pi / 2 + progress * 2 * math.pi;
    canvas.drawCircle(
      center + Offset(math.cos(dotAngle) * r, math.sin(dotAngle) * r),
      5,
      Paint()..color = color,
    );
    // Glow around dot
    canvas.drawCircle(
      center + Offset(math.cos(dotAngle) * r, math.sin(dotAngle) * r),
      12,
      Paint()..color = color.withOpacity(0.2),
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
