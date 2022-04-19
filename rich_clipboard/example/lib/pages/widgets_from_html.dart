import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

class WidgetsFromHtmlPage extends StatefulWidget {
  const WidgetsFromHtmlPage({Key? key}) : super(key: key);

  @override
  State<WidgetsFromHtmlPage> createState() => _WidgetsFromHtmlPageState();
}

class _WidgetsFromHtmlPageState extends State<WidgetsFromHtmlPage> {
  String _html = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: HtmlWidget(
                _html,
                isSelectable: true,
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                final data = await RichClipboard.getData();
                setState(() {
                  _html = data.html ?? '';
                });
              },
              child: const Text('Paste'),
            ),
          ),
        ],
      ),
    );
  }
}
