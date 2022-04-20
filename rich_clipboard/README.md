# rich_clipboard

[![CI](https://github.com/BringingFire/rich_clipboard/actions/workflows/ci.yml/badge.svg)](https://github.com/BringingFire/rich_clipboard/actions/workflows/ci.yml)

A Flutter plugin providing access to additional data types in the system
clipboard.

## Warning: Alpha Software

This is an alpha package. The API can and likely will go through some revisions
as support is added for more platforms.

## Platform Support

macOS | Windows | Linux | Android | iOS
:----:|:-------:|:-----:|:-------:|:---:
 ✅   | ✅      | ❌     | ❌    | ❌

## Unsupported Platforms

  On unsupported platforms this plugin will provide plain text only support
  rather that failing. This is done by transparently calling methods on
  Flutter's built-in [`Clipboard`][1] where appropriate, or returning mock
  empty values where no analogue exists. In these cases some data may be
  silently discarded, such as when attempting to write data types other
  than plain text to the clipboard.

## Usage

You can use static methods on the `RichClipboard` class to access data in the
system clipboard. The API is similar to that provided by Flutter's built-in
[`Clipboard`][1] class.

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

[1]: https://api.flutter.dev/flutter/services/Clipboard-class.html