import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/fallback_rich_clipboard.dart';
import 'src/rich_clipboard_data.dart';

export 'src/method_channel_rich_clipboard.dart' show MethodChannelRichClipboard;
export 'src/rich_clipboard_data.dart' show RichClipboardData;

abstract class RichClipboardPlatform extends PlatformInterface {
  RichClipboardPlatform() : super(token: _token);

  static final Object _token = Object();

  static RichClipboardPlatform _instance = FallbackRichClipboard();

  static RichClipboardPlatform get instance => _instance;

  static set instance(RichClipboardPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Retrieves data from the system clipboard in supported formats.
  ///
  /// Platform code may convert from unsupported formats to provide data when it
  /// is not available in a supported format. For example, if no HTML is
  /// available in the clipboard but RTF is, come platforms will convert the RTF
  /// to HTML which will then be included in the returned data.
  ///
  /// Returns a future which completes to a [RichClipboardData].
  Future<RichClipboardData> getData();

  /// Stores the provided data in the system clipboard.
  ///
  /// To clear the clipboard pass an empty [RichClipboardData].
  Future<void> setData(RichClipboardData data);

  /// Retrieves a list of strings representing the data types available in the
  /// system clipboard.
  ///
  /// This method is primarily useful for debugging as the strings are platform
  /// dependent.
  ///
  /// Returns a future that completes to a list of strings. If no data is
  /// available in the system clipboard then the future will resolve to an empty
  /// list.
  Future<List<String>> getAvailableTypes();
}
