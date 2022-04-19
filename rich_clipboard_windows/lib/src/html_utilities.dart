import 'dart:convert' show utf8;

const _kHtmlFormat = 'HTML Format';
const _kStartFragmentComment = '<!--StartFragment-->';
const _kEndFragmentComment = '<!--EndFragment-->';

const _kHtmlDescriptionTemplate =
    '''
Version:0.9
StartHTML:0000000000
EndHTML:0000000000
StartFragment:0000000000
EndFragment:0000000000
''';

/// Remove the leading description from Windows clipboard HTML.
///
/// See [HTML Clipboard Format](https://docs.microsoft.com/en-us/windows/win32/dataxchg/html-clipboard-format)
/// for details.
String stripWin32HtmlDescription(String html) {
  // The description has a StartHTML field we could use to calculate this
  // instead, but it's in terms of byte offset so is annoying to work with
  // once we already converted back to a Dart string, and since it's generated
  // in application code it could just contain garbage anyway.
  final startHtml = html.indexOf('<html');
  final htmlStr = html.substring(startHtml < 0 ? 0 : startHtml);

  return htmlStr;
}

/// Turn an HTML document into a list of UTF-8 code units suitable for storing
/// in the Windows clipboard as the "HTML Format" type.
List<int> constructWin32HtmlClipboardData(String html) {
  // Windows wants these marker comments in the HTML, and future parts of our
  // code relies on them being present. It's probably technically incorrect
  // to just wrap the entire body since that could include things like meta
  // tags, but it works for Google Docs so it's good enough for us.
  if (!html.contains(_kStartFragmentComment)) {
    final startBodyIndex = html.indexOf('<body>') + '<body>'.length;
    html = html.substring(0, startBodyIndex) +
        _kStartFragmentComment +
        html.substring(startBodyIndex);
  }
  if (!html.contains(_kEndFragmentComment)) {
    final endBodyIndex = html.indexOf('</body>');
    html = html.substring(0, endBodyIndex) +
        _kEndFragmentComment +
        html.substring(endBodyIndex);
  }

  final descUtf8Len = utf8.encode(_kHtmlDescriptionTemplate).length;
  final htmlUtf8 = utf8.encode(html);
  final htmlStart = descUtf8Len;
  final htmlEnd = descUtf8Len + htmlUtf8.length;
  final fragmentStart = descUtf8Len +
      utf8
          .encode(html.substring(0, html.indexOf(_kStartFragmentComment)))
          .length +
      utf8.encode(_kStartFragmentComment).length;
  final fragmentEnd = descUtf8Len +
      utf8
          .encode(html.substring(0, html.lastIndexOf(_kEndFragmentComment)))
          .length;
  final desc = _kHtmlDescriptionTemplate
      .replaceAll(
        'StartHTML:0000000000',
        'StartHTML:${htmlStart.toString().padLeft(10, '0')}',
      )
      .replaceAll(
        'EndHTML:0000000000',
        'EndHTML:${htmlEnd.toString().padLeft(10, '0')}',
      )
      .replaceAll(
        'StartFragment:0000000000',
        'StartFragment:${fragmentStart.toString().padLeft(10, '0')}',
      )
      .replaceAll(
        'EndFragment:0000000000',
        'EndFragment:${fragmentEnd.toString().padLeft(10, '0')}',
      );
  final descUtf8 = utf8.encode(desc);
  final utf8Result = [...descUtf8, ...htmlUtf8];
  return utf8Result;
}
