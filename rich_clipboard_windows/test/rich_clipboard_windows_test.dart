import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rich_clipboard_platform_interface/rich_clipboard_platform_interface.dart';
import 'package:rich_clipboard_windows/rich_clipboard_windows.dart';
import 'package:rich_clipboard_windows/src/win32_clipboard.dart';

import 'rich_clipboard_windows_test.mocks.dart';

@GenerateMocks([Win32Clipboard])
void main() {
  late MockWin32Clipboard win32clipboard;
  late RichClipboardWindows clipboard;

  setUp(() {
    win32clipboard = MockWin32Clipboard();
    clipboard = RichClipboardWindows()..clipboard = win32clipboard;
  });

  test('registerWith', () {
    RichClipboardWindows.registerWith();
    expect(RichClipboardPlatform.instance, isA<RichClipboardWindows>());
  });

  test('cfHtml registers the format and caches the result', () {
    final htmlId = 27017;
    when(win32clipboard.registerFormat(any)).thenReturn(htmlId);

    expect(clipboard.cfHtml, htmlId);
    expect(clipboard.cfHtml, htmlId);
    expect(
      verify(win32clipboard.registerFormat(captureAny)).captured.single,
      'HTML Format',
    );
  });

  group('getAvailableTypes', () {
    test('returns an empty list when the clipboard cannot be opened', () async {
      when(win32clipboard.open()).thenReturn(false);

      final results = await clipboard.getAvailableTypes();

      expect(results, isEmpty);
      verify(win32clipboard.open()).called(1);
    });
    test('returns an empty list when there are no results', () async {
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.getAvailableFormats()).thenReturn([]);

      final results = await clipboard.getAvailableTypes();

      expect(results, isEmpty);
      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.getAvailableFormats()).called(1);
      verify(win32clipboard.close()).called(1);
    });

    test('returns strings with both the id and name if available', () async {
      const availableFormats = [
        ClipboardFormat(format: 10),
        ClipboardFormat(format: 20, name: 'deadbeef'),
      ];
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.getAvailableFormats()).thenReturn(availableFormats);

      final results = await clipboard.getAvailableTypes();

      expect(results, hasLength(2));
      expect(results.first, contains(availableFormats.first.format.toString()));
      expect(results.last, contains(availableFormats.last.format.toString()));
      expect(results.last, contains(availableFormats.last.name!));

      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.getAvailableFormats()).called(1);
      verify(win32clipboard.close()).called(1);
    });
  });

  group('getData', () {
    test('returns empty data if the clipboard cannot be opened', () async {
      when(win32clipboard.open()).thenReturn(false);

      final results = await clipboard.getData();

      expect(results, const RichClipboardData());
      verify(win32clipboard.open()).called(1);
    });

    test('returns empty data when none is available', () async {
      const htmlId = 27017;
      const htmlName = 'HTML Format';
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.registerFormat(htmlName)).thenReturn(htmlId);
      when(win32clipboard.getString(CF_UNICODETEXT)).thenReturn(null);
      when(win32clipboard.getString(htmlId, encoding: ClipboardEncoding.utf8))
          .thenReturn(null);

      final results = await clipboard.getData();

      expect(results, const RichClipboardData());
      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.getString(CF_UNICODETEXT));
      verify(
          win32clipboard.getString(htmlId, encoding: ClipboardEncoding.utf8));
      verify(win32clipboard.close()).called(1);
    });

    test('returns data with text when only text is available', () async {
      const htmlId = 27017;
      const htmlName = 'HTML Format';
      const text = 'hello there';
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.registerFormat(htmlName)).thenReturn(htmlId);
      when(win32clipboard.getString(CF_UNICODETEXT)).thenReturn(text);
      when(win32clipboard.getString(htmlId, encoding: ClipboardEncoding.utf8))
          .thenReturn(null);

      final results = await clipboard.getData();

      expect(results, const RichClipboardData(text: text));
      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.getString(CF_UNICODETEXT));
      verify(
          win32clipboard.getString(htmlId, encoding: ClipboardEncoding.utf8));
      verify(win32clipboard.close()).called(1);
    });

    test('returns data with both text and html when both are available',
        () async {
      const htmlId = 27017;
      const htmlName = 'HTML Format';
      const text = 'About Me';
      const html = kWindowsClipboardHtmlData;
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.registerFormat(htmlName)).thenReturn(htmlId);
      when(win32clipboard.getString(CF_UNICODETEXT)).thenReturn(text);
      when(win32clipboard.getString(htmlId, encoding: ClipboardEncoding.utf8))
          .thenReturn(html);

      final results = await clipboard.getData();

      expect(results.text, text);
      expect(results.html, isNotNull);
      expect(results.html?.trim(), startsWith('<html>'));
      expect(results.html?.trim(), endsWith('</html>'));
      expect(results.html, contains('About Me'));

      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.getString(CF_UNICODETEXT));
      verify(
          win32clipboard.getString(htmlId, encoding: ClipboardEncoding.utf8));
      verify(win32clipboard.close()).called(1);
    });
  });

  group('setData', () {
    test('returns early if the clipboard cannot be opened', () async {
      when(win32clipboard.open()).thenReturn(false);

      await clipboard.setData(const RichClipboardData());

      verify(win32clipboard.open()).called(1);
    });

    test('clears the clipboard when empty data is passed', () async {
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.empty()).thenReturn(true);

      await clipboard.setData(const RichClipboardData());

      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.empty()).called(1);
      verify(win32clipboard.close()).called(1);
    });

    test('only sets text if only text is provided', () async {
      const text = 'hello there';
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.empty()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.setString(CF_UNICODETEXT, any)).thenReturn(true);

      await clipboard.setData(const RichClipboardData(text: text));

      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.setString(CF_UNICODETEXT, text)).called(1);
      verify(win32clipboard.close()).called(1);
    });

    test('sets text and html when both are provided', () async {
      const text = 'hello there';
      const html = '<html><body><h1>hello there</h1></body></html>';
      const htmlId = 27017;
      const htmlName = 'HTML Format';
      when(win32clipboard.open()).thenReturn(true);
      when(win32clipboard.empty()).thenReturn(true);
      when(win32clipboard.close()).thenReturn(true);
      when(win32clipboard.registerFormat(htmlName)).thenReturn(htmlId);
      when(win32clipboard.setString(CF_UNICODETEXT, any)).thenReturn(true);
      when(win32clipboard.setStringByUnits(
        htmlId,
        any,
        encoding: ClipboardEncoding.utf8,
      )).thenReturn(true);

      await clipboard.setData(const RichClipboardData(text: text, html: html));

      verify(win32clipboard.open()).called(1);
      verify(win32clipboard.setString(CF_UNICODETEXT, text)).called(1);
      final htmlUnits = verify(win32clipboard.setStringByUnits(
              htmlId, captureAny,
              encoding: ClipboardEncoding.utf8))
          .captured
          .single as List<int>;
      final htmlString = utf8.decode(htmlUnits);
      expect(htmlString, contains('<h1>hello there</h1>'));
      expect(htmlString, startsWith('Version:0.9'));
      expect(htmlString, contains('<!--StartFragment-->'));
      expect(htmlString, contains('<!--EndFragment-->'));
      verify(win32clipboard.close()).called(1);
    });
  });
}

const kWindowsClipboardHtmlData = '''
Version:0.9
StartHTML:00000134
EndHTML:00000221
StartFragment:00000168
EndFragment:00000185
SourceURL:https://jmatth.com/about/
<html><body>
<!--StartFragment--><h1>About Me</h1><!--EndFragment-->
</body>
</html>
''';
