import 'package:flutter/material.dart';

class RowDemoScreen extends StatelessWidget {
  static const routeName = '/row-demo';
  const RowDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Row Demo')),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chip('1'),
            const SizedBox(width: 12),
            _chip('2'),
            const SizedBox(width: 12),
            _chip('3'),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFe0f2fe),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
