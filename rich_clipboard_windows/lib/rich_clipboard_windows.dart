library rich_clipboard_windows;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_data.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart';
import 'package:win32/win32.dart' as win32;

import 'src/html_utilities.dart';

const _kGMemMovable = 0x0002;

const _kHtmlFormat = 'HTML Format';

class _ClipboardFormat {
  final int format;
  final String? name;

  const _ClipboardFormat({required this.format, this.name});
}

class RichClipboardWindows extends RichClipboardPlatform {
  int? __cfHtml;
  int? get _cfHtml {
    if (__cfHtml != null) {
      return __cfHtml;
    }

    int formatId = 0;
    using((arena) {
      final formatStringUnits = _kHtmlFormat.codeUnits;
      final formatStringPtr = arena
          .allocate<Uint16>(sizeOf<Uint16>() * (formatStringUnits.length + 1));
      for (var i = 0; i < formatStringUnits.length; i++) {
        formatStringPtr[i] = formatStringUnits[i];
      }
      formatStringPtr[formatStringUnits.length] = win32.NULL;
      formatId = win32.RegisterClipboardFormat(formatStringPtr.cast<Utf16>());
    });

    if (formatId == 0) {
      return null;
    }

    __cfHtml = formatId;
    return _cfHtml;
  }

  /// Registers the Windows implementation.
  static void registerWith() {
    RichClipboardPlatform.instance = RichClipboardWindows();
  }

  List<_ClipboardFormat> _getFormats() {
    final formats = <_ClipboardFormat>[];
    var current_format = win32.EnumClipboardFormats(win32.NULL);
    using((arena) {
      final name_buffer = arena.allocate<Uint16>(256);
      int max_chars = 256 ~/ sizeOf<Uint16>();

      while (current_format != 0) {
        name_buffer.elementAt(0).cast<Uint16>().value = win32.NULL;
        win32.GetClipboardFormatName(
            current_format, name_buffer.cast<Utf16>(), max_chars);
        String? nameString = name_buffer.cast<Utf16>().toDartString();
        if (nameString.isEmpty) {
          nameString = _win32CfToStrFallback[current_format];
        }
        formats.add(_ClipboardFormat(
          format: current_format,
          name: nameString,
        ));
        current_format = win32.EnumClipboardFormats(current_format);
      }
    });

    return formats;
  }

  @override
  Future<List<String>> getAvailableTypes() async {
    if (win32.OpenClipboard(0) == win32.NULL) {
      return [];
    }

    final formats = _getFormats();
    win32.CloseClipboard();

    return formats.map((cf) => '${cf.format} ("${cf.name}")').toList();
  }

  @override
  Future<RichClipboardData> getData() async {
    if (win32.OpenClipboard(0) == win32.NULL) {
      return const RichClipboardData();
    }

    String? text;
    String? html;
    try {
      text = _getWin32ClipboardString(win32.CF_UNICODETEXT);
      final cfHtml = _cfHtml;
      if (cfHtml != null) {
        html = _getWin32ClipboardString(cfHtml, isUtf8: true);
        if (html != null) {
          html = stripWin32HtmlDescription(html);
        }
      }
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
      _setWin32ClipboardStringByUnits(
        win32.CF_UNICODETEXT,
        data.text!.codeUnits,
      );
    }
    if (data.html != null && _cfHtml != null) {
      _setWin32ClipboardHtml(data.html!);
    }

    win32.CloseClipboard();
  }

  _setWin32ClipboardHtml(String html) {
    final cfHtml = _cfHtml;
    if (cfHtml == null) {
      return;
    }

    final htmlCodeUnits = constructWin32HtmlClipboardData(html);

    _setWin32ClipboardStringByUnits(cfHtml, htmlCodeUnits, isUtf8: true);
  }
}

void _setWin32ClipboardStringByUnits(int format, List<int> units,
    {bool isUtf8 = false}) {
  final unitSize = isUtf8 ? sizeOf<Uint8>() : sizeOf<Uint16>();
  final memHandle = win32.GlobalAlloc(
    _kGMemMovable,
    (units.length + 1) * unitSize,
  );
  if (memHandle == win32.NULL) {
    return;
  }

  final memPointer = win32.GlobalLock(memHandle).cast<Uint16>();

  // Unfortunately I haven't found a way to deduplicate this code further as
  // the exact type of `stringPointer` needs to be known at compile time.
  // Trying to do dynamically assign it with something like
  // `stringPointer = isUtf8 ? memPtr.cast<Uint8>() : memPtr.cast<Uint16>();`
  // results in type errors at compile time.
  if (isUtf8) {
    final stringPointer = memPointer.cast<Uint8>();
    for (var i = 0; i < units.length; i++) {
      stringPointer[i] = units[i];
    }
    stringPointer.elementAt(units.length).value = win32.NULL;
  } else {
    final stringPointer = memPointer.cast<Uint16>();
    for (var i = 0; i < units.length; i++) {
      stringPointer[i] = units[i];
    }
    stringPointer.elementAt(units.length).value = win32.NULL;
  }

  win32.GlobalUnlock(memHandle);
  win32.SetClipboardData(format, memHandle);
}

String? _getWin32ClipboardString(int format, {bool isUtf8 = false}) {
  final handle = win32.GetClipboardData(format);
  if (handle == win32.NULL) {
    return null;
  }

  final rawPtr = win32.GlobalLock(handle);
  if (rawPtr == nullptr) {
    win32.GlobalUnlock(handle);
    return null;
  }

  final String resultString;
  if (isUtf8) {
    resultString = rawPtr.cast<Utf8>().toDartString();
  } else {
    resultString = rawPtr.cast<Utf16>().toDartString();
  }
  win32.GlobalUnlock(handle);

  return resultString;
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
