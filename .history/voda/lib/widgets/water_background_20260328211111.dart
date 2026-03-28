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
  // Raw target tilt from sensor — updated without setState
  double _targetTilt = 0.0;
  // Smoothed tilt used for painting — lerped toward _targetTilt each frame
  double _currentTilt = 0.0;

  // Max tilt in radians (~14°) — limits sensitivity
  static const double _maxTilt = 0.25;
  // How quickly the water catches up: 0 = never, 1 = instant
  static const double _lerpSpeed = 0.06;

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
        accelerometerEvents.listen((AccelerometerEvent event) {
      // Just store the target — no setState, no rebuild triggered here
      final raw = atan2(event.x, event.y);
      _targetTilt = raw.clamp(-_maxTilt, _maxTilt);
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
        // Lerp the tilt each frame — smooth and glitch-free
        _currentTilt += (_targetTilt - _currentTilt) * _lerpSpeed;
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _WaterPainter(
            progress: _progressAnim.value,
            wavePhase: _waveController.value * 2 * pi,
            tiltAngle: _currentTilt,
          ),
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double tiltAngle;

  _WaterPainter({
    required this.progress,
    required this.wavePhase,
    required this.tiltAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Water fill with wave effect
    if (progress > 0) {
      final waterHeight = size.height * progress;
      final waterY = size.height - waterHeight;

      canvas.save();

      // Rotate the canvas to simulate tilt
      final center = Offset(size.width / 2, waterY);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(tiltAngle);
      canvas.translate(-center.dx, -center.dy);

      // Create wave path
      final wavePath = Path();
      wavePath.moveTo(-size.width, size.height);
      wavePath.lineTo(-size.width, waterY);

      for (double x = -size.width; x <= size.width * 2; x += 4) {
        final normalizedX = x / size.width;
        final wave1 = sin((normalizedX * 2 * pi) + wavePhase) * 10;
        final wave2 = cos((normalizedX * 3 * pi) - wavePhase * 1.3) * 8;
        final y = waterY + wave1 + wave2;
        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(size.width * 2, size.height);
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

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WaterPainter old) =>
      progress != old.progress ||
      wavePhase != old.wavePhase ||
      tiltAngle != old.tiltAngle;
}
