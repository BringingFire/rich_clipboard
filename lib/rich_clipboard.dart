import 'package:flutter/services.dart';

const _kMimeTextPlain = 'text/plain';
const _kMimeTextHtml = 'text/html';

class RichClipboardData {
  RichClipboardData({this.plainText, this.htmlText});
  RichClipboardData.fromMap(Map<String, String?> map)
      : this(
          plainText: map[_kMimeTextPlain],
          htmlText: map[_kMimeTextHtml],
        );

  final String? plainText;
  final String? htmlText;

  Map<String, String?> toMap() => {
        _kMimeTextPlain: plainText,
        _kMimeTextHtml: htmlText,
      };
  @override
  String toString() =>
      'RichClipboardData{ plainText: $plainText, htmlText: $htmlText }';
}

class RichClipboard {
  static const MethodChannel _channel = MethodChannel('rich_clipboard');

  static Future<RichClipboardData> getData() async {
    final data = await _channel
        .invokeMapMethod<String, String?>('RichClipboard.getData');
    if (data == null) {
      return RichClipboardData();
    }

    return RichClipboardData.fromMap(data);
  }

  static Future<void> setData(RichClipboardData data) async {
    await _channel.invokeMethod('RichClipboard.setData', data.toMap());
  }

  static Future<int> getItemCount() async {
    return await _channel.invokeMethod('getItemCount');
  }

  static Future<String?> asHtml() async {
    return await _channel.invokeMethod('asHtml');
  }

  static Future<List<String>> getAvailableTypes() async {
    final List<String>? result =
        await _channel.invokeListMethod('getAvailableTypes');
    return result ?? [];
  }
}
