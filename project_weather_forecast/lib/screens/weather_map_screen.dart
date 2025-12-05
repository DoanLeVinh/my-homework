import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/weather_provider.dart';
import '../widgets/glass_card.dart';

// Legend item class
class LegendItem {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});
}

class WeatherMapScreen extends StatefulWidget {
  const WeatherMapScreen({Key? key}) : super(key: key);

  @override
  State<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(10.8231, 106.6297); // Default: Ho Chi Minh
  String _selectedLayer = 'temp_new';
  double _layerOpacity = 0.7;
  bool _isLoadingLocation = true;

  // Animation controller for layer transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, String> _layerNames = {
    'temp_new': 'Nhiệt độ',
    'precipitation_new': 'Lượng mưa',
    'clouds_new': 'Mây',
    'wind_new': 'Gió',
    'pressure_new': 'Áp suất',
  };

  final Map<String, IconData> _layerIcons = {
    'temp_new': Icons.thermostat,
    'precipitation_new': Icons.water_drop,
    'clouds_new': Icons.cloud,
    'wind_new': Icons.air,
    'pressure_new': Icons.compress,
  };

  final Map<String, List<LegendItem>> _legends = {
    'temp_new': [
      LegendItem(color: Color(0xFF9400D3), label: '< -40°C'), // Dark violet
      LegendItem(color: Color(0xFF0000FF), label: '-20°C'), // Blue
      LegendItem(color: Color(0xFF00FFFF), label: '0°C'), // Cyan
      LegendItem(color: Color(0xFF00FF00), label: '20°C'), // Green
      LegendItem(color: Color(0xFFFFD700), label: '30°C'), // Gold
      LegendItem(color: Color(0xFFFF0000), label: '> 40°C'), // Red
    ],
    'precipitation_new': [
      LegendItem(color: Color(0xFFF0F0F0), label: 'Không mưa'), // Light gray
      LegendItem(color: Color(0xFF87CEEB), label: 'Mưa nhẹ'), // Sky blue
      LegendItem(color: Color(0xFF1E90FF), label: 'Mưa vừa'), // Dodger blue
      LegendItem(color: Color(0xFF0000CD), label: 'Mưa to'), // Medium blue
      LegendItem(color: Color(0xFF8B00FF), label: 'Mưa rất to'), // Violet
    ],
    'clouds_new': [
      LegendItem(color: Color(0xFFFFFFFF), label: '0% mây'), // White
      LegendItem(color: Color(0xFFD3D3D3), label: '25%'), // Light gray
      LegendItem(color: Color(0xFFA9A9A9), label: '50%'), // Dark gray
      LegendItem(color: Color(0xFF696969), label: '75%'), // Dim gray
      LegendItem(
        color: Color(0xFF2F4F4F),
        label: '100% mây',
      ), // Dark slate gray
    ],
    'wind_new': [
      LegendItem(color: Color(0xFF98FB98), label: '0-5 m/s'), // Pale green
      LegendItem(color: Color(0xFF32CD32), label: '5-10 m/s'), // Lime green
      LegendItem(color: Color(0xFFFFD700), label: '10-15 m/s'), // Gold
      LegendItem(color: Color(0xFFFF8C00), label: '15-20 m/s'), // Dark orange
      LegendItem(color: Color(0xFFDC143C), label: '> 20 m/s'), // Crimson
    ],
    'pressure_new': [
      LegendItem(color: Color(0xFF0000FF), label: '< 980 hPa'), // Blue
      LegendItem(color: Color(0xFF00CED1), label: '990 hPa'), // Dark turquoise
      LegendItem(color: Color(0xFF32CD32), label: '1000 hPa'), // Lime green
      LegendItem(color: Color(0xFFFFD700), label: '1010 hPa'), // Gold
      LegendItem(color: Color(0xFFFF4500), label: '> 1020 hPa'), // Orange red
    ],
  };

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Set location from current weather after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeLocation() {
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );

    // Nếu có currentWeather, dùng tọa độ của nó
    if (weatherProvider.currentWeather != null) {
      setState(() {
        _currentLocation = LatLng(
          weatherProvider.currentWeather!.lat,
          weatherProvider.currentWeather!.lon,
        );
        _isLoadingLocation = false;
      });
      // Di chuyển map đến vị trí thành phố đang xem
      _mapController.move(_currentLocation, 10.0);
    } else {
      // Nếu chưa có weather data, thử lấy GPS location
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentLocation, 9.0);
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Consumer<WeatherProvider>(
            builder: (context, provider, child) {
              final tileUrl = provider.getTileLayerUrl(_selectedLayer);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation,
                  initialZoom: 9.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                ),
                children: [
                  // Base map layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.weather_forecast',
                  ),

                  // Weather layer with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TileLayer(
                      urlTemplate: tileUrl,
                      userAgentPackageName: 'com.example.weather_forecast',
                      backgroundColor: Colors.transparent,
                      tileBuilder: (context, widget, tile) {
                        return Opacity(opacity: _layerOpacity, child: widget);
                      },
                    ),
                  ),

                  // Current location marker
                  MarkerLayer(
                    markers: [
                      // User's current location
                      Marker(
                        point: _currentLocation,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud,
                                    size: 20,
                                    color: Color(0xFF4A90E2),
                                  ),
                                  const SizedBox(width: 4),
                                  if (provider.currentWeather != null)
                                    Text(
                                      '${provider.currentWeather!.temp.round()}°',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A90E2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Hoàng Sa (Paracel Islands) - Vietnamese label
                      Marker(
                        point: LatLng(16.5, 112.0),
                        width: 120,
                        height: 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF0000).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '🇻🇳 HOÀNG SA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Trường Sa (Spratly Islands) - Vietnamese label
                      Marker(
                        point: LatLng(10.0, 114.0),
                        width: 120,
                        height: 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF0000).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '🇻🇳 TRƯỜNG SA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Top controls - Compact header with close button and layer tabs
          SafeArea(
            child: Column(
              children: [
                // Header with close button and horizontal layer tabs
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Close button - smaller
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            color: Color(0xFF4A90E2),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Layer tabs - horizontal scrollable
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _layerNames.keys.map((layer) {
                                final isSelected = _selectedLayer == layer;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_selectedLayer != layer) {
                                        // Animate layer transition
                                        _animationController.reverse().then((
                                          _,
                                        ) {
                                          setState(() {
                                            _selectedLayer = layer;
                                          });
                                          _animationController.forward();
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _layerIcons[layer],
                                            size: 18,
                                            color: isSelected
                                                ? Color(0xFF4A90E2)
                                                : Colors.white,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _layerNames[layer]!,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Color(0xFF4A90E2)
                                                  : Colors.white,
                                              fontSize: 10,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Opacity control - minimal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.opacity, color: Colors.white70, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withOpacity(0.2),
                              trackHeight: 2,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: _layerOpacity,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _layerOpacity = value;
                                });
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${(_layerOpacity * 100).round()}%',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Left side legend
          if (_legends[_selectedLayer] != null)
            Positioned(
              left: 16,
              top: 140,
              bottom: 120,
              child: GlassCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _layerNames[_selectedLayer]!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._legends[_selectedLayer]!.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.white30,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          // Bottom controls - smaller buttons
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom in
                GestureDetector(
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_currentLocation, zoom + 1);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.add, color: Color(0xFF4A90E2), size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                // Zoom out
                GestureDetector(
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_currentLocation, zoom - 1);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.remove,
                      color: Color(0xFF4A90E2),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // My location
                GestureDetector(
                  onTap: () {
                    _mapController.move(_currentLocation, 9.0);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: Color(0xFF4A90E2),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoadingLocation)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang lấy vị trí...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
