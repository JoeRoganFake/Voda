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
              // Full screen water background
              _FullScreenWater(progress: water.progress),
              
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
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            ),
                            color: water.progress > 0.5
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),

                    // Stats in center
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${water.currentIntake}',
                              style: TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.bold,
                                color: water.progress > 0.5
                                    ? Colors.white
                                    : const Color(0xFF0EA5E9),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ml',
                              style: TextStyle(
                                fontSize: 28,
                                color: water.progress > 0.5
                                    ? Colors.white.withOpacity(0.9)
                                    : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: water.progress > 0.5
                                    ? Colors.white.withOpacity(0.2)
                                    : const Color(0xFF0EA5E9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: water.progress > 0.5
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '${(water.progress * 100).toInt()}% of ${water.dailyGoal} ml',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: water.progress > 0.5
                                      ? Colors.white
                                      : const Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quick actions
                    _QuickActionsRow(isDark: water.progress > 0.15),
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
// Full screen water fill
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenWater extends StatefulWidget {
  final double progress;
  const _FullScreenWater({required this.progress});

  @override
  State<_FullScreenWater> createState() => _FullScreenWaterState();
}

class _FullScreenWaterState extends State<_FullScreenWater>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _waveController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _progressAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();
  }

  @override
  void didUpdateWidget(_FullScreenWater old) {
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
        return CustomPaint(
          size: Size.infinite,
          painter: _FullScreenWaterPainter(
            progress: _progressAnim.value,
            wavePhase: _waveController.value * 2 * pi,
          ),
        );
      },
    );
  }
}

class _FullScreenWaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  _FullScreenWaterPainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    // Background (when water doesn't fill screen)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF8FAFC),
    );

    if (progress > 0) {
      final waterHeight = size.height * progress;
      final waterY = size.height - waterHeight;

      // Create wave path
      final wavePath = Path();
      wavePath.moveTo(0, size.height);
      wavePath.lineTo(0, waterY);

      // Draw waves with multiple frequencies for natural look
      for (double x = 0; x <= size.width; x += 2) {
        final normalizedX = x / size.width;
        
        // Multiple wave frequencies combined
        final wave1 = sin((normalizedX * 2 * pi) + wavePhase) * 12;
        final wave2 = sin((normalizedX * 4 * pi) - wavePhase * 0.7) * 6;
        final wave3 = sin((normalizedX * 6 * pi) + wavePhase * 1.3) * 3;
        
        final y = waterY + wave1 + wave2 + wave3;
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width, size.height);
      wavePath.close();

      // Main water gradient
      final waterRect = Rect.fromLTWH(0, waterY - 30, size.width, waterHeight + 30);
      canvas.drawPath(
        wavePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF7DD3FC),
              const Color(0xFF38BDF8),
              const Color(0xFF0EA5E9),
              const Color(0xFF0284C7),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ).createShader(waterRect),
      );

      // Shimmer overlay
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.15),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ).createShader(waterRect);

      canvas.drawPath(wavePath, shimmerPaint);

      // Bubble effects
      _drawBubbles(canvas, size, waterY, waterHeight);
    }
  }

  void _drawBubbles(Canvas canvas, Size size, double waterY, double waterHeight) {
    if (progress < 0.05) return;

    final bubbles = [
      (x: 0.15, y: 0.25, r: 5.0, speed: 1.0),
      (x: 0.35, y: 0.65, r: 4.0, speed: 1.3),
      (x: 0.55, y: 0.40, r: 6.0, speed: 0.9),
      (x: 0.75, y: 0.80, r: 3.5, speed: 1.1),
      (x: 0.85, y: 0.30, r: 4.5, speed: 1.2),
      (x: 0.25, y: 0.70, r: 3.0, speed: 1.4),
      (x: 0.65, y: 0.55, r: 5.5, speed: 0.8),
      (x: 0.45, y: 0.85, r: 4.0, speed: 1.0),
    ];

    for (final bubble in bubbles) {
      final bx = size.width * bubble.x;
      final by = waterY + (waterHeight * bubble.y);
      
      // Animated floating movement
      final floatOffset = sin(wavePhase * bubble.speed + bubble.x * 15) * 8;
      final horizontalDrift = cos(wavePhase * bubble.speed * 0.5 + bubble.x * 10) * 4;
      
      // Bubble with gradient for depth
      final bubbleRect = Rect.fromCircle(
        center: Offset(bx + horizontalDrift, by + floatOffset),
        radius: bubble.r,
      );
      
      canvas.drawCircle(
        Offset(bx + horizontalDrift, by + floatOffset),
        bubble.r,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.topLeft,
            colors: [
              Colors.white.withOpacity(0.6),
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ).createShader(bubbleRect),
      );

      // Highlight spot
      canvas.drawCircle(
        Offset(bx - bubble.r * 0.3 + horizontalDrift, by + floatOffset - bubble.r * 0.3),
        bubble.r * 0.35,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_FullScreenWaterPainter old) =>
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

