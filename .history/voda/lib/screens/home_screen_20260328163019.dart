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
    final cx = w / 2;

    // ── Geometry ─────────────────────────────────────────────────────
    // Rim oval (top opening, 3-D perspective)
    const double rimHWf = 0.335; // half-width fraction
    const double rimHHf = 0.038; // half-height fraction (perspective flatness)
    final rimHW  = w * rimHWf;
    final rimHH  = h * rimHHf;
    final rimCY  = h * 0.065;          // y-centre of the rim ellipse
    final wallTopY = rimCY + rimHH;    // walls begin just below rim

    // Wall half-widths (taper inwards going down)
    final wTopHW = w * rimHWf;        // matches the rim exactly
    final wBotHW = w * 0.220;
    final wallBotY  = h * 0.835;

    // Thick base below body
    final baseTopY  = wallBotY;
    final baseBotY  = h * 0.965;
    final baseL = cx - wBotHW - 3;
    final baseR = cx + wBotHW + 3;

    // ── Body path ─────────────────────────────────────────────────────
    // Cubic-bezier sides give a very subtle outward belly at mid-height
    // (classic tumbler silhouette)
    final ctrlY  = (wallTopY + wallBotY) * 0.5;
    final bulge  = w * 0.012;  // tiny outward push at mid-height

    final bodyPath = Path()
      ..moveTo(cx - wTopHW, wallTopY)
      ..cubicTo(
        cx - wTopHW - bulge, ctrlY,
        cx - wBotHW - bulge, wallBotY - 22,
        cx - wBotHW,         wallBotY - 22,
      )
      ..quadraticBezierTo(cx - wBotHW, wallBotY, cx, wallBotY)
      ..quadraticBezierTo(cx + wBotHW, wallBotY, cx + wBotHW, wallBotY - 22)
      ..cubicTo(
        cx + wBotHW + bulge, wallBotY - 22,
        cx + wTopHW + bulge, ctrlY,
        cx + wTopHW,         wallTopY,
      )
      ..close();

    // ── Glass body — frosted gradient (lighter centre = curved glass) ─
    final bodyRect = Rect.fromLTWH(cx - wTopHW, wallTopY, wTopHW * 2, wallBotY - wallTopY);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          stops: const [0.0, 0.35, 0.65, 1.0],
          colors: [
            const Color(0xFFBBDEFB).withAlpha(160),
            const Color(0xFFF0F8FF).withAlpha(220),
            const Color(0xFFE3F2FD).withAlpha(200),
            const Color(0xFFBBDEFB).withAlpha(160),
          ],
        ).createShader(bodyRect),
    );

    // ── Water fill ────────────────────────────────────────────────────
    if (fillLevel > 0.005) {
      canvas.save();
      canvas.clipPath(bodyPath);

      final liquidH = wallBotY - wallTopY;
      final waterY  = wallTopY + liquidH * (1 - fillLevel);
      final waterRect = Rect.fromLTWH(0, waterY, w, wallBotY - waterY);

      // Back wave — deeper, more opaque
      canvas.drawPath(
        _wave(size, waterY + 8, 5, wavePhase + pi, wallBotY),
        Paint()..color = const Color(0xFF1565C0).withAlpha(170),
      );
      // Front wave — blue gradient
      canvas.drawPath(
        _wave(size, waterY, 4, wavePhase, wallBotY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF90CAF9), Color(0xFF1565C0)],
          ).createShader(waterRect),
      );

      _drawBubbles(canvas, size, waterY, wallBotY);
      canvas.restore();
    }

    // ── Inner wall lines (show glass thickness) ───────────────────────
    final innerOffset = 7.0;
    // Left inner edge
    canvas.drawLine(
      Offset(cx - wTopHW + innerOffset, wallTopY + 6),
      Offset(cx - wBotHW + innerOffset - 1, wallBotY - 28),
      Paint()
        ..color = Colors.white.withAlpha(130)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    // Right inner edge
    canvas.drawLine(
      Offset(cx + wTopHW - innerOffset, wallTopY + 6),
      Offset(cx + wBotHW - innerOffset + 1, wallBotY - 28),
      Paint()
        ..color = Colors.white.withAlpha(60)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Body outline ──────────────────────────────────────────────────
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF64B5F6).withAlpha(210)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Base (thick glass bottom) ─────────────────────────────────────
    final baseRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(baseL, baseTopY, baseR - baseL, baseBotY - baseTopY),
      topLeft:     const Radius.circular(3),
      topRight:    const Radius.circular(3),
      bottomLeft:  const Radius.circular(13),
      bottomRight: const Radius.circular(13),
    );
    canvas.drawRRect(
      baseRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [
            const Color(0xFFBBDEFB),
            const Color(0xFF42A5F5).withAlpha(220),
          ],
        ).createShader(Rect.fromLTWH(baseL, baseTopY, baseR - baseL, baseBotY - baseTopY)),
    );
    canvas.drawRRect(
      baseRRect,
      Paint()
        ..color = const Color(0xFF64B5F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Base top highlight
    canvas.drawLine(
      Offset(baseL + 8, baseTopY + 5),
      Offset(baseR - 8, baseTopY + 5),
      Paint()
        ..color = Colors.white.withAlpha(120)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // ── Rim — 3-D oval ────────────────────────────────────────────────
    final rimOval = Rect.fromCenter(
      center: Offset(cx, rimCY),
      width:  rimHW * 2,
      height: rimHH * 2,
    );
    // Outer oval fill (glass ring)
    canvas.drawOval(rimOval, Paint()..color = const Color(0xFF90CAF9).withAlpha(190));
    // Inner oval (the air/liquid opening)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, rimCY),
        width:  (rimHW - 5.5) * 2,
        height: (rimHH - 3.0) * 2,
      ),
      Paint()..color = const Color(0xFFF0F8FF).withAlpha(210),
    );
    // Rim border
    canvas.drawOval(
      rimOval,
      Paint()
        ..color = const Color(0xFF64B5F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Rim highlight catch-light
    canvas.drawLine(
      Offset(cx - rimHW * 0.7, rimCY - rimHH * 0.55),
      Offset(cx + rimHW * 0.1, rimCY - rimHH * 0.75),
      Paint()
        ..color = Colors.white.withAlpha(210)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Left shine strip (gradient fade) ─────────────────────────────
    final shineX0 = cx - wTopHW + 9;
    final shineX1 = cx - wBotHW + 7;
    final shineH  = (wallBotY - wallTopY) * 0.52;
    final shineRect = Rect.fromLTWH(shineX0 - 8, wallTopY + 8, 20, shineH);
    canvas.drawPath(
      Path()
        ..moveTo(shineX0,      wallTopY + 8)
        ..lineTo(shineX0 + 13, wallTopY + 8)
        ..lineTo(shineX1 + 9,  wallTopY + shineH)
        ..lineTo(shineX1 - 5,  wallTopY + shineH)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end:   Alignment.centerRight,
          colors: [Colors.white.withAlpha(185), Colors.white.withAlpha(0)],
        ).createShader(shineRect),
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

  void _drawBubbles(Canvas canvas, Size s, double waterY, double bottom) {
    if (fillLevel < 0.06) return;
    final paint = Paint()..color = Colors.white.withAlpha(110);
    final filled = bottom - waterY;
    const defs = [
      (xF: 0.30, yF: 0.70, r: 3.0),
      (xF: 0.56, yF: 0.40, r: 2.0),
      (xF: 0.42, yF: 0.85, r: 2.5),
      (xF: 0.68, yF: 0.25, r: 2.5),
      (xF: 0.36, yF: 0.55, r: 1.5),
    ];
    for (final b in defs) {
      final dy = (sin(wavePhase + b.xF * 7) * 0.03 * filled).abs();
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

