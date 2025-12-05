import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.location_on, size: 80, color: Colors.white),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Cho phép truy cập vị trí',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Ứng dụng cần quyền truy cập vị trí để cung cấp dự báo thời tiết chính xác cho khu vực của bạn',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                if (_isLoading)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  Column(
                    children: [
                      // Luôn luôn
                      _buildPermissionButton(
                        icon: Icons.check_circle,
                        title: 'Luôn luôn cho phép',
                        description: 'Truy cập vị trí mọi lúc (khuyến nghị)',
                        color: Colors.green,
                        onTap: () => _handlePermission(
                          ph.Permission.locationAlways,
                          'always',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Chỉ khi dùng app
                      _buildPermissionButton(
                        icon: Icons.mobile_friendly,
                        title: 'Chỉ khi sử dụng app',
                        description: 'Truy cập vị trí khi app đang mở',
                        color: Colors.blue,
                        onTap: () => _handlePermission(
                          ph.Permission.locationWhenInUse,
                          'when_in_use',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Chỉ lần này
                      _buildPermissionButton(
                        icon: Icons.timer,
                        title: 'Chỉ lần này',
                        description: 'Hỏi lại vào lần sau',
                        color: Colors.orange,
                        onTap: () => _handlePermission(
                          ph.Permission.locationWhenInUse,
                          'once',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Không cho phép
                      TextButton(
                        onPressed: () => _handlePermission(null, 'never'),
                        child: Text(
                          'Không cho phép',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePermission(
    ph.Permission? permission,
    String choice,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      if (choice == 'never') {
        // Người dùng không cho phép
        await prefs.setString('location_permission', 'never');
        await prefs.setBool('location_permission_asked', true);

        if (mounted) {
          Navigator.of(context).pop(false); // Return false = no permission
        }
        return;
      }

      if (choice == 'once') {
        // Chỉ lần này - không lưu preference
        await prefs.setBool('location_permission_asked', false);
      } else {
        // Luôn luôn hoặc khi dùng app - lưu preference
        await prefs.setString('location_permission', choice);
        await prefs.setBool('location_permission_asked', true);
      }

      // Request permission
      if (permission != null) {
        final status = await permission.request();

        if (status.isGranted) {
          if (mounted) {
            Navigator.of(context).pop(true); // Return true = permission granted
          }
        } else if (status.isDenied) {
          _showPermissionDeniedDialog();
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog();
        }
      }
    } catch (e) {
      debugPrint('Error handling permission: $e');
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quyền bị từ chối'),
        content: Text(
          'Bạn đã từ chối quyền truy cập vị trí. App sẽ sử dụng vị trí mặc định (TP.HCM)',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mở cài đặt'),
        content: Text(
          'Quyền truy cập vị trí bị vô hiệu hóa vĩnh viễn. Vui lòng mở Cài đặt để bật quyền.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await ph.openAppSettings();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop(false);
              }
            },
            child: Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }
}
