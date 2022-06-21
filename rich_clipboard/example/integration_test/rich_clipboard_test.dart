import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

void main() {
  test('getData works with plain text', () async {
    const text = 'Hello there';
    await Clipboard.setData(const ClipboardData(text: text));
    final rcData = await RichClipboard.getData();
    expect(rcData.html, isNull);
    expect(rcData.text, text);
  });

  test('setData works with plain text', () async {
    const text = 'Hello there';
    await RichClipboard.setData(const RichClipboardData(text: text));
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    expect(data, isNotNull);
    expect(data!.text, text);
  });
}
