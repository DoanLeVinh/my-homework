import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/search_bar_widget.dart' as custom;
import '../widgets/weather_display.dart';
import '../widgets/forecast_display.dart';
import '../widgets/utility_button.dart';
import '../widgets/weather_background.dart';
//import '../widgets/weather_debug_menu.dart'; // Uncomment để bật Debug Menu
import 'weather_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Debug mode để test weather animations
  //String? _debugWeather; // Uncomment khi dùng Debug Menu

  @override
  void initState() {
    super.initState();
    // Initialize with current location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WeatherProvider>();
      provider.initializeWithLocation();
      provider.loadSavedCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          // Get weather condition for background
          // Sử dụng debug weather nếu đang test, nếu không thì dùng weather thực
          final weatherCondition =
              // _debugWeather ?? // Uncomment khi dùng Debug Menu
              provider.currentWeather?.weatherMain ?? 'Clear';

          // Get current time at location (với timezone)
          final currentTime = provider.currentWeather?.currentTime;

          // Check if it's night based on sunrise/sunset
          final isNight = provider.currentWeather?.isNightTime ?? false;

          return WeatherBackground(
            weatherCondition: weatherCondition,
            currentTime: currentTime,
            isNight: isNight,
            child: SafeArea(
              child: Stack(
                children: [
                  // Main content
                  if (provider.isLoading)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Đang tải dữ liệu thời tiết...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else if (provider.error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Đã xảy ra lỗi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.error!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                provider.initializeWithLocation();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF4A90E2),
                              ),
                              child: Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (provider.currentWeather != null)
                    RefreshIndicator(
                      onRefresh: () => provider.initializeWithLocation(),
                      color: Color(0xFF4A90E2),
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 80), // Space for search bar
                            // Current weather
                            WeatherDisplay(weather: provider.currentWeather!),
                            const SizedBox(height: 24),

                            // Forecast
                            if (provider.forecast != null)
                              ForecastDisplay(
                                forecast: provider.forecast!,
                                currentWeather: provider.currentWeather,
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                  // Search bar, map button and utility button overlay (always on top)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map button (left) - compact
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WeatherMapScreen(),
                              ),
                            );
                          },
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.map_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Search bar (center - expanded)
                        Expanded(child: custom.SearchBar()),
                        const SizedBox(width: 8),
                        // Utility button (right) - compact
                        UtilityButton(),
                      ],
                    ),
                  ),

                  // ============================================
                  // DEBUG MENU - Uncomment để test weather effects
                  // ============================================
                  // WeatherDebugMenu(
                  //   currentWeather: weatherCondition,
                  //   onWeatherChanged: (weather) {
                  //     setState(() {
                  //       _debugWeather = weather;
                  //     });
                  //   },
                  // ),
                  // ============================================
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
