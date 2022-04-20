import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

const _kGapSize = 12.0;

class FlutterClipboardPage extends StatefulWidget {
  const FlutterClipboardPage({Key? key}) : super(key: key);

  @override
  State<FlutterClipboardPage> createState() => _FlutterClipboardPageState();
}

class _FlutterClipboardPageState extends State<FlutterClipboardPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Clipboard data',
                style: theme.textTheme.titleLarge,
              ),
              const Gap(_kGapSize),
              TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 12,
                readOnly: true,
                style: theme.textTheme.bodyText2!
                    .copyWith(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(_kGapSize),
              ElevatedButton(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  _controller.text = data?.text ?? '';
                },
                child: const Text('Paste'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
