import 'package:flutter/material.dart';
import 'dart:math' as math;

// Rain Drop Widget
class RainDrop extends StatelessWidget {
  final double size;
  final double opacity;
  final double delay;

  const RainDrop({
    super.key,
    required this.size,
    required this.opacity,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(opacity * 0.5),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}

// Animated Rain Effect
class AnimatedRain extends StatefulWidget {
  final int intensity; // 1-10

  const AnimatedRain({super.key, this.intensity = 5});

  @override
  State<AnimatedRain> createState() => _AnimatedRainState();
}

class _AnimatedRainState extends State<AnimatedRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<RainDropData> _drops = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Generate rain drops
    _generateDrops();
  }

  void _generateDrops() {
    final count = widget.intensity * 15; // More drops for higher intensity
    for (int i = 0; i < count; i++) {
      _drops.add(
        RainDropData(
          x: _random.nextDouble(),
          delay: _random.nextDouble(),
          speed: 0.5 + _random.nextDouble() * 0.5,
          size: 1.5 + _random.nextDouble() * 1.5,
          opacity: 0.4 + _random.nextDouble() * 0.4,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _drops.map((drop) {
            final progress = (_controller.value + drop.delay) % 1.0;
            final y = progress * drop.speed;

            return Positioned(
              left: drop.x * MediaQuery.of(context).size.width,
              top: y * MediaQuery.of(context).size.height,
              child: RainDrop(
                size: drop.size,
                opacity: drop.opacity * (1 - progress),
                delay: drop.delay,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class RainDropData {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final double opacity;

  RainDropData({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

// Animated Cloud
class AnimatedCloud extends StatefulWidget {
  final double size;
  final double speed;
  final double yPosition;
  final Color color;

  const AnimatedCloud({
    super.key,
    this.size = 100,
    this.speed = 30,
    this.yPosition = 0.2,
    this.color = Colors.white,
  });

  @override
  State<AnimatedCloud> createState() => _AnimatedCloudState();
}

class _AnimatedCloudState extends State<AnimatedCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.speed.toInt()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final x = (_controller.value * screenWidth * 1.5) - widget.size;

        return Positioned(
          left: x % (screenWidth + widget.size * 2) - widget.size,
          top: widget.yPosition * MediaQuery.of(context).size.height,
          child: _buildCloud(),
        );
      },
    );
  }

  Widget _buildCloud() {
    return Opacity(
      opacity: 0.7,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 0.6,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: _cloudCircle(widget.size * 0.4),
            ),
            Positioned(
              left: widget.size * 0.25,
              bottom: widget.size * 0.1,
              child: _cloudCircle(widget.size * 0.5),
            ),
            Positioned(
              left: widget.size * 0.5,
              bottom: 0,
              child: _cloudCircle(widget.size * 0.45),
            ),
            Positioned(
              right: 0,
              bottom: widget.size * 0.05,
              child: _cloudCircle(widget.size * 0.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cloudCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// Multiple Clouds Layer
class CloudsLayer extends StatelessWidget {
  final int density; // 1-5
  final Color color;

  const CloudsLayer({super.key, this.density = 3, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(density, (index) {
        return AnimatedCloud(
          size: 80 + (index * 20).toDouble(),
          speed: 25 + (index * 10).toDouble(),
          yPosition: 0.15 + (index * 0.15),
          color: color.withOpacity(0.6 - (index * 0.1)),
        );
      }),
    );
  }
}

// Lightning Effect
class LightningEffect extends StatefulWidget {
  const LightningEffect({super.key});

  @override
  State<LightningEffect> createState() => _LightningEffectState();
}

class _LightningEffectState extends State<LightningEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showLightning = false;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _triggerLightning();
  }

  void _triggerLightning() {
    Future.delayed(Duration(seconds: 3 + _random.nextInt(5)), () {
      if (mounted) {
        setState(() => _showLightning = true);
        _controller.forward(from: 0).then((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() => _showLightning = false);
              _triggerLightning();
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_showLightning) return const SizedBox.shrink();

        return Container(
          color: Colors.white.withOpacity(0.6 * (1 - _controller.value)),
          child: CustomPaint(
            painter: LightningPainter(progress: _controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class LightningPainter extends CustomPainter {
  final double progress;

  LightningPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.5) return;

    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final startX = size.width * 0.5;
    path.moveTo(startX, 0);
    path.lineTo(startX - 20, size.height * 0.2);
    path.lineTo(startX + 10, size.height * 0.2);
    path.lineTo(startX - 15, size.height * 0.4);
    path.lineTo(startX + 5, size.height * 0.4);
    path.lineTo(startX - 25, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LightningPainter oldDelegate) => true;
}

// Animated Sun Rays
class AnimatedSunRays extends StatefulWidget {
  const AnimatedSunRays({super.key});

  @override
  State<AnimatedSunRays> createState() => _AnimatedSunRaysState();
}

class _AnimatedSunRaysState extends State<AnimatedSunRays>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            painter: SunRaysPainter(),
            size: const Size(200, 200),
          ),
        );
      },
    );
  }
}

class SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.withOpacity(0.0),
          Colors.yellow.withOpacity(0.3),
          Colors.orange.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + math.cos(angle) * size.width * 0.5,
        center.dy + math.sin(angle) * size.height * 0.5,
      );
      canvas.drawPath(path, paint..strokeWidth = 20);
    }
  }

  @override
  bool shouldRepaint(SunRaysPainter oldDelegate) => false;
}

// Snow Effect
class AnimatedSnow extends StatefulWidget {
  final int intensity;

  const AnimatedSnow({super.key, this.intensity = 5});

  @override
  State<AnimatedSnow> createState() => _AnimatedSnowState();
}

class _AnimatedSnowState extends State<AnimatedSnow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SnowflakeData> _flakes = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _generateSnowflakes();
  }

  void _generateSnowflakes() {
    final count = widget.intensity * 20;
    for (int i = 0; i < count; i++) {
      _flakes.add(
        SnowflakeData(
          x: _random.nextDouble(),
          delay: _random.nextDouble(),
          speed: 0.3 + _random.nextDouble() * 0.4,
          size: 2 + _random.nextDouble() * 4,
          swing: _random.nextDouble() * 0.1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _flakes.map((flake) {
            final progress = (_controller.value + flake.delay) % 1.0;
            final y = progress * flake.speed;
            final swing = math.sin(progress * math.pi * 4) * flake.swing;

            return Positioned(
              left: (flake.x + swing) * MediaQuery.of(context).size.width,
              top: y * MediaQuery.of(context).size.height,
              child: Container(
                width: flake.size,
                height: flake.size,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class SnowflakeData {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final double swing;

  SnowflakeData({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.swing,
  });
}

// ⭐ Animated Stars for Night Sky
class AnimatedStars extends StatefulWidget {
  final double opacity;

  const AnimatedStars({super.key, this.opacity = 1.0});

  @override
  State<AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<AnimatedStars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<StarData> _stars = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Generate random stars
    for (int i = 0; i < 50; i++) {
      _stars.add(
        StarData(
          x: _random.nextDouble(),
          y: _random.nextDouble() * 0.6, // Top 60% of screen
          size: _random.nextDouble() * 2 + 1,
          twinkleSpeed: _random.nextDouble() * 2 + 1,
          delay: _random.nextDouble(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: StarsPainter(
            stars: _stars,
            animation: _controller.value,
            opacity: widget.opacity,
          ),
          child: Container(),
        );
      },
    );
  }
}

class StarData {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double delay;

  StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.delay,
  });
}

class StarsPainter extends CustomPainter {
  final List<StarData> stars;
  final double animation;
  final double opacity;

  StarsPainter({
    required this.stars,
    required this.animation,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var star in stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;

      // Twinkle effect using sine wave
      final twinkle =
          (math.sin(
                (animation + star.delay) * math.pi * 2 * star.twinkleSpeed,
              ) +
              1) /
          2;

      paint.color = Colors.white.withOpacity(twinkle * 0.8 * opacity);

      // Draw star as circle
      canvas.drawCircle(Offset(x, y), star.size, paint);

      // Add star glow
      paint.color = Colors.white.withOpacity(twinkle * 0.3 * opacity);
      canvas.drawCircle(Offset(x, y), star.size * 2, paint);
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => true;
}
