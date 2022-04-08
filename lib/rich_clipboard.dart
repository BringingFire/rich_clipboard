import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _kMimeTextPlain = 'text/plain';
const _kMimeTextHtml = 'text/html';

final platformSupported = !kIsWeb && Platform.isMacOS;

/// Data from the system clipboard.
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
  String toString() => 'RichClipboardData{ plainText: $text, htmlText: $html }';
}

/// Utility methods for interacting with the systems clipboard with support for
/// various data formats.
class RichClipboard {
  // Prevent instantiation or extension
  RichClipboard._();

  static const MethodChannel _channel = MethodChannel('rich_clipboard');

  /// Retrieves data from the clipboard.
  ///
  /// Returns a future which completes to a [RichClipboardData] containing all
  /// available formats that were found in the clipboard.
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

  /// Clears the system clipboard and then stores the provided data.
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

  /// Returns a list of strings representing the data types available in the
  /// system clipboard.
  ///
  /// Primarily useful for debugging. The returned strings are platform
  /// dependent and likely do not conform to anything easily usable like MIME
  /// types.
  static Future<List<String>> getAvailableTypes() async {
    if (!platformSupported) {
      return [];
    }
    final List<String>? result =
        await _channel.invokeListMethod('RichClipboard.getAvailableTypes');
    return result ?? [];
  }
}
