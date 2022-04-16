import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

void main() {
  const MethodChannel channel = MethodChannel('rich_clipboard');

  TestWidgetsFlutterBinding.ensureInitialized();

  String? text;
  String? html;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      switch (methodCall.method) {
        case 'RichClipboard.getData':
          return html == null && text == null
              ? null
              : {
                  RichClipboard.kTextHtml: html,
                  RichClipboard.kTextPlain: text,
                };
        case 'RichClipboard.setData':
          final args = (methodCall.arguments as Map<Object?, Object?>);
          text = args[RichClipboard.kTextPlain] as String?;
          html = args[RichClipboard.kTextHtml] as String?;
          break;
        default:
          throw PlatformException(
            code: 'ERR_METHOD_UNIMPLEMENTED',
            message: 'Unimplemented method ${methodCall.method}',
          );
      }
      return null;
    });
  });

  setUpAll(() {
    text = null;
    html = null;
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group('getData', () {
    test('returns an empty object when the clipboard is empty', () async {
      final data = await RichClipboard.getData();
      expect(data.text, isNull);
      expect(data.html, isNull);
    });

    test('returns an object with text when there is only plain text', () async {
      text = 'hello there';
      final data = await RichClipboard.getData();
      expect(data.text, text);
      expect(data.html, isNull);
    });

    test('returns an object with both text and html when both are available',
        () async {
      text = 'hello there';
      html = '<h1>hello there</h1>';
      final data = await RichClipboard.getData();
      expect(data.text, text);
      expect(data.html, html);
    });
  });

  group('setData', () {
    test('sets just plain text if no html is included', () async {
      const data = RichClipboardData(text: 'hello there');
      await RichClipboard.setData(data);
      expect(text, data.text);
      expect(html, isNull);
    });

    test('sets plain text and html if both are provided', () async {
      const data = RichClipboardData(
        text: 'hello there',
        html: '<h1>hello there</h1>',
      );
      await RichClipboard.setData(data);
      expect(text, data.text);
      expect(html, data.html);
    });

    test('calls the platform method even if the data is empty', () async {
      text = '';
      html = '';
      await RichClipboard.setData(const RichClipboardData());
      expect(text, isNull);
      expect(html, isNull);
    });
  });
}
