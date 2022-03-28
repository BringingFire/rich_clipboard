import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rich_clipboard/rich_clipboard.dart';
import 'package:rich_clipboard_example/pages/flutter_clipboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> _availableTypes = ['loading...'];
  String _html = 'NO HTML';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    List<String> availableTypes = [];
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      availableTypes = await RichClipboard.getAvailableTypes();
    } on PlatformException {
      availableTypes = ['Failed to get clipboard available types.'];
    }

    String html;
    try {
      html = (await RichClipboard.asHtml()) ?? 'NO HTML FOUND';
    } on PlatformException {
      html = 'Failed to get html';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _availableTypes = availableTypes;
      _html = html;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      // home: Scaffold(
      //   appBar: AppBar(
      //     title: const Text('Plugin example app'),
      //   ),
      //   // body: SingleChildScrollView(
      //   //   child: Column(
      //   //     mainAxisAlignment: MainAxisAlignment.center,
      //   //     crossAxisAlignment: CrossAxisAlignment.center,
      //   //     children: [
      //   //       Text(
      //   //         'Available types:\n$_availableTypes\n',
      //   //         textAlign: TextAlign.center,
      //   //       ),
      //   //       Text(
      //   //         'Clipboard HTML:\n$_html\n',
      //   //         textAlign: TextAlign.center,
      //   //       ),
      //   //       ElevatedButton(
      //   //         onPressed: initPlatformState,
      //   //         child: const Text('Refresh'),
      //   //       ),
      //   //     ],
      //   //   ),
      //   // ),
      // ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final WidgetBuilder builder;

  _MenuItem({required this.icon, required this.title, required this.builder});
}

final _menu = <_MenuItem>[
  _MenuItem(
    icon: Icons.paste,
    title: 'Flutter clipboard',
    builder: (context) => const FlutterClipboardPage(),
  ),
  _MenuItem(
    icon: Icons.paste,
    title: 'Flutter clipboard',
    builder: (context) => const FlutterClipboardPage(),
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIXME'),
      ),
      drawer: _drawer,
      body: _menu[_activeIndex].builder(context),
    );
  }

  Widget get _drawer => Drawer(
        child: ListView(
          children: List.generate(
            _menu.length,
            (index) {
              final item = _menu[index];
              return ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                onTap: () => setState(() {
                  _activeIndex = index;
                }),
                selected: index == _activeIndex,
                selectedTileColor: Colors.grey.shade300,
              );
            },
          ),
        ),
      );
}
