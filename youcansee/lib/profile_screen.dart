import 'package:flutter/material.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Vị trí của avatar
  double _avatarLeft = 100;
  double _avatarTop = 200;
  final double _avatarSize = 120;

  // Thông tin có thể chỉnh sửa
  String _userName = 'Johan Smith';
  String _location = 'Ho Chi Minh City, Vietnam';
  String _email = 'vinhdl1636@ut.edu.vn';
  String _phone = '+84 123 456 789';
  String _occupation = 'Software Developer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Nội dung cố định
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Khoảng trống cho avatar
                const SizedBox(height: 120),
                
                const SizedBox(height: 30),
                
                // Tên người dùng
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Địa chỉ
                Text(
                  _location,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Thông tin bổ sung
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email, _email),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.phone, _phone),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.work, _occupation),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Avatar có thể kéo thả
          Positioned(
            left: _avatarLeft,
            top: _avatarTop,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _avatarLeft += details.delta.dx;
                  _avatarTop += details.delta.dy;
                  
                  // Giới hạn không cho avatar ra ngoài màn hình
                  final screenSize = MediaQuery.of(context).size;
                  _avatarLeft = max(0, min(_avatarLeft, screenSize.width - _avatarSize - 40));
                  _avatarTop = max(0, min(_avatarTop, screenSize.height - _avatarSize - 100));
                });
              },
              child: Container(
                width: _avatarSize + 40,
                height: _avatarSize + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE3F2FD), // Màu xanh nhạt
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          // Hiển thị icon mặc định nếu không tìm thấy ảnh
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper để tạo các dòng thông tin
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Dialog để chỉnh sửa thông tin profile
  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    final TextEditingController locationController = TextEditingController(text: _location);
    final TextEditingController emailController = TextEditingController(text: _email);
    final TextEditingController phoneController = TextEditingController(text: _phone);
    final TextEditingController occupationController = TextEditingController(text: _occupation);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: occupationController,
                  decoration: const InputDecoration(
                    labelText: 'Nghề nghiệp',
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _userName = nameController.text;
                  _location = locationController.text;
                  _email = emailController.text;
                  _phone = phoneController.text;
                  _occupation = occupationController.text;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thông tin đã được cập nhật!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}