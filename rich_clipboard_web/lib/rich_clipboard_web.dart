import 'dart:html';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart';

const _kMimeTextPlain = 'text/plain';
const _kMimeTextHtml = 'text/html';

bool _detectClipboardApi() {
  final clipboard = window.navigator.clipboard;
  if (clipboard == null) {
    return false;
  }
  for (final methodName in ['read', 'write']) {
    final method = getProperty(clipboard, methodName);
    if (method == null) {
      return false;
    }
  }

  return true;
}

/// The web implementation of [RichClipboard].
class RichClipboardWeb extends RichClipboardPlatform {
  /// Registers the implementation.
  static void registerWith(Registrar registrar) {
    if (!_detectClipboardApi()) {
      return;
    }
    RichClipboardPlatform.instance = RichClipboardWeb();
  }

  @override
  Future<List<String>> getAvailableTypes() async {
    final clipboard = window.navigator.clipboard as _Clipboard?;
    if (clipboard == null) {
      return [];
    }

    final data = await clipboard.read();
    if (data.isEmpty) {
      return [];
    }
    return data.first.types;
  }

  @override
  Future<RichClipboardData> getData() async {
    final clipboard = window.navigator.clipboard as _Clipboard?;
    if (clipboard == null) {
      return const RichClipboardData();
    }

    final contents = await clipboard.read();
    if (contents.isEmpty) {
      return const RichClipboardData();
    }

    final item = contents.first;
    final availableTypes = item.types;

    String? text;
    String? html;
    if (availableTypes.contains(_kMimeTextPlain)) {
      final textBlob = await item.getType('text/plain');
      text = await textBlob.text();
    }
    if (availableTypes.contains(_kMimeTextHtml)) {
      final htmlBlob = await item.getType('text/html');
      html = await htmlBlob.text();
    }

    return RichClipboardData(
      text: text,
      html: html,
    );
  }

  @override
  Future<void> setData(RichClipboardData data) async {
    final clipboard = window.navigator.clipboard as _Clipboard?;
    if (clipboard == null) {
      return;
    }

    final dataMap = Map.fromEntries(
      data.toMap().entries.where((entry) => entry.value != null).map(
            (entry) => MapEntry(
              entry.key,
              // Wrapping the string in a list here satisfies the Blob
              // constructor and works just fine. If something in Dart or the
              // web APIs change to require a list of individual characters in
              // the future, use the .characters getter from the characters
              // package to safely split the string into unicode grapheme
              // clusters.
              Blob([entry.value!], entry.key),
            ),
          ),
    );

    final items = <_ClipboardItem>[
      if (dataMap.isNotEmpty) _ClipboardItem(jsify(dataMap))
    ];
    await clipboard.write(items);
  }
}

@JS('Blob')
@staticInterop
extension _BlobText on Blob {
  @JS('text')
  external dynamic _text();
  Future<String> text() => promiseToFuture<String>(_text());
}

@JS('ClipboardItem')
@staticInterop
class _ClipboardItem {
  external factory _ClipboardItem(dynamic args);
}

extension _ClipboardItemImpl on _ClipboardItem {
  @JS('getType')
  external dynamic _getType(String mimeType);
  Future<Blob> getType(String mimeType) =>
      promiseToFuture<Blob>(_getType(mimeType));

  @JS('types')
  external List<dynamic> get _types;
  List<String> get types => _types.cast<String>();
}

@JS('Clipboard')
@staticInterop
class _Clipboard {}

extension _ClipboardImpl on _Clipboard {
  @JS('read')
  external dynamic _read();
  Future<List<_ClipboardItem>> read() => promiseToFuture<List<dynamic>>(_read())
      .then((list) => list.cast<_ClipboardItem>());

  @JS('write')
  external dynamic _write(List<_ClipboardItem> items);
  Future<void> write(List<_ClipboardItem> items) =>
      promiseToFuture(_write(items));
}
