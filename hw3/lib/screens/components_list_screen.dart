import 'package:flutter/material.dart';
import 'text_detail_screen.dart';
import 'image_detail_screen.dart';
import 'input_detail_screen.dart';
import 'column_demo_screen.dart';
import 'row_demo_screen.dart';

class ComponentsListScreen extends StatelessWidget {
  static const routeName = '/components';
  const ComponentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <String, List<_Item>>{
      'Display': [
        _Item(
          'Text',
          'Displays text',
          Icons.text_fields,
          TextDetailScreen.routeName,
        ),
        _Item(
          'Image',
          'Displays an image',
          Icons.image_outlined,
          ImageDetailScreen.routeName,
        ),
      ],
      'Input': [
        _Item(
          'TextField',
          'Input field for text',
          Icons.edit_outlined,
          TextFieldScreen.routeName,
        ),
        _Item(
          'PasswordField',
          'Input field for passwords',
          Icons.lock_outline,
          PasswordFieldScreen.routeName,
        ),
      ],
      'Layout': [
        _Item(
          'Column',
          'Arranges elements vertically',
          Icons.view_agenda_outlined,
          ColumnDemoScreen.routeName,
        ),
        _Item(
          'Row',
          'Arranges elements horizontally',
          Icons.view_week_outlined,
          RowDemoScreen.routeName,
        ),
      ],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('UI Components List')),
      backgroundColor: const Color(0xFFE6F4FF),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sections.entries
            .map((e) => _Section(title: e.key, items: e.value))
            .toList(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
        ...items.map((i) => _CardItem(item: i)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CardItem extends StatelessWidget {
  const _CardItem({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pushNamed(item.route),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(item.icon, color: const Color(0xFF2BB3F3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const _Item(this.title, this.subtitle, this.icon, this.route);
}
