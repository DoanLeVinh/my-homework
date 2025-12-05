import 'package:flutter/material.dart';

class ImageDetailScreen extends StatelessWidget {
  static const routeName = '/image-detail';
  const ImageDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Detail')),
      body: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFbae6fd), Color(0xFF60a5fa)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.image, size: 120, color: Colors.white),
        ),
      ),
    );
  }
}
