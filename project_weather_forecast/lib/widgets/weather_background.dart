import 'package:flutter/material.dart';
import 'weather_animations.dart';

class WeatherBackground extends StatelessWidget {
  final String weatherCondition; // main weather from API
  final Widget child;
  final DateTime? currentTime; // Thời gian hiện tại tại vị trí đó
  final bool? isNight; // Có phải đêm không (từ sunrise/sunset)

  const WeatherBackground({
    super.key,
    required this.weatherCondition,
    required this.child,
    this.currentTime,
    this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final isNightTime = isNight ?? false; // Default là ngày nếu không có data
    final weatherType = _getWeatherType(weatherCondition.toLowerCase());

    return Stack(
      children: [
        // Animated Background Gradient
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getBackgroundColors(weatherType, isNightTime),
            ),
          ),
        ),

        // Weather Effects Layer
        ..._getWeatherEffects(weatherType, isNightTime),

        // Content
        child,
      ],
    );
  }

  WeatherType _getWeatherType(String condition) {
    if (condition.contains('rain') || condition.contains('drizzle')) {
      return WeatherType.rainy;
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return WeatherType.thunderstorm;
    } else if (condition.contains('snow')) {
      return WeatherType.snowy;
    } else if (condition.contains('cloud')) {
      return WeatherType.cloudy;
    } else if (condition.contains('clear') || condition.contains('sunny')) {
      return WeatherType.sunny;
    } else if (condition.contains('mist') ||
        condition.contains('fog') ||
        condition.contains('haze')) {
      return WeatherType.foggy;
    }
    return WeatherType.clear;
  }

  List<Color> _getBackgroundColors(WeatherType type, bool isNight) {
    // Chế độ ban đêm
    if (isNight) {
      switch (type) {
        case WeatherType.sunny: // Clear night
        case WeatherType.clear:
          return [
            const Color(0xFF0F2027), // Deep night blue
            const Color(0xFF203A43), // Dark blue
            const Color(0xFF2C5364), // Blue-gray
          ];

        case WeatherType.rainy:
          return [
            const Color(0xFF1a1a2e), // Very dark navy
            const Color(0xFF16213e), // Dark navy blue
            const Color(0xFF0f3460), // Deep blue
          ];

        case WeatherType.thunderstorm:
          return [
            const Color(0xFF0a0a0a), // Almost black
            const Color(0xFF1a1a2e), // Very dark blue
            const Color(0xFF16213e), // Dark navy
          ];

        case WeatherType.snowy:
          return [
            const Color(0xFF2C3E50), // Dark blue-gray
            const Color(0xFF34495E), // Blue-gray
            const Color(0xFF546E7A), // Light blue-gray
          ];

        case WeatherType.cloudy:
          return [
            const Color(0xFF232526), // Dark gray
            const Color(0xFF414345), // Medium gray
            const Color(0xFF4B5563), // Light gray
          ];

        case WeatherType.foggy:
          return [
            const Color(0xFF2C3E50), // Dark blue
            const Color(0xFF3A506B), // Blue-gray
            const Color(0xFF5A6A7F), // Misty blue
          ];
      }
    }

    // Chế độ ban ngày (giữ nguyên như cũ)
    switch (type) {
      case WeatherType.sunny:
        return [
          const Color(0xFF4A90E2), // Light blue
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFFFDB813), // Golden yellow
        ];

      case WeatherType.rainy:
        return [
          const Color(0xFF2C3E50), // Dark blue-gray
          const Color(0xFF34495E), // Blue-gray
          const Color(0xFF4A5F7F), // Light blue-gray
        ];

      case WeatherType.thunderstorm:
        return [
          const Color(0xFF1a1a2e), // Very dark blue
          const Color(0xFF16213e), // Dark navy
          const Color(0xFF0f3460), // Deep blue
        ];

      case WeatherType.snowy:
        return [
          const Color(0xFFB0C4DE), // Light steel blue
          const Color(0xFFD3E4F4), // Pale blue
          const Color(0xFFE8F4F8), // Very light blue
        ];

      case WeatherType.cloudy:
        return [
          const Color(0xFF5B9BD5), // Sky blue
          const Color(0xFF87CEEB), // Light sky blue
          const Color(0xFFB4D7F1), // Pale blue
        ];

      case WeatherType.foggy:
        return [
          const Color(0xFF6BA3D0), // Soft blue
          const Color(0xFF91C4E8), // Light misty blue
          const Color(0xFFB8D9F0), // Very pale blue
        ];

      case WeatherType.clear:
        return [
          const Color(0xFF2C3E50),
          const Color(0xFF3A4D62),
          const Color(0xFF4A5F7F),
        ];
    }
  }

  List<Widget> _getWeatherEffects(WeatherType type, bool isNight) {
    // Hiệu ứng ban đêm
    if (isNight) {
      switch (type) {
        case WeatherType.sunny: // Clear night
        case WeatherType.clear:
          return [
            // Moon (di chuyển xuống và sang trái để tránh search bar)
            Positioned(
              top: 120, // Từ 60 -> 120 (xuống dưới searchbar)
              left: 40, // Từ right: 50 -> left: 40 (sang trái)
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Stars
            AnimatedStars(),
          ];

        case WeatherType.rainy:
          return [
            CloudsLayer(density: 4, color: const Color(0xFF1a1a2e)),
            AnimatedRain(intensity: 7),
            // Dim moon behind clouds (di chuyển xuống)
            Positioned(
              top: 130,
              left: 50,
              child: Opacity(
                opacity: 0.2,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ];

        case WeatherType.thunderstorm:
          return [
            CloudsLayer(density: 5, color: const Color(0xFF0a0a0a)),
            AnimatedRain(intensity: 10),
            LightningEffect(),
          ];

        case WeatherType.snowy:
          return [
            CloudsLayer(density: 4, color: const Color(0xFF34495E)),
            AnimatedSnow(intensity: 6),
            // Pale moon (di chuyển)
            Positioned(
              top: 140,
              left: 45,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ];

        case WeatherType.cloudy:
          return [
            // Moon peeking through clouds (di chuyển)
            Positioned(
              top: 135,
              left: 50,
              child: Opacity(
                opacity: 0.4,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CloudsLayer(density: 5, color: const Color(0xFF414345)),
            AnimatedStars(opacity: 0.3),
          ];

        case WeatherType.foggy:
          return [
            CloudsLayer(density: 6, color: const Color(0xFF3A506B)),
            Positioned.fill(
              child: Container(color: const Color(0xFF2C3E50).withOpacity(0.3)),
            ),
            // Very dim moon (di chuyển)
            Positioned(
              top: 145,
              left: 55,
              child: Opacity(
                opacity: 0.15,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
      }
    }

    // Hiệu ứng ban ngày (giữ nguyên như cũ)
    switch (type) {
      case WeatherType.sunny:
        return [
          // Sun rays
          Positioned(top: 50, right: 30, child: AnimatedSunRays()),
          // Sun circle
          Positioned(
            top: 80,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Light clouds
          CloudsLayer(density: 2, color: Colors.white.withOpacity(0.3)),
        ];

      case WeatherType.rainy:
        return [
          CloudsLayer(density: 4, color: const Color(0xFF5A6B7F)),
          AnimatedRain(intensity: 7),
        ];

      case WeatherType.thunderstorm:
        return [
          CloudsLayer(density: 5, color: const Color(0xFF2C3E50)),
          AnimatedRain(intensity: 10),
          LightningEffect(),
        ];

      case WeatherType.snowy:
        return [
          CloudsLayer(density: 4, color: const Color(0xFFB0C4DE)),
          AnimatedSnow(intensity: 6),
        ];

      case WeatherType.cloudy:
        return [
          // Soft sun rays through clouds
          Positioned(
            top: 60,
            right: 40,
            child: Opacity(opacity: 0.4, child: AnimatedSunRays()),
          ),
          // Subtle sun glow
          Positioned(
            top: 90,
            right: 70,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.shade200.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 15,
                  ),
                ],
              ),
            ),
          ),
          CloudsLayer(density: 5, color: Colors.grey.shade300),
        ];

      case WeatherType.foggy:
        return [
          // Very soft sun glow through fog
          Positioned(
            top: 70,
            right: 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.yellow.shade100.withOpacity(0.3),
                    Colors.yellow.shade50.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CloudsLayer(density: 6, color: Colors.grey.shade400),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),
        ];

      case WeatherType.clear:
        return [CloudsLayer(density: 2, color: Colors.white.withOpacity(0.2))];
    }
  }
}

enum WeatherType { sunny, rainy, thunderstorm, snowy, cloudy, foggy, clear }
