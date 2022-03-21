import 'dart:async';

import 'package:flutter/services.dart';

class RichClipboard {
  static const MethodChannel _channel = MethodChannel('rich_clipboard');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
