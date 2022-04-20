import 'dart:convert' show utf8;

import 'package:flutter_test/flutter_test.dart';
import 'package:rich_clipboard_windows/src/html_utilities.dart';

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

const kRawHtmlData = '''
<html><body>
<h1>About Me</h1>
</body>
</html>
''';

void main() {
  test('stripWin32HtmlDescription', () {
    final strippedHtml =
        stripWin32HtmlDescription(kWindowsClipboardHtmlData).trim();
    expect(strippedHtml, startsWith('<html>'));
    expect(strippedHtml, endsWith('</html>'));
  });

  test('constructWin32HtmlClipboardData', () {
    final clipboardHtmlData = constructWin32HtmlClipboardData(kRawHtmlData);
    final clipboardHtmlString = utf8.decode(clipboardHtmlData);

    expect(clipboardHtmlString, startsWith('Version:0.9'));
    expect(clipboardHtmlString, contains('<body><!--StartFragment-->'));
    expect(clipboardHtmlString, contains('<!--EndFragment--></body>'));

    final descriptionKVRegex = RegExp(r'^\w+:.+$');
    final descriptionMap = Map.fromEntries(clipboardHtmlString
        .split('\n')
        .takeWhile((line) => descriptionKVRegex.hasMatch(line))
        .map((line) {
      final kv = line.split(':');
      return MapEntry(kv.first, kv.last);
    }));

    final startHtmlStr = descriptionMap['StartHTML'];
    expect(startHtmlStr, isNotNull);
    final startHtml = int.parse(startHtmlStr!);

    final endHtmlStr = descriptionMap['EndHTML'];
    expect(endHtmlStr, isNotNull);
    final endHtml = int.parse(endHtmlStr!);

    final htmlString =
        utf8.decode(clipboardHtmlData.sublist(startHtml, endHtml)).trim();
    expect(htmlString, startsWith('<html>'));
    expect(htmlString, endsWith('</html>'));

    final startFragmentStr = descriptionMap['StartFragment'];
    expect(startFragmentStr, isNotNull);
    final startFragment = int.parse(startFragmentStr!);

    final endFragmentStr = descriptionMap['EndFragment'];
    expect(endFragmentStr, isNotNull);
    final endFragment = int.parse(endFragmentStr!);

    final fragmentString = utf8
        .decode(clipboardHtmlData.sublist(startFragment, endFragment))
        .trim();
    expect(fragmentString, startsWith('<h1>'));
    expect(fragmentString, endsWith('</h1>'));
  });
}
