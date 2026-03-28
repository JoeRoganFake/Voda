import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class WaterBackground extends StatefulWidget {
  final double progress;
  const WaterBackground({super.key, required this.progress});

  @override
  State<WaterBackground> createState() => _WaterBackgroundState();
}

class _WaterBackgroundState extends State<WaterBackground>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _waveController;
  late Animation<double> _progressAnim;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _accelerometerX = 0;
  double _accelerometerY = 0;

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

    _accelerometerSubscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Use a fraction of the accelerometer data to create a subtle tilt
          _accelerometerX = event.y * 0.05; // Swapped x and y for natural feel
          _accelerometerY = event.x * 0.05;
        });
      }
    });
  }

  @override
  void didUpdateWidget(WaterBackground old) {
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
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _waveController]),
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _WaterPainter(
            progress: _progressAnim.value,
            wavePhase: _waveController.value * 2 * pi,
            accelerometerX: _accelerometerX,
            accelerometerY: _accelerometerY,
          ),
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double accelerometerX;
  final double accelerometerY;

  _WaterPainter({
    required this.progress,
    required this.wavePhase,
    required this.accelerometerX,
    required this.accelerometerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Apply a rotation based on accelerometer data for the sloshing effect
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-accelerometerX); // Apply the tilt
    canvas.translate(-center.dx, -center.dy);

    // Water fill with wave effect
    if (progress > 0) {
      final waterHeight = size.height * progress;
      // Adjust waterY based on the tilt to keep it feeling natural
      final waterY = size.height - waterHeight + (accelerometerY * 200);

      // Create wave path
      final wavePath = Path();
      wavePath.moveTo(0, size.height);
      wavePath.lineTo(0, waterY);

      for (double x = 0; x <= size.width; x += 4) {
        final normalizedX = x / size.width;
        final wave1 = sin((normalizedX * 2 * pi) + wavePhase) * 10;
        final wave2 = cos((normalizedX * 3 * pi) - wavePhase * 1.3) * 8;
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
              const Color(0xFF1E3A8A), // Darker blue
              const Color(0xFF1C44B3), // Medium blue
              const Color(0xFF1E63DB), // Lighter blue
            ],
          ).createShader(waterRect),
      );

      // Add shimmer effect
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(waterRect);

      canvas.drawPath(wavePath, shimmerPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterPainter old) =>
      progress != old.progress ||
      wavePhase != old.wavePhase ||
      accelerometerX != old.accelerometerX ||
      accelerometerY != old.accelerometerY;
}
