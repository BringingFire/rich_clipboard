import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

class RichClipboardPage extends StatefulWidget {
  static String kTextPlain = 'text/plain';
  static String kTextHtml = 'text/html';

  const RichClipboardPage({Key? key}) : super(key: key);

  @override
  State<RichClipboardPage> createState() => _RichClipboardPageState();
}

class _RichClipboardPageState extends State<RichClipboardPage> {
  late final TextEditingController _availableController;
  late final TextEditingController _textContentsController;
  late final TextEditingController _htmlContentsController;
  int _availableCount = 0;

  @override
  void initState() {
    super.initState();
    _availableController = TextEditingController();
    _textContentsController = TextEditingController();
    _htmlContentsController = TextEditingController();
  }

  @override
  void dispose() {
    _availableController.dispose();
    _textContentsController.dispose();
    _htmlContentsController.dispose();
    super.dispose();
  }

  Future<void> _refreshTypes() async {
    final types = await RichClipboard.getAvailableTypes();
    setState(() {
      _availableController.text = types.toString();
      _availableCount = types.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text('Clipboard available types ($_availableCount total)'),
                  IconButton(
                    onPressed: _refreshTypes,
                    iconSize: 16,
                    splashRadius: 12,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                  )
                ],
              ),
              TextField(
                controller: _availableController,
                minLines: 1,
                maxLines: null,
                readOnly: true,
                style: theme.textTheme.bodyText2!.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const Text('text/html'),
              TextField(
                controller: _htmlContentsController,
                minLines: 1,
                maxLines: null,
                style: theme.textTheme.bodyText2!.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const Text('text/plain'),
              TextField(
                controller: _textContentsController,
                minLines: 1,
                maxLines: null,
                style: theme.textTheme.bodyText2!.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.red),
                    onPressed: () async {
                      final plainText = _textContentsController.text;
                      final htmlText = _htmlContentsController.text;
                      final data = RichClipboardData(
                        plainText: plainText.isEmpty ? null : plainText,
                        htmlText: htmlText.isEmpty ? null : htmlText,
                      );
                      await RichClipboard.setData(data);
                      await _refreshTypes();
                    },
                    child: const Text('Copy'),
                  ),
                  const Gap(40),
                  ElevatedButton(
                    onPressed: () async {
                      await _refreshTypes();
                      final data = await RichClipboard.getData();
                      _htmlContentsController.text = data.htmlText ?? 'NONE';
                      _textContentsController.text = data.plainText ?? 'NONE';
                    },
                    child: const Text('Paste'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
