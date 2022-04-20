import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

export 'package:win32/win32.dart' show CF_UNICODETEXT;

enum ClipboardEncoding {
  utf8,
  utf16,
}

// Flag for [GlobalAlloc] to make the allocated memory movable.
const _kGMemMovable = 0x0002;

/// A wrapper around win32 API calls related to the clipboard.
///
/// This class exists to isolate FFI code from the rest of the library, as well
/// as allow for mocking out these API calls in tests.
class Win32Clipboard {
  /// Opens the clipboard and prevents other applications from modifying it.
  bool open() => OpenClipboard(0) == TRUE;

  bool close() => CloseClipboard() == TRUE;

  /// Clears the clipboard and claims ownership of it.
  ///
  /// You must already have opened the clipboard with [Win32Clipboard.open].
  bool empty() => EmptyClipboard() == TRUE;

  /// Register a clipboard format with the given name.
  ///
  /// Returns the id of the newly registered format. If a format has already
  /// been registered with the given name, its id is returned. Returns null if
  /// an error occurs.
  int? registerFormat(String name) {
    int formatId = NULL;
    using((arena) {
      final formatStringUnits = name.codeUnits;
      final formatStringPtr = arena
          .allocate<Uint16>(sizeOf<Uint16>() * (formatStringUnits.length + 1));
      for (var i = 0; i < formatStringUnits.length; i++) {
        formatStringPtr[i] = formatStringUnits[i];
      }
      formatStringPtr[formatStringUnits.length] = NULL;
      formatId = RegisterClipboardFormat(formatStringPtr.cast<Utf16>());
    });

    return formatId == NULL ? null : formatId;
  }

  /// Returns a list of the formats currently available in the clipboard.
  ///
  /// You must already have opened the clipboard with [Win32Clipboard.open].
  List<ClipboardFormat> getAvailableFormats() {
    final formats = <ClipboardFormat>[];
    var current_format = EnumClipboardFormats(NULL);
    using((arena) {
      final name_buffer = arena.allocate<Uint16>(256);
      int max_chars = 256 ~/ sizeOf<Uint16>();

      while (current_format != 0) {
        name_buffer.elementAt(0).cast<Uint16>().value = NULL;
        GetClipboardFormatName(
            current_format, name_buffer.cast<Utf16>(), max_chars);
        String? nameString = name_buffer.cast<Utf16>().toDartString();
        if (nameString.isEmpty) {
          nameString = _win32CfToStrFallback[current_format];
        }
        formats.add(ClipboardFormat(
          format: current_format,
          name: nameString,
        ));
        current_format = EnumClipboardFormats(current_format);
      }
    });

    return formats;
  }

  /// Read a string from the clipboard.
  ///
  /// You must already have opened the clipboard with [Win32Clipboard.open].
  String? getString(int format, {encoding = ClipboardEncoding.utf16}) {
    final handle = GetClipboardData(format);
    if (handle == NULL) {
      return null;
    }

    final rawPtr = GlobalLock(handle);
    if (rawPtr == nullptr) {
      GlobalUnlock(handle);
      return null;
    }

    late final String resultString;
    switch (encoding) {
      case ClipboardEncoding.utf16:
        resultString = rawPtr.cast<Utf16>().toDartString();
        break;
      case ClipboardEncoding.utf8:
        resultString = rawPtr.cast<Utf8>().toDartString();
        break;
    }

    GlobalUnlock(handle);

    return resultString;
  }

  /// Write the provided string to the clipboard.
  ///
  /// You must already have opened the clipboard with [Win32Clipboard.open].
  void setString(int format, String string,
      {encoding = ClipboardEncoding.utf16}) {
    late final List<int> units;
    switch (encoding) {
      case ClipboardEncoding.utf16:
        units = string.codeUnits;
        break;
      case ClipboardEncoding.utf8:
        units = utf8.encode(string);
        break;
    }
    setStringByUnits(format, units);
  }

  /// Write the provided code units to the clipboard.
  ///
  /// You must already have opened the clipboard with [Win32Clipboard.open].
  void setStringByUnits(
    int format,
    List<int> units, {
    encoding = ClipboardEncoding.utf16,
  }) {
    late final int unitSize;
    switch (encoding) {
      case ClipboardEncoding.utf16:
        unitSize = sizeOf<Uint16>();
        break;
      case ClipboardEncoding.utf8:
        unitSize = sizeOf<Uint8>();
        break;
    }

    final memHandle = GlobalAlloc(_kGMemMovable, (units.length + 1) * unitSize);
    if (memHandle == NULL) {
      return;
    }

    final memPointer = GlobalLock(memHandle).cast<Uint16>();

    // Unfortunately I haven't found a way to deduplicate this code further as
    // the exact type of `stringPointer` needs to be known at compile time.
    // Trying to do dynamically assign it with something like
    // `stringPointer = isUtf8 ? memPtr.cast<Uint8>() : memPtr.cast<Uint16>();`
    // results in type errors at compile time.
    switch (encoding) {
      case ClipboardEncoding.utf8:
        final stringPointer = memPointer.cast<Uint8>();
        for (var i = 0; i < units.length; i++) {
          stringPointer[i] = units[i];
        }
        stringPointer.elementAt(units.length).value = NULL;
        break;
      case ClipboardEncoding.utf16:
        final stringPointer = memPointer.cast<Uint16>();
        for (var i = 0; i < units.length; i++) {
          stringPointer[i] = units[i];
        }
        stringPointer.elementAt(units.length).value = NULL;
        break;
    }

    GlobalUnlock(memHandle);
    SetClipboardData(format, memHandle);
  }
}

/// A data class representing a data format in the win32 clipboard.
class ClipboardFormat {
  // The id of the format
  final int format;
  // The name of the format, if available.
  final String? name;

  const ClipboardFormat({required this.format, this.name});
}

/// A map of default clipboard type ids to names.
///
/// This is here because the win32 API call to get the name of a format doesn't
/// return anything for the default types.
const _win32CfToStrFallback = <int, String>{
  CF_TEXT: 'CF_TEXT',
  CF_BITMAP: 'CF_BITMAP',
  CF_METAFILEPICT: 'CF_METAFILEPICT',
  CF_SYLK: 'CF_SYLK',
  CF_DIF: 'CF_DIF',
  CF_TIFF: 'CF_TIFF',
  CF_OEMTEXT: 'CF_OEMTEXT',
  CF_DIB: 'CF_DIB',
  CF_PALETTE: 'CF_PALETTE',
  CF_PENDATA: 'CF_PENDATA',
  CF_RIFF: 'CF_RIFF',
  CF_WAVE: 'CF_WAVE',
  CF_UNICODETEXT: 'CF_UNICODETEXT',
  CF_ENHMETAFILE: 'CF_ENHMETAFILE',
  CF_HDROP: 'CF_HDROP',
  CF_LOCALE: 'CF_LOCALE',
  CF_DIBV5: 'CF_DIBV5',
  CF_OWNERDISPLAY: 'CF_OWNERDISPLAY',
  CF_DSPTEXT: 'CF_DSPTEXT',
  CF_DSPBITMAP: 'CF_DSPBITMAP',
  CF_DSPMETAFILEPICT: 'CF_DSPMETAFILEPICT',
  CF_DSPENHMETAFILE: 'CF_DSPENHMETAFILE',
  CF_PRIVATEFIRST: 'CF_PRIVATEFIRST',
  CF_PRIVATELAST: 'CF_PRIVATELAST',
  CF_GDIOBJFIRST: 'CF_GDIOBJFIRST',
  CF_GDIOBJLAST: 'CF_GDIOBJLAST',
};
