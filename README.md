# rich_clipboard

A Flutter plugin providing access to additional data types in the system
clipboard.

## Platform Support

macOS | Windows | Linux | Android | iOS
:----:|:-------:|:-----:|:-------:|:---:
 ✅   | ❌       | ❌     | ❌    | ❌

## Usage

You can use static methods on the `RichClipboard` class to access data
in the system clipboard. The API is similar to that provided by Flutter's
built-in `Clipboard` class.

```dart
import 'package:rich_clipboard/rich_clipboard.dart';
...
final clipboardData = await RichClipboard.getData();
if (clipboardData.html != null) {
  // Do something with HTML
} else if (clipboardData.text != null) {
  // Do something with plain text
}
...

final plainText = 'Hello there';
final html = '<html><body><h1>$plainText</h1></body></html>';
await RichClipboard.setData(RichClipboardData({
  text: plainText,
  html: html,
}));
```