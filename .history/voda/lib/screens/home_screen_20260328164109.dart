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
      body: Consumer<WaterProvider>(
        builder: (context, water, _) {
          return Stack(
            children: [
              // Full-page water background
              _FullPageWater(progress: water.progress),
              
              // Content on top
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hydration',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: water.progress > 0.5 
                                  ? Colors.white 
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                            color: water.progress > 0.5 
                                ? Colors.white 
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),

                    // Stats
                    Expanded(
                      child: Center(
                        child: _WaterStats(water: water),
                      ),
                    ),

                    // Quick actions
                    _QuickActionsRow(progress: water.progress),
                    const SizedBox(height: 30),
                  ],
   Full page water background
// ─────────────────────────────────────────────────────────────────────────────

class _FullPageWater extends StatefulWidget {
  final double progress;
  const _FullPageWater({required this.progress});

  @override
  State<_FullPageWater> createState() => _FullPageWaterState();
}

class _FullPageWaterState extends State<_FullPageWater>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _waveController;
  late Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fillAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOutCubic),
    );
    _fillController.forward();
  }

  @override
  void didUpdateWidget(_FullPageWater old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      final from = _fillAnim.value;
      _fillAnim = Tween<double>(begin: from, end: widget.progress).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeInOutCubic),
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
      builder: (_, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: _FullPageWaterPainter(
            progress: _fillAnim.value,
            wavePhase: _waveController.value * 2 * pi,
          ),
        );
      },
    );
  }
}

class _FullPageWaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  _FullPageWaterPainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient (above water)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFE0F2FE),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    if (progress > 0) {
      final waterHeight = size.height * progress;
      final waterTop = size.height - waterHeight;

      // Create wave path
      final wavePath = Path();
      wavePath.moveTo(0, size.height);
      wavePath.lineTo(0, waterTop);

      // Multiple waves for more natural look
      for (double x = 0; x <= size.width; x += 3) {
        final normalizedX = x / size.width;
        final wave1 = sin((normalizedX * 2 * pi) + wavePhase) * 15;
        final wave2 = sin((normalizedX * 4 * pi) - wavePhase * 1.3) * 8;
        final wave3 = sin((normalizedX * 6 * pi) + wavePhase * 0.7) * 4;
        final y = waterTop + wave1 + wave2 + wave3;
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width, size.height);
      wavePath.close();

      // Water gradient
      final waterRect = Rect.fromLTWH(0, waterTop - 50, size.width, waterHeight + 50);
      canvas.drawPath(
        wavePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF38BDF8).withOpacity(0.8),
              const Color(0xFF0EA5E9),
              const Color(0xFF0284C7),
              const Color(0xFF0369A1),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ).createShader(waterRect),
      );

      // Add flowing shimmer effect
      final shimmerPath = Path();
      shimmerPath.moveTo(0, waterTop);
      for (double x = 0; x <= size.width; x += 3) {
        final normalizedX = x / size.width;
        final wave1 = sin((normalizedX * 2 * pi) + wavePhase) * 15;
        final wave2 = sin((normalizedX * 4 * pi) - wavePhase * 1.3) * 8;
        final wave3 = sin((normalizedX * 6 * pi) + wavePhase * 0.7) * 4;
        final y = waterTop + wave1 + wave2 + wave3;
        shimmerPath.lineTo(x, y);
      }
      shimmerPath.lineTo(size.width, waterTop - 30);
      shimmerPath.lineTo(0, waterTop - 30);
      shimmerPath.close();

      canvas.drawPath(
        shimmerPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.0),
            ],
          ).createShader(Rect.fromLTWH(0, waterTop - 30, size.width, 30)),
      );

      // Bubbles
      _drawBubbles(canvas, size, waterTop, waterHeight);
    }
  }

  void _drawBubbles(Canvas canvas, Size size, double waterTop, double waterHeight) {
    if (progress < 0.05) return;

    final random = Random(42); // Fixed seed for consistent positions
    final bubbles = List.generate(20, (i) {
      return (
        x: random.nextDouble(),
        y: random.nextDouble(),
        r: 2.0 + random.nextDouble() * 4,
        speed: random.nextDouble(),
      );
    });

    for (final bubble in bubbles) {
      final bx = size.width * bubble.x;
      final by = waterTop + (waterHeight * bubble.y);
      
      // Animated movement
      final offset = sin(wavePhase * (1 + bubble.speed) + bubble.x * 10) * 8;
      
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
              Colors.white.withOpacity(0.6),
              Colors.white.withOpacity(0.2),
            ],
          ).createShader(bubbleRect),
      );

      // Bubble highlight
      canvas.drawCircle(
        Offset(bx - bubble.r * 0.3, by + offset - bubble.r * 0.3),
        bubble.r * 0.35,
        Paint()..color = Colors.white.withOpacity(0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_FullPageWaterPainter old) =>
      progress != old.progress || wavePhase != old.wavePhase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Water stats display
// ─────────────────────────────────────────────────────────────────────────────

class _WaterStats extends StatelessWidget {
  final WaterProvider water;
  const _WaterStats({required this.water});

  @override
  Widget build(BuildContext context) {
    final isAboveWater = water.progress < 0.5;
    final textColor = isAboveWater ? const Color(0xFF1E293B) : Colors.white;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${water.currentIntake}',
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1,
            shadows: isAboveWater ? null : [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ml',
          style: TextStyle(
            fontSize: 28,
            color: textColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isAboveWater 
                ? const Color(0xFF0EA5E9).withOpacity(0.1)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isAboveWater
                  ? const Color(0xFF0EA5E9).withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(water.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 20,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of ${water.dailyGoal} ml',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ]                     fontWeight: FontWeight.w600,
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

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  _CircleProgressPainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill,
    );

    // Water fill with wave effect
    if (progress > 0) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

      final waterHeight = size.height * progress;
      final waterY = size.height - waterHeight;

      // Create wave path
      final wavePath = Path();
      wavePath.moveTo(0, size.height);
      wavePath.lineTo(0, waterY);

      for (double x = 0; x <= size.width; x += 2) {
        final normalizedX = x / size.width;
        final wave1 = sin((normalizedX * 3 * pi) + wavePhase) * 8;
        final wave2 = sin((normalizedX * 5 * pi) - wavePhase * 1.3) * 4;
        final y = waterY + wave1 + wave2;
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width, size.height);
      wavePath.close();

      // Draw water with gradient
      final waterRect = Rect.fromLTWH(0, waterY - 20, size.width, waterHeight + 20);
      canvas.drawPath(
        wavePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF38BDF8).withOpacity(0.7),
              const Color(0xFF0EA5E9),
              const Color(0xFF0284C7),
            ],
          ).createShader(waterRect),
      );

      // Add shimmer effect
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.2),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(waterRect);

      canvas.drawPath(wavePath, shimmerPaint);

      canvas.restore();
    }

    // Progress ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Background ring
    canvas.drawCircle(
      center,
      radius - 4,
      ringPaint..color = const Color(0xFFE2E8F0),
    );

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + (2 * pi * progress),
          colors: const [
            Color(0xFF06B6D4),
            Color(0xFF0EA5E9),
            Color(0xFF3B82F6),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      progress != old.progress || wavePhase != old.wavePhase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Add',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuickAddButton(
                label: '250ml',
                subtitle: 'Cup',
                onTap: () => water.addWater(250),
              ),
              const SizedBox(width: 12),
              _QuickAddButton(
                label: '500ml',
                subtitle: 'Bottle',
                onTap: () => water.addWater(500),
              ),
              const SizedBox(width: 12),
              _QuickAddButton(
                label: 'Custom',
                subtitle: 'Amount',
                onTap: () => _showCustomDialog(context),
                isCustom: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Water'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (ml)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                context.read<WaterProvider>().addWater(amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isCustom;

  const _QuickAddButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCustom
                    ? [
                        const Color(0xFF06B6D4),
                        const Color(0xFF0EA5E9),
                      ]
                    : [
                        const Color(0xFFF8FAFC),
                        const Color(0xFFF1F5F9),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCustom
                    ? Colors.transparent
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCustom ? const Color(0xFF0EA5E9) : Colors.black)
                      .withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCustom ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCustom
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

