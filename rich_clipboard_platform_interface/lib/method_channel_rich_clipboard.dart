import 'package:flutter/services.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_data.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart';

const MethodChannel _channel = MethodChannel('com.bringingfire.rich_clipboard');

class MethodChannelRichClipboard extends RichClipboardPlatform {
  @override
  Future<List<String>> getAvailableTypes() async {
    final List<String>? result =
        await _channel.invokeListMethod('getAvailableTypes');
    return result ?? [];
  }

  @override
  Future<RichClipboardData> getData() async {
    final data = await _channel.invokeMapMethod<String, String?>('getData');
    if (data == null) {
      return const RichClipboardData();
    }

    return RichClipboardData.fromMap(data);
  }

  @override
  Future<void> setData(RichClipboardData data) async {
    await _channel.invokeMethod('setData', data.toMap());
  }
}
