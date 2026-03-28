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
              // Full page water animation
              _FullPageWater(progress: water.progress),
              
              // Content overlay
              SafeArea(
                child: Column(
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
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                            color: Colors.white,
                            iconSize: 28,
                          ),
                        ],
                      ),
                    ),

                    // Center stats
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${water.currentIntake}',
                              style: const TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'ml',
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${(water.progress * 100).toInt()}% of ${water.dailyGoal} ml goal',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quick actions
                    _QuickActionsRow(water: water),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full page water animation
// ─────────────────────────────────────────────────────────────────────────────

class _FullPageWater extends StatefulWidget {
  final double progress;
  const _FullPageWater({required this.progress});

  @override
  State<_FullPageWater> createState() => _FullPageWaterState();
}

class _FullPageWaterState extends State<_FullPageWater>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fillAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );
    _fillController.forward();
  }

  @override
  void didUpdateWidget(_FullPageWater old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      final from = _fillAnim.value;
      _fillAnim = Tween<double>(begin: from, end: widget.progress).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
      );
      _fillController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _fillController]),
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
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
    // Background gradient (sky to darker)
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0F2FE),
            const Color(0xFFBAE6FD),
            const Color(0xFF7DD3FC),
          ],
        ).createShader(bgRect),
    );

    // Water level calculation
    final waterHeight = size.height * progress;
    final waterY = size.height - waterHeight;

    if (progress > 0) {
      // Create wave path
      final wavePath = Path();
      wavePath.moveTo(0, size.height);
      wavePath.lineTo(0, waterY);

      // Main wave with multiple frequencies for natural look
      for (double x = 0; x <= size.width; x += 3) {
        final normalizedX = x / size.width;
        
        // Combine multiple sine waves for complexity
        final wave1 = sin((normalizedX * 2 * pi) + wavePhase) * 15;
        final wave2 = sin((normalizedX * 3 * pi) - wavePhase * 0.7) * 8;
        final wave3 = sin((normalizedX * 5 * pi) + wavePhase * 1.3) * 5;
        
        final y = waterY + wave1 + wave2 + wave3;
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width, size.height);
      wavePath.close();

      // Draw main water body with gradient
      final waterRect = Rect.fromLTWH(0, waterY - 50, size.width, waterHeight + 50);
      canvas.drawPath(
        wavePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF38BDF8),
              const Color(0xFF0EA5E9),
              const Color(0xFF0284C7),
              const Color(0xFF0369A1),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ).createShader(waterRect),
      );

      // Add shine/light effect on water surface
      final shinePath = Path();
      shinePath.moveTo(0, waterY);
      
      for (double x = 0; x <= size.width; x += 3) {
        final normalizedX = x / size.width;
        final wave1 = sin((normalizedX * 2 * pi) + wavePhase) * 15;
        final wave2 = sin((normalizedX * 3 * pi) - wavePhase * 0.7) * 8;
        final wave3 = sin((normalizedX * 5 * pi) + wavePhase * 1.3) * 5;
        final y = waterY + wave1 + wave2 + wave3;
        shinePath.lineTo(x, y);
      }
      
      shinePath.lineTo(size.width, waterY + 80);
      shinePath.lineTo(0, waterY + 80);
      shinePath.close();

      canvas.drawPath(
        shinePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, waterY, size.width, 80)),
      );

      // Add bubbles
      _drawBubbles(canvas, size, waterY, waterHeight);
    }
  }

  void _drawBubbles(Canvas canvas, Size size, double waterY, double waterHeight) {
    if (progress < 0.05) return;

    final bubbles = [
      (x: 0.15, y: 0.2, r: 6.0, speed: 1.0),
      (x: 0.35, y: 0.5, r: 4.0, speed: 1.3),
      (x: 0.55, y: 0.3, r: 5.0, speed: 0.8),
      (x: 0.72, y: 0.65, r: 4.5, speed: 1.1),
      (x: 0.88, y: 0.4, r: 3.5, speed: 1.4),
      (x: 0.25, y: 0.75, r: 3.0, speed: 0.9),
      (x: 0.65, y: 0.85, r: 5.5, speed: 1.2),
      (x: 0.45, y: 0.15, r: 4.0, speed: 1.0),
    ];

    for (final bubble in bubbles) {
      final bx = size.width * bubble.x;
      final by = waterY + (waterHeight * bubble.y);
      
      // Animated bubble movement
      final offset = sin(wavePhase * bubble.speed + bubble.x * 15) * 8;
      
      // Bubble glow
      canvas.drawCircle(
        Offset(bx, by + offset),
        bubble.r + 2,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Bubble body with gradient
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
              Colors.white.withOpacity(0.1),
            ],
          ).createShader(bubbleRect),
      );

      // Bubble highlight
      canvas.drawCircle(
        Offset(bx - bubble.r * 0.35, by + offset - bubble.r * 0.35),
        bubble.r * 0.4,
        Paint()..color = Colors.white.withOpacity(0.9),
      );

      // Bubble outline
      canvas.drawCircle(
        Offset(bx, by + offset),
        bubble.r,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_FullPageWaterPainter old) =>
      progress != old.progress || wavePhase != old.wavePhase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
  final WaterProvider water;
  const _QuickActionsRow({required this.water});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _QuickAddButton(
            label: '250ml',
            onTap: () => water.addWater(250),
          ),
          const SizedBox(width: 12),
          _QuickAddButton(
            label: '500ml',
            onTap: () => water.addWater(500),
          ),
          const SizedBox(width: 12),
          _QuickAddButton(
            label: 'Custom',
            onTap: () => _showCustomDialog(context),
            isCustom: true,
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
  final VoidCallback onTap;
  final bool isCustom;

  const _QuickAddButton({
    required this.label,
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
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isCustom
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCustom ? const Color(0xFF0284C7) : Colors.white,
              )
    );
  }
}

