import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          'Voda',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<WaterProvider>(
        builder: (context, water, _) {
          return Column(
            children: [
              // Today's intake — above the bottle
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 8),
                child: Column(
                  children: [
                    const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${water.currentIntake} ml',
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    Text(
                      'of ${water.dailyGoal} ml goal  ·  ${(water.progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Animated water bottle — center
              Expanded(
                child: Center(
                  child: _AnimatedWaterBottle(progress: water.progress),
                ),
              ),

              // Drink options — below the bottle
              const _DrinkOptionsRow(),
              const SizedBox(height: 28),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated water bottle
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedWaterBottle extends StatefulWidget {
  final double progress;
  const _AnimatedWaterBottle({required this.progress});

  @override
  State<_AnimatedWaterBottle> createState() => _AnimatedWaterBottleState();
}

class _AnimatedWaterBottleState extends State<_AnimatedWaterBottle>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _waveController;
  late Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fillAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOut),
    );
    _fillController.forward();
  }

  @override
  void didUpdateWidget(_AnimatedWaterBottle old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      final from = _fillAnim.value;
      _fillAnim = Tween<double>(begin: from, end: widget.progress).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeOut),
      );
      _fillController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fillController, _waveController]),
      builder: (_, __) => SizedBox(
        width: 160,
        height: 300,
        child: CustomPaint(
          painter: _GlassPainter(
            fillLevel: _fillAnim.value,
            wavePhase: _waveController.value * 2 * pi,
          ),
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double fillLevel;
  final double wavePhase;

  _GlassPainter({required this.fillLevel, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glass geometry — tapered: wider at top, narrower at bottom
    const rimH = 8.0;
    final topL = w * 0.08;
    final topR = w * 0.92;
    final botL = w * 0.18;
    final botR = w * 0.82;
    final glassTop = h * 0.02;
    final glassBot = h * 0.97;

    // ── body path ─────────────────────────────────────────────────────
    final bodyPath = Path()
      ..moveTo(topL, glassTop + rimH)
      ..lineTo(topR, glassTop + rimH)
      ..lineTo(botR, glassBot - 14)
      ..quadraticBezierTo(botR, glassBot, w / 2, glassBot)
      ..quadraticBezierTo(botL, glassBot, botL, glassBot - 14)
      ..lineTo(topL, glassTop + rimH)
      ..close();

    // ── frosted glass background ───────────────────────────────────────
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFFF0F8FF));

    // ── water fill ────────────────────────────────────────────────────
    if (fillLevel > 0.005) {
      canvas.save();
      canvas.clipPath(bodyPath);

      final totalH = glassBot - (glassTop + rimH);
      final waterY = glassTop + rimH + totalH * (1 - fillLevel);
      final waterRect = Rect.fromLTWH(0, waterY, w, glassBot - waterY);

      final gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF64B5F6),
          Color(0xFF0D47A1),
        ],
      ).createShader(waterRect);

      // Back wave — deeper colour
      canvas.drawPath(
        _wave(size, waterY + 9, 6, wavePhase + pi, glassBot),
        Paint()..color = const Color(0xFF1565C0).withAlpha(170),
      );

      // Front wave — gradient
      canvas.drawPath(
        _wave(size, waterY, 5, wavePhase, glassBot),
        Paint()..shader = gradient,
      );

      // Bubbles
      _drawBubbles(canvas, size, waterY, glassBot);

      canvas.restore();
    }

    // ── glass outline ─────────────────────────────────────────────────
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF90CAF9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // ── rim ───────────────────────────────────────────────────────────
    final rimPath = Path()
      ..moveTo(topL - 4, glassTop)
      ..lineTo(topR + 4, glassTop)
      ..lineTo(topR, glassTop + rimH)
      ..lineTo(topL, glassTop + rimH)
      ..close();
    canvas.drawPath(rimPath, Paint()..color = const Color(0xFF64B5F6));
    canvas.drawPath(
      rimPath,
      Paint()
        ..color = const Color(0xFFBBDEFB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Rim top highlight
    canvas.drawLine(
      Offset(topL - 4, glassTop),
      Offset(topR + 4, glassTop),
      Paint()
        ..color = Colors.white.withAlpha(200)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // ── left glass shine ──────────────────────────────────────────────
    final shineLeft = Path()
      ..moveTo(topL + 6, glassTop + rimH + 10)
      ..lineTo(topL + 18, glassTop + rimH + 10)
      ..lineTo(botL + 8, glassBot * 0.52)
      ..lineTo(botL - 1, glassBot * 0.52)
      ..close();
    canvas.drawPath(shineLeft, Paint()..color = Colors.white.withAlpha(140));

    // ── right subtle reflection ───────────────────────────────────────
    canvas.drawLine(
      Offset(topR - 10, glassTop + rimH + 12),
      Offset(botR - 8, glassBot * 0.38),
      Paint()
        ..color = Colors.white.withAlpha(60)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _wave(Size s, double y, double amp, double phase, double bottom) {
    final path = Path()..moveTo(0, bottom);
    path.lineTo(0, y);
    for (double x = 0; x <= s.width; x++) {
      path.lineTo(x, y + sin(x / s.width * 2 * pi + phase) * amp);
    }
    path.lineTo(s.width, bottom);
    path.close();
    return path;
  }

  void _drawBubbles(
      Canvas canvas, Size s, double waterY, double bottom) {
    if (fillLevel < 0.06) return;
    final paint = Paint()..color = Colors.white.withAlpha(100);
    final filled = bottom - waterY;
    final defs = [
      (xF: 0.28, yF: 0.72, r: 3.5),
      (xF: 0.58, yF: 0.42, r: 2.5),
      (xF: 0.40, yF: 0.86, r: 2.0),
      (xF: 0.70, yF: 0.22, r: 3.0),
      (xF: 0.33, yF: 0.55, r: 1.8),
    ];
    for (final b in defs) {
      final dy = (sin(wavePhase + b.xF * 7) * 0.025 * filled).abs();
      canvas.drawCircle(
        Offset(s.width * b.xF, waterY + filled * b.yF - dy),
        b.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      fillLevel != old.fillLevel || wavePhase != old.wavePhase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Drink options row
// ─────────────────────────────────────────────────────────────────────────────

class _DrinkOptionsRow extends StatelessWidget {
  const _DrinkOptionsRow();

  @override
  Widget build(BuildContext context) {
    final options = [
      (label: 'Small\nCup', ml: 150, icon: Icons.emoji_food_beverage_outlined),
      (label: 'Cup', ml: 250, icon: Icons.local_cafe_outlined),
      (label: 'Glass', ml: 350, icon: Icons.sports_bar_outlined),
      (label: 'Bottle', ml: 500, icon: Icons.water_drop_outlined),
      (label: 'Big\nBottle', ml: 750, icon: Icons.opacity),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options
            .map((o) => _DrinkOption(label: o.label, ml: o.ml, icon: o.icon))
            .toList(),
      ),
    );
  }
}

class _DrinkOption extends StatelessWidget {
  final String label;
  final int ml;
  final IconData icon;

  const _DrinkOption(
      {required this.label, required this.ml, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<WaterProvider>().addWater(ml),
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A73E8).withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1A73E8), size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$ml ml',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A73E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

