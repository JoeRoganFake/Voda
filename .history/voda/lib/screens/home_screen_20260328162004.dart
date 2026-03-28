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
        width: 150,
        height: 280,
        child: CustomPaint(
          painter: _WaterBottlePainter(
            fillLevel: _fillAnim.value,
            wavePhase: _waveController.value * 2 * pi,
          ),
        ),
      ),
    );
  }
}

class _WaterBottlePainter extends CustomPainter {
  final double fillLevel;
  final double wavePhase;

  _WaterBottlePainter({required this.fillLevel, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bottlePath = _buildBottlePath(size);

    // White interior
    canvas.drawPath(bottlePath, Paint()..color = Colors.white);

    // Water fill (clipped to bottle shape)
    if (fillLevel > 0.005) {
      canvas.save();
      canvas.clipPath(bottlePath);

      final waterY = h * (1 - fillLevel);

      // Back wave (slightly lower, more opaque)
      final backWave = _wavePath(size, waterY + 5, 7, wavePhase + pi);
      canvas.drawPath(
        backWave,
        Paint()..color = const Color(0xFF1A73E8).withAlpha(180),
      );

      // Front wave
      final frontWave = _wavePath(size, waterY, 5, wavePhase);
      canvas.drawPath(
        frontWave,
        Paint()..color = const Color(0xFF1A73E8).withAlpha(120),
      );

      canvas.restore();
    }

    // Bottle outline
    canvas.drawPath(
      bottlePath,
      Paint()
        ..color = const Color(0xFF1A73E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Cap (filled rectangle with rounded top)
    final capRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.33, 0, w * 0.34, h * 0.07),
      topLeft: const Radius.circular(5),
      topRight: const Radius.circular(5),
    );
    canvas.drawRRect(capRect, Paint()..color = const Color(0xFF1A73E8));
  }

  Path _wavePath(Size size, double waterY, double amp, double phase) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, waterY);
    for (double x = 0; x <= size.width; x++) {
      final y = waterY + sin((x / size.width * 2 * pi) + phase) * amp;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  Path _buildBottlePath(Size size) {
    final w = size.width;
    final h = size.height;

    final neckL = w * 0.34;
    final neckR = w * 0.66;
    final neckTop = h * 0.07;
    final neckBot = h * 0.21;
    final bodyL = w * 0.06;
    final bodyR = w * 0.94;
    final shoulderBot = h * 0.30;
    final bodyBot = h * 0.92;

    return Path()
      ..moveTo(neckL, neckTop)
      ..lineTo(neckR, neckTop)
      ..lineTo(neckR, neckBot)
      ..quadraticBezierTo(bodyR, neckBot, bodyR, shoulderBot)
      ..lineTo(bodyR, bodyBot)
      ..quadraticBezierTo(bodyR, h, w / 2, h)
      ..quadraticBezierTo(bodyL, h, bodyL, bodyBot)
      ..lineTo(bodyL, shoulderBot)
      ..quadraticBezierTo(bodyL, neckBot, neckL, neckBot)
      ..lineTo(neckL, neckTop)
      ..close();
  }

  @override
  bool shouldRepaint(_WaterBottlePainter old) =>
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

