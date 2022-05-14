library rich_clipboard_windows;

import 'package:flutter/foundation.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart';
import 'package:rich_clipboard_windows/src/win32_clipboard.dart';

import 'src/html_utilities.dart';

const _kHtmlFormat = 'HTML Format';

/// The Windows implementation of [RichClipboard].
class RichClipboardWindows extends RichClipboardPlatform {
  /// The object for managing clipboard related win32 API calls.
  @visibleForTesting
  Win32Clipboard clipboard = Win32Clipboard();

  /// Registers the Windows implementation.
  static void registerWith() {
    RichClipboardPlatform.instance = RichClipboardWindows();
  }

  /// The id of the clipboard format for HTML.
  ///
  /// This getter will register the format if it does not already exist. Only
  /// evaluates to `null` when an error occurs.
  @visibleForTesting
  int? get cfHtml {
    _cfHtml ??= clipboard.registerFormat(_kHtmlFormat);
    return _cfHtml;
  }

  int? _cfHtml;

  @override
  Future<List<String>> getAvailableTypes() async {
    if (!clipboard.open()) {
      return [];
    }

    final results = clipboard
        .getAvailableFormats()
        .map((cf) => '${cf.format} ("${cf.name}")')
        .toList();
    clipboard.close();
    return results;
  }

  @override
  Future<RichClipboardData> getData() async {
    if (!clipboard.open()) {
      return const RichClipboardData();
    }

    String? text;
    String? html;
    try {
      text = clipboard.getString(CF_UNICODETEXT);
      if (cfHtml != null) {
        html = clipboard.getString(cfHtml!, encoding: ClipboardEncoding.utf8);
        if (html != null) {
          html = stripWin32HtmlDescription(html);
        }
      }
    } finally {
      clipboard.close();
    }

    return RichClipboardData(
      text: text,
      html: html,
    );
  }

  @override
  Future<void> setData(RichClipboardData data) async {
    if (!clipboard.open()) {
      return;
    }

    clipboard.empty();

    if (data.text != null) {
      clipboard.setString(CF_UNICODETEXT, data.text!);
    }
    if (data.html != null && cfHtml != null) {
      _setHtmlData(data.html!);
    }

    clipboard.close();
  }

  _setHtmlData(String html) {
    if (cfHtml == null) {
      return;
    }

    final htmlCodeUnits = constructWin32HtmlClipboardData(html);

    clipboard.setStringByUnits(cfHtml!, htmlCodeUnits,
        encoding: ClipboardEncoding.utf8);
  }
}
