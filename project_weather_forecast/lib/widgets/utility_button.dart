import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/database_provider.dart';
import '../screens/saved_cities_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/notification_settings_screen.dart';

class UtilityButton extends StatefulWidget {
  const UtilityButton({Key? key}) : super(key: key);

  @override
  State<UtilityButton> createState() => _UtilityButtonState();
}

class _UtilityButtonState extends State<UtilityButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Main utility button - compact size
            GestureDetector(
              onTap: () {
                print('Main button tapped, current state: $_isExpanded');
                _toggleMenu();
              },
              behavior: HitTestBehavior.opaque,
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
                  child: RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(Icons.apps, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),

            // Dropdown menu items
            if (_isExpanded) ...[
              const SizedBox(height: 8),

              // Calendar button - NEW
              _buildMenuItem(
                icon: Icons.calendar_today,
                onTap: () async {
                  print('Calendar button executing...');

                  // Kiểm tra đăng nhập
                  final dbProvider = context.read<DatabaseProvider>();
                  if (dbProvider.currentUser == null) {
                    // Chưa đăng nhập, hiển thị thông báo
                    _toggleMenu();
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Color(0xFF2C3E50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Icon(Icons.lock_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Yêu cầu đăng nhập',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          content: Text(
                            'Cần đăng nhập / đăng ký để sử dụng lịch và sự kiện',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Hủy',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );

                                // Reload data if login successful
                                if (result == true && context.mounted) {
                                  provider.loadSavedCities();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF2C3E50),
                              ),
                              child: Text('Đăng nhập'),
                            ),
                          ],
                        ),
                      );
                    }
                    return;
                  }

                  // Đã đăng nhập, mở CalendarScreen
                  _toggleMenu();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                },
              ),

              // Profile button
              _buildMenuItem(
                icon: Icons.person_outline,
                onTap: () async {
                  print('Profile button executing...');

                  // Kiểm tra đăng nhập
                  final dbProvider = context.read<DatabaseProvider>();
                  if (dbProvider.currentUser == null) {
                    // Chưa đăng nhập, hiển thị thông báo
                    _toggleMenu();
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Color(0xFF2C3E50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Icon(Icons.lock_outline, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Yêu cầu đăng nhập',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          content: Text(
                            'Cần đăng nhập / đăng ký để xem thông tin cá nhân',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Hủy',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );

                                // Reload data if login successful
                                if (result == true && context.mounted) {
                                  provider.loadSavedCities();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF2C3E50),
                              ),
                              child: Text('Đăng nhập'),
                            ),
                          ],
                        ),
                      );
                    }
                    return;
                  }

                  // Đã đăng nhập, mở ProfileScreen
                  _toggleMenu();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),

              // Save/Unsave button
              if (provider.currentWeather != null)
                _buildMenuItem(
                  icon: provider.isCurrentCitySaved
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  onTap: () async {
                    print('Save button executing...');

                    // Kiểm tra đăng nhập
                    final dbProvider = context.read<DatabaseProvider>();
                    if (dbProvider.currentUser == null) {
                      // Chưa đăng nhập, hiển thị thông báo
                      _toggleMenu();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Color(0xFF2C3E50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                Icon(Icons.lock_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Yêu cầu đăng nhập',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            content: Text(
                              'Cần đăng nhập / đăng ký để sử dụng tính năng này',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Hủy',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );

                                  // Reload data if login successful
                                  if (result == true && context.mounted) {
                                    provider.loadSavedCities();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF2C3E50),
                                ),
                                child: Text('Đăng nhập'),
                              ),
                            ],
                          ),
                        );
                      }
                      return;
                    }

                    // Đã đăng nhập, toggle save
                    await provider.toggleSaveCurrentCity();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.isCurrentCitySaved
                                ? 'Đã lưu thành phố'
                                : 'Đã bỏ lưu thành phố',
                          ),
                          duration: Duration(seconds: 2),
                          backgroundColor: provider.isCurrentCitySaved
                              ? Colors.green
                              : Colors.orange,
                        ),
                      );
                    }
                    _toggleMenu();
                  },
                ),

              // Saved cities button
              _buildMenuItem(
                icon: Icons.list,
                onTap: () {
                  print('List button executing...');
                  _toggleMenu();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedCitiesScreen(),
                    ),
                  );
                },
              ),

              // Refresh button
              _buildMenuItem(
                icon: Icons.refresh,
                onTap: () async {
                  print('Refresh button executing...');
                  _toggleMenu();
                  await provider.initializeWithLocation();
                },
              ),

              // Settings button
              _buildMenuItem(
                icon: Icons.settings,
                onTap: () {
                  print('Settings button executing...');
                  _toggleMenu();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({required IconData icon, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          print('MenuItem InkWell tapped: $icon'); // Debug
          onTap();
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
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
          child: Center(child: Icon(icon, color: Colors.white, size: 20)),
        ),
      ),
    );
  }
}
