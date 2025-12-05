import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import 'home_screen.dart';
import 'permission_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Initialize database (không cần user email lúc đầu)
      await dbProvider.initialize();

      // Check for existing session token (auto-login)
      final hasValidSession = await authProvider.checkSession();

      if (hasValidSession) {
        debugPrint('Valid session found - auto-login successful');
        // User đã đăng nhập trước đó và session còn hiệu lực
      } else {
        debugPrint('No valid session - user needs to login');
      }

      // Check if we need to ask for location permission
      final hasAsked = await LocationService.hasAskedPermission();

      if (!hasAsked) {
        // First time - show permission screen
        await Future.delayed(const Duration(milliseconds: 2000));

        if (mounted) {
          final permissionGranted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const PermissionScreen(),
              fullscreenDialog: true,
            ),
          );

          if (permissionGranted == true) {
            // Permission granted - fetch weather with location
            await weatherProvider.initializeWithLocation();
          } else {
            // Permission denied - use default location (Ho Chi Minh)
            await weatherProvider.fetchWeatherByCoords(10.8231, 106.6297);
          }
        }
      } else {
        // Not first time - check saved permission
        final savedPermission = await LocationService.getSavedPermission();

        if (savedPermission == 'never') {
          // User chose never - use default location
          await weatherProvider.fetchWeatherByCoords(10.8231, 106.6297);
        } else {
          // Try to get location
          final position = await LocationService.getCurrentLocation();

          if (position != null) {
            await weatherProvider.fetchWeatherByCoords(
              position.latitude,
              position.longitude,
            );
          } else {
            // Fallback to default
            await weatherProvider.fetchWeatherByCoords(10.8231, 106.6297);
          }
        }
      }

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');

      // Vẫn navigate tới home screen ngay cả khi có lỗi
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
              Color(0xFF3A6CC3),
              Color(0xFF4A7FED),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Weather icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wb_sunny,
                      size: 70,
                      color: Colors.yellow.shade300,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App title
                  Text(
                    'Dự báo Thời tiết',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Weather Forecast',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Đang tải dữ liệu...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
