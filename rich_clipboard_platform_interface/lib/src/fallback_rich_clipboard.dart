import 'package:flutter/services.dart';

import '../rich_clipboard_platform_interface.dart';

/// A partial implementation of [RichClipboardPlatform] that provides
/// functionality on unsupported platforms.
///
/// This class uses Flutter's built-in [Clipboard] to provide plain text support
/// and silently discards other content types
class FallbackRichClipboard extends RichClipboardPlatform {
  @override
  Future<List<String>> getAvailableTypes() async =>
      const [Clipboard.kTextPlain];

  @override
  Future<RichClipboardData> getData() => Clipboard.getData(Clipboard.kTextPlain)
      .then((d) => RichClipboardData(text: d?.text));

  @override
  Future<void> setData(RichClipboardData data) => Clipboard.setData(data);
}
