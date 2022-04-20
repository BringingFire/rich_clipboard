import 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart';

export 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart'
    show RichClipboardData;

/// Utility methods for interacting with the system's clipboard with support for
/// various data formats.
class RichClipboard {
  RichClipboard._();

  static RichClipboardPlatform get _platform => RichClipboardPlatform.instance;

  /// Retrieves a list of strings representing the data types available in the
  /// system clipboard.
  ///
  /// This method is primarily useful for debugging as the strings are platform
  /// dependent.
  ///
  /// Returns a future that completes to a list of strings. If no data is
  /// available in the system clipboard then the future will complete to an
  /// empty list.
  static Future<List<String>> getAvailableTypes() async =>

      await _platform.getAvailableTypes();

  /// Retrieves data from the system clipboard in supported formats.
  ///
  /// Platform code may convert from unsupported formats to provide data when it
  /// is not available in a supported format. For example, if no HTML is
  /// available in the clipboard but RTF is, some platforms will convert the RTF
  /// to HTML which will then be included in the returned data.
  ///
  /// Returns a future which completes to a [RichClipboardData].
  static Future<RichClipboardData> getData() async => await _platform.getData();

  /// Stores the provided data in the system clipboard.
  ///
  /// To clear the clipboard pass an empty [RichClipboardData].
  static Future<void> setData(RichClipboardData data) async =>
      _platform.setData(data);
}
