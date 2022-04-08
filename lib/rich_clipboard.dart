import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _kMimeTextPlain = 'text/plain';
const _kMimeTextHtml = 'text/html';

final platformSupported = !kIsWeb && Platform.isMacOS;

class RichClipboardData implements ClipboardData {
  RichClipboardData({this.text, this.html});
  RichClipboardData.fromMap(Map<String, String?> map)
      : this(
          text: map[_kMimeTextPlain],
          html: map[_kMimeTextHtml],
        );

  @override
  final String? text;
  final String? html;

  Map<String, String?> toMap() => {
        _kMimeTextPlain: text,
        _kMimeTextHtml: html,
      };
  @override
  String toString() =>
      'RichClipboardData{ plainText: $text, htmlText: $html }';
}

class RichClipboard {
  static const MethodChannel _channel = MethodChannel('rich_clipboard');

  static Future<RichClipboardData> getData() async {
    if (!platformSupported) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return RichClipboardData(text: data?.text);
    }

    final data = await _channel
        .invokeMapMethod<String, String?>('RichClipboard.getData');
    if (data == null) {
      return RichClipboardData();
    }

    return RichClipboardData.fromMap(data);
  }

  static Future<void> setData(RichClipboardData data) async {
    if (!platformSupported) {
      await Clipboard.setData(ClipboardData(text: data.text));
    }
    await _channel.invokeMethod('RichClipboard.setData', data.toMap());
  }

  static Future<int> getItemCount() async {
    if (!platformSupported) {
      return -1;
    }
    return await _channel.invokeMethod('RichClipboard.getItemCount');
  }

  static Future<List<String>> getAvailableTypes() async {
    if (!platformSupported) {
      return [];
    }
    final List<String>? result =
        await _channel.invokeListMethod('RichClipboard.getAvailableTypes');
    return result ?? [];
  }
}
