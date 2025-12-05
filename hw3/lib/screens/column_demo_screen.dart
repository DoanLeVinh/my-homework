import 'package:flutter/material.dart';

class ColumnDemoScreen extends StatelessWidget {
  static const routeName = '/column-demo';
  const ColumnDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Column Demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_chip('A'), _gap(), _chip('B'), _gap(), _chip('C')],
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 12);
  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFe0f2fe),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
