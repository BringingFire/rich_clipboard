import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final _platformSupported = !kIsWeb &&
    (Platform.environment.containsKey('FLUTTER_TEST') || Platform.isMacOS);

const _kTextPlain = 'text/plain';
const _kTextHtml = 'text/html';

/// Data from the system clipboard.
@immutable
class RichClipboardData implements ClipboardData {
  const RichClipboardData({this.text, this.html});
  RichClipboardData.fromMap(Map<String, String?> map)
      : this(
          text: map[_kTextPlain],
          html: map[_kTextHtml],
        );

  @override
  final String? text;

  /// HTML variant of this clipboard data.
  final String? html;

  /// Convert this object to a map of MIME types to strings.
  ///
  /// This is primarily a convenience method for passing [RichClipboardData]
  /// instances across a Flutter [MethodChannel].
  Map<String, String?> toMap() => {
        _kTextPlain: text,
        _kTextHtml: html,
      };

  @override
  String toString() => 'RichClipboardData{ text: $text, html: $html }';
}

/// Utility methods for interacting with the system's clipboard with support for
/// various data formats.
class RichClipboard {
  // Prevent instantiation or extension
  RichClipboard._();

  static const MethodChannel _channel =
      MethodChannel('com.bringingfire.rich_clipboard');

  /// Retrieves data from the system clipboard in supported formats.
  ///
  /// Platform code may convert from unsupported formats to provide data when it
  /// is not available in a supported format. For example, if no HTML is
  /// available in the clipboard but RTF is, that RTF will be converted to HTML
  /// which will then be included in the returned data.
  ///
  /// Returns a future which completes to a [RichClipboardData].
  static Future<RichClipboardData> getData() async {
    if (!_platformSupported) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return RichClipboardData(text: data?.text);
    }

    final data = await _channel.invokeMapMethod<String, String?>('getData');
    if (data == null) {
      return const RichClipboardData();
    }

    return RichClipboardData.fromMap(data);
  }

  /// Stores the provided data in the system clipboard.
  ///
  /// To clear the clipboard pass an empty [RichClipboardData].
  static Future<void> setData(RichClipboardData data) async {
    if (!_platformSupported) {
      await Clipboard.setData(ClipboardData(text: data.text));
    }
    await _channel.invokeMethod('setData', data.toMap());
  }

  /// Retrieves a list of strings representing the data types available in the
  /// system clipboard.
  ///
  /// This method is primarily useful for debugging as the strings are platform
  /// dependent.
  ///
  /// Returns a future that completes to a list of strings. If no data is
  /// available in the system clipboard then the future will resolve to an empty
  /// list.
  static Future<List<String>> getAvailableTypes() async {
    if (!_platformSupported) {
      return [];
    }
    final List<String>? result =
        await _channel.invokeListMethod('getAvailableTypes');
    return result ?? [];
  }
}
