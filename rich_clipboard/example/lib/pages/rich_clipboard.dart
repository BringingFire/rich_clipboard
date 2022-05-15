import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

const kTextPlain = 'text/plain';
const kTextHtml = 'text/html';

class RichClipboardPage extends StatefulWidget {
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
    final monoStyle = theme.textTheme.bodyText2!.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Consolas', 'Roboto Mono'],
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                            'Clipboard available types ($_availableCount total)'),
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
                      style: monoStyle,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const Gap(10),
                    const Text(kTextHtml),
                    const Gap(5),
                    TextField(
                      controller: _htmlContentsController,
                      minLines: 1,
                      maxLines: null,
                      style: monoStyle,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const Gap(10),
                    const Text(kTextPlain),
                    const Gap(5),
                    TextField(
                      controller: _textContentsController,
                      minLines: 1,
                      maxLines: null,
                      style: monoStyle,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
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
                    text: plainText.isEmpty ? null : plainText,
                    html: htmlText.isEmpty ? null : htmlText,
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
                  _htmlContentsController.text = data.html ?? '';
                  _textContentsController.text = data.text ?? '';
                },
                child: const Text('Paste'),
              ),
            ],
          ),
          const Gap(20),
        ],
      ),
    );
  }
}
