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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<WaterProvider>(
          builder: (context, water, _) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hydration',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),

                // Main circular progress
                Expanded(
                  child: Center(
                    child: _CircularWaterProgress(progress: water.progress, water: water),
                  ),
                ),

                // Quick actions
                const _QuickActionsRow(),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular water progress
// ─────────────────────────────────────────────────────────────────────────────

class _CircularWaterProgress extends StatefulWidget {
  final double progress;
  final WaterProvider water;
  const _CircularWaterProgress({required this.progress, required this.water});

  @override
  State<_CircularWaterProgress> createState() => _CircularWaterProgressState();
}

class _CircularWaterProgressState extends State<_CircularWaterProgress>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _waveController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _progressAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();
  }

  @override
  void didUpdateWidget(_CircularWaterProgress old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      final from = _progressAnim.value;
      _progressAnim = Tween<double>(begin: from, end: widget.progress).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _waveController]),
      builder: (_, __) {
        final progress = _progressAnim.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  CustomPaint(
                    size: const Size(280, 280),
                    painter: _CircleProgressPainter(
                      progress: progress,
                      wavePhase: _waveController.value * 2 * pi,
                    ),
                  ),
                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.water.currentIntake}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0EA5E9),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ml',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}% of ${widget.water.dailyGoal} ml',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0EA5E9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
        width: 66,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5F9FF),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF42A5F5).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A73E8).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1976D2), size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF666666),
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$ml ml',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

