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
        width: 200,
        height: 350,
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

    // Modern bottle shape with elegant curves
    final bottleWidth = w * 0.7;
    final neckWidth = w * 0.35;
    final topY = h * 0.08;
    final neckY = h * 0.25;
    final bottomY = h * 0.92;

    // Create bottle path with smooth curves
    final bottlePath = Path()
      // Top cap
      ..moveTo(cx - neckWidth / 2, topY)
      ..lineTo(cx + neckWidth / 2, topY)
      ..lineTo(cx + neckWidth / 2, neckY)
      // Smooth curve to body
      ..quadraticBezierTo(
        cx + neckWidth / 2, neckY + 20,
        cx + bottleWidth / 2, neckY + 30,
      )
      // Body sides
      ..lineTo(cx + bottleWidth / 2, bottomY - 20)
      // Rounded bottom
      ..quadraticBezierTo(
        cx + bottleWidth / 2, bottomY,
        cx, bottomY,
      )
      ..quadraticBezierTo(
        cx - bottleWidth / 2, bottomY,
        cx - bottleWidth / 2, bottomY - 20,
      )
      // Left side
      ..lineTo(cx - bottleWidth / 2, neckY + 30)
      // Smooth curve to neck
      ..quadraticBezierTo(
        cx - neckWidth / 2, neckY + 20,
        cx - neckWidth / 2, neckY,
      )
      ..close();

    // Bottle background with glass effect
    final bottleRect = Rect.fromLTWH(cx - bottleWidth / 2, topY, bottleWidth, bottomY - topY);
    canvas.drawPath(
      bottlePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFE3F2FD).withOpacity(0.4),
            const Color(0xFFFFFFFF).withOpacity(0.7),
            const Color(0xFFE3F2FD).withOpacity(0.4),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bottleRect),
    );

    // Water fill with beautiful gradient
    if (fillLevel > 0.01) {
      canvas.save();
      canvas.clipPath(bottlePath);

      final liquidHeight = (bottomY - neckY - 30) * fillLevel;
      final waterTop = bottomY - liquidHeight;

      // Create water path with wave
      final waterPath = Path()..moveTo(cx - bottleWidth / 2, bottomY);

      // Draw wave at water surface
      final wavePoints = 60;
      for (int i = 0; i <= wavePoints; i++) {
        final x = (cx - bottleWidth / 2) + (bottleWidth * i / wavePoints);
        final normalizedX = i / wavePoints;
        final waveHeight = sin((normalizedX * 4 * pi) + wavePhase) * 3;
        final y = i == 0 || i == wavePoints 
            ? waterTop 
            : waterTop + waveHeight;
        
        if (i == 0) {
          waterPath.lineTo(x, y);
        } else {
          waterPath.lineTo(x, y);
        }
      }

      waterPath.lineTo(cx + bottleWidth / 2, bottomY);
      waterPath.close();

      // Draw main water with beautiful gradient
      final waterRect = Rect.fromLTWH(
        cx - bottleWidth / 2, 
        waterTop, 
        bottleWidth, 
        bottomY - waterTop,
      );
      
      canvas.drawPath(
        waterPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF42A5F5).withOpacity(0.7),
              const Color(0xFF1E88E5),
              const Color(0xFF1565C0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(waterRect),
      );

      // Add subtle highlight on water surface
      canvas.drawLine(
        Offset(cx - bottleWidth / 2 + 10, waterTop),
        Offset(cx + bottleWidth / 2 - 10, waterTop),
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );

      // Draw floating bubbles
      _drawModernBubbles(canvas, size, waterTop, bottomY, bottleWidth, cx);

      canvas.restore();
    }

    // Bottle shine/reflection
    final shinePath = Path()
      ..moveTo(cx - bottleWidth / 2 + 15, neckY + 40)
      ..lineTo(cx - bottleWidth / 2 + 30, neckY + 40)
      ..lineTo(cx - bottleWidth / 2 + 25, bottomY - 50)
      ..lineTo(cx - bottleWidth / 2 + 15, bottomY - 50)
      ..close();

    canvas.drawPath(
      shinePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.1),
          ],
        ).createShader(Rect.fromLTWH(
          cx - bottleWidth / 2 + 15,
          neckY + 40,
          15,
          bottomY - neckY - 90,
        )),
    );

    // Bottle outline with modern style
    canvas.drawPath(
      bottlePath,
      Paint()
        ..color = const Color(0xFF1976D2).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Cap detail
    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - neckWidth / 2, topY, neckWidth, 15),
      const Radius.circular(4),
    );
    
    canvas.drawRRect(
      capRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF64B5F6),
            const Color(0xFF42A5F5),
          ],
        ).createShader(Rect.fromLTWH(cx - neckWidth / 2, topY, neckWidth, 15)),
    );

    // Cap highlight
    canvas.drawRRect(
      capRect,
      Paint()
        ..color = const Color(0xFF1976D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawLine(
      Offset(cx - neckWidth / 2 + 8, topY + 5),
      Offset(cx + neckWidth / 2 - 8, topY + 5),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawModernBubbles(Canvas canvas, Size size, double waterTop, 
      double bottom, double width, double cx) {
    if (fillLevel < 0.05) return;

    final bubbles = [
      (x: 0.25, y: 0.3, r: 4.0, opacity: 0.4),
      (x: 0.7, y: 0.6, r: 3.0, opacity: 0.5),
      (x: 0.4, y: 0.75, r: 3.5, opacity: 0.45),
      (x: 0.6, y: 0.4, r: 2.5, opacity: 0.5),
      (x: 0.35, y: 0.55, r: 2.0, opacity: 0.4),
      (x: 0.8, y: 0.25, r: 2.5, opacity: 0.45),
    ];

    for (final bubble in bubbles) {
      final waterHeight = bottom - waterTop;
      final bx = cx - width / 2 + (width * bubble.x);
      final by = waterTop + (waterHeight * bubble.y);
      
      // Animated bubble movement
      final offset = sin(wavePhase * 2 + bubble.x * 10) * 5;
      
      // Bubble with gradient
      final bubbleRect = Rect.fromCircle(
        center: Offset(bx, by + offset),
        radius: bubble.r,
      );
      
      canvas.drawCircle(
        Offset(bx, by + offset),
        bubble.r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(bubble.opacity),
              Colors.white.withOpacity(bubble.opacity * 0.3),
            ],
          ).createShader(bubbleRect),
      );

      // Bubble highlight
      canvas.drawCircle(
        Offset(bx - bubble.r * 0.3, by + offset - bubble.r * 0.3),
        bubble.r * 0.4,
        Paint()..color = Colors.white.withOpacity(0.8),
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

