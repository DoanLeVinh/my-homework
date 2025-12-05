import 'package:flutter/material.dart';

class TextDetailScreen extends StatelessWidget {
  static const routeName = '/text-detail';
  const TextDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Detail')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: DefaultTextStyle.of(
                context,
              ).style.copyWith(fontSize: 24, height: 1.6),
              children: const [
                TextSpan(text: 'The '),
                TextSpan(
                  text: 'quick',
                  style: TextStyle(decoration: TextDecoration.lineThrough),
                ),
                TextSpan(text: ' '),
                TextSpan(
                  text: 'Brown',
                  style: TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: '\nfox '),
                WidgetSpan(child: SizedBox(width: 6)),
                TextSpan(text: 'j'),
                WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(text: 'u'),
                WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(text: 'm'),
                WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(text: 'p'),
                WidgetSpan(child: SizedBox(width: 4)),
                TextSpan(text: 's '),
                TextSpan(
                  text: 'over',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: '\n'),
                TextSpan(text: 'the '),
                TextSpan(
                  text: 'lazy',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: ' dog.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
