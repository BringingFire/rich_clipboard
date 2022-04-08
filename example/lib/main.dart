import 'package:flutter/material.dart';
import 'package:rich_clipboard_example/pages/flutter_clipboard.dart';
import 'package:rich_clipboard_example/pages/rich_clipboard.dart';
import 'package:rich_clipboard_example/pages/super_editor.dart';
import 'package:rich_clipboard_example/pages/widgets_from_html.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });
}

final _menu = <_MenuItem>[
  _MenuItem(
    icon: Icons.attach_money,
    title: 'Rich clipboard',
    subtitle: 'Inspect and modify clipboard contents',
    builder: (context) => const RichClipboardPage(),
  ),
  _MenuItem(
    icon: Icons.edit,
    title: 'Super Editor',
    subtitle: 'A rich text editor, extended with rich clipboard support',
    builder: (context) => const SuperEditorPage(),
  ),
  _MenuItem(
    icon: Icons.build,
    title: 'Widgets from html',
    subtitle: 'Paste html from the clipboard as widgets',
    builder: (context) => const WidgetsFromHtmlPage(),
  ),
  _MenuItem(
    icon: Icons.paste,
    title: 'Flutter clipboard',
    subtitle: 'Builtin clipboard behavior for comparison',
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
        title: Text(_menu[_activeIndex].title),
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
                subtitle: Text(item.subtitle),
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
