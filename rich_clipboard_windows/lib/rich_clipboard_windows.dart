library rich_clipboard_windows;

import 'dart:convert' show utf8;
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_data.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart';
import 'package:win32/win32.dart' as win32;

const _kCFHtml = 49286;
const _kGMemMovable = 0x0002;

class RichClipboardWindows extends RichClipboardPlatform {
  /// Registers the Windows implementation.
  static void registerWith() {
    RichClipboardPlatform.instance = RichClipboardWindows();
  }

  @override
  Future<List<String>> getAvailableTypes() async {
    if (win32.OpenClipboard(0) == win32.NULL) {
      return [];
    }

    final formats = <String>[];
    var current_format = win32.EnumClipboardFormats(0);

    using((arena) {
      final name_buffer = arena.allocate<Utf16>(256);
      int max_chars = 256 ~/ sizeOf<Uint16>();

      while (current_format != 0) {
        win32.GetClipboardFormatName(current_format, name_buffer, max_chars);
        var nameString = name_buffer.toDartString();
        if (nameString.isEmpty) {
          nameString = _win32CfToStrFallback[current_format] ?? '';
        }
        formats.add('$nameString ($current_format)');
        current_format = win32.EnumClipboardFormats(current_format);
      }
    });

    win32.CloseClipboard();
    return formats;
  }

  @override
  Future<RichClipboardData> getData() async {
    if (win32.OpenClipboard(0) == win32.NULL) {
      return const RichClipboardData();
    }

    final String? text;
    final String? html;
    try {
      text = _getWin32ClipboardString([win32.CF_UNICODETEXT]);
      html = _getWin32ClipboardString(
        [
          // 49796,
          _kCFHtml,
          // 13,
        ],
        ascii: true,
      );
    } finally {
      win32.CloseClipboard();
    }

    return RichClipboardData(
      text: text,
      html: html,
    );
  }

  @override
  Future<void> setData(RichClipboardData data) async {
    if (win32.OpenClipboard(0) == win32.NULL) {
      return;
    }

    win32.EmptyClipboard();

    if (data.text != null) {
      final textUtf16 = data.text!.codeUnits;
      final alloc = win32.GlobalAlloc(
          _kGMemMovable, (textUtf16.length + 1) * sizeOf<Uint16>());
      final handle = win32.GlobalLock(alloc).cast<Uint16>();
      for (var i = 0; i < textUtf16.length; i++) {
        handle.elementAt(i).value = textUtf16[i];
      }
      handle.elementAt(textUtf16.length).value = 0x0;
      win32.GlobalUnlock(alloc);
      win32.SetClipboardData(win32.CF_UNICODETEXT, alloc);
    }

    win32.CloseClipboard();
  }
}

String? _getWin32ClipboardString(List<int> formats, {bool ascii = false}) {
  int chosenFormat = -1;
  using((arena) {
    final formatsPtr = arena.allocate<Uint32>(formats.length);
    for (var i = 0; i < formats.length; i++) {
      formatsPtr.elementAt(i).value = formats[i];
    }

    chosenFormat = win32.GetPriorityClipboardFormat(formatsPtr, formats.length);
  });

  if (chosenFormat < 1) {
    return null;
  }

  final handle = win32.GetClipboardData(chosenFormat);
  if (handle == win32.NULL) {
    final err = win32.GetLastError();
    print('ERR: 0x${err.toRadixString(16)}');
    return null;
  }

  final rawPtr = win32.GlobalLock(handle);
  if (rawPtr == nullptr) {
    win32.GlobalUnlock(handle);
    return null;
  }

  final String fullStr;
  if (ascii) {
    fullStr = rawPtr.cast<Utf8>().toDartString();
  } else {
    fullStr = rawPtr.cast<Utf16>().toDartString();
  }
  win32.GlobalUnlock(handle);

  if (!ascii) {
    return fullStr;
  }

  final startHtml = fullStr.indexOf('<html');
  final htmlStr = fullStr.substring(startHtml < 0 ? 0 : startHtml);

  return htmlStr;
}

const _win32CfToStrFallback = <int, String>{
  win32.CF_TEXT: 'CF_TEXT',
  win32.CF_BITMAP: 'CF_BITMAP',
  win32.CF_METAFILEPICT: 'CF_METAFILEPICT',
  win32.CF_SYLK: 'CF_SYLK',
  win32.CF_DIF: 'CF_DIF',
  win32.CF_TIFF: 'CF_TIFF',
  win32.CF_OEMTEXT: 'CF_OEMTEXT',
  win32.CF_DIB: 'CF_DIB',
  win32.CF_PALETTE: 'CF_PALETTE',
  win32.CF_PENDATA: 'CF_PENDATA',
  win32.CF_RIFF: 'CF_RIFF',
  win32.CF_WAVE: 'CF_WAVE',
  win32.CF_UNICODETEXT: 'CF_UNICODETEXT',
  win32.CF_ENHMETAFILE: 'CF_ENHMETAFILE',
  win32.CF_HDROP: 'CF_HDROP',
  win32.CF_LOCALE: 'CF_LOCALE',
  win32.CF_DIBV5: 'CF_DIBV5',
  win32.CF_OWNERDISPLAY: 'CF_OWNERDISPLAY',
  win32.CF_DSPTEXT: 'CF_DSPTEXT',
  win32.CF_DSPBITMAP: 'CF_DSPBITMAP',
  win32.CF_DSPMETAFILEPICT: 'CF_DSPMETAFILEPICT',
  win32.CF_DSPENHMETAFILE: 'CF_DSPENHMETAFILE',
  win32.CF_PRIVATEFIRST: 'CF_PRIVATEFIRST',
  win32.CF_PRIVATELAST: 'CF_PRIVATELAST',
  win32.CF_GDIOBJFIRST: 'CF_GDIOBJFIRST',
  win32.CF_GDIOBJLAST: 'CF_GDIOBJLAST',
};

List<int> _templateWin32HtmlClipboardData(String html) {
  final desc = '''
Version:0.9
    StartHTML:0000000000
    EndHTML:0000000000
    StartFragment:0000000000
    EndFragment:0000000000
''';
  final descUtf8Len = utf8.encode(desc).length;
  final htmlUtf8 = utf8.encode(html);
  final htmlStart = descUtf8Len;
  final htmlEnd = descUtf8Len + htmlUtf8.length;
  desc.replaceAll('StartHTML:0000000000',
      'StartHTML:${htmlStart.toString().padLeft(10, '0')}');
  desc.replaceAll(
      'EndHTML:0000000000', 'EndHTML:${htmlEnd.toString().padLeft(10, '0')}');
  desc.replaceAll('StartFragment:0000000000',
      'StartHTML:${htmlStart.toString().padLeft(10, '0')}');
  desc.replaceAll('EndFragment:0000000000',
      'EndHTML:${htmlEnd.toString().padLeft(10, '0')}');
  final descUtf8 = utf8.encode(desc);
  return [...descUtf8, ...htmlUtf8];
}
