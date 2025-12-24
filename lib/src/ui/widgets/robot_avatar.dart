import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RobotAvatar extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const RobotAvatar({
    super.key,
    this.size = 140,
    this.onTap,
  });

  @override
  State<RobotAvatar> createState() => _RobotAvatarState();
}

class _RobotAvatarState extends State<RobotAvatar>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation - slow and calming
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // Rotation animation for outer ring
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Pulse animation for glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _showChatDialog,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _breatheAnimation,
            _rotateController,
            _pulseAnimation,
          ]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: widget.size * _breatheAnimation.value,
                  height: widget.size * _breatheAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGreen
                            .withOpacity(_pulseAnimation.value * 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

                // Rotating outer ring
                Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size * 0.9, widget.size * 0.9),
                    painter: OrbitRingPainter(
                      color: AppTheme.accentGreen.withOpacity(0.4),
                      dotCount: 8,
                    ),
                  ),
                ),

                // Counter-rotating inner ring
                Transform.rotate(
                  angle: -_rotateController.value * 2 * math.pi * 0.5,
                  child: CustomPaint(
                    size: Size(widget.size * 0.7, widget.size * 0.7),
                    painter: OrbitRingPainter(
                      color: AppTheme.accentBlue.withOpacity(0.3),
                      dotCount: 6,
                      dotRadius: 3,
                    ),
                  ),
                ),

                // Main orb with gradient
                Transform.scale(
                  scale: _breatheAnimation.value,
                  child: Container(
                    width: widget.size * 0.55,
                    height: widget.size * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentGreen.withOpacity(0.9),
                          AppTheme.accentGreen.withOpacity(0.6),
                          AppTheme.softGrey,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.self_improvement,
                        size: widget.size * 0.25,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.accentGreen.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.self_improvement, color: AppTheme.accentGreen),
            const SizedBox(width: 12),
            const Text('Zen Mode', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Take a deep breath. Complete tasks to earn more screen time and improve your digital wellbeing.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'I understand',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class OrbitRingPainter extends CustomPainter {
  final Color color;
  final int dotCount;
  final double dotRadius;

  OrbitRingPainter({
    required this.color,
    this.dotCount = 8,
    this.dotRadius = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, ringPaint);

    // Draw dots on ring
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi / dotCount) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
