# rich_clipboard

[![CI](https://github.com/BringingFire/rich_clipboard/actions/workflows/ci.yml/badge.svg)](https://github.com/BringingFire/rich_clipboard/actions/workflows/ci.yml)
[![Pub Version](https://img.shields.io/pub/v/rich_clipboard)](https://pub.dev/packages/rich_clipboard)

A Flutter plugin providing access to additional data types in the system
clipboard.

## Platform Support

macOS | Windows | Linux | Web             | Android | iOS
:----:|:-------:|:-----:|:---------------:|:-------:|:---:
 ✅   | ✅       | ✅    | ✅ [*](#firefox) | ✅      | ✅

## Unsupported Platforms

  On unsupported platforms this plugin will provide plain text only support
  rather than failing. This is done by transparently calling methods on
  Flutter's built-in [`Clipboard`][1] where appropriate, or returning mock
  empty values where no analogue exists. In these cases some data may be
  silently discarded, such as when attempting to write data types other
  than plain text to the clipboard.

### Firefox

While "web" is currently a supported platform, support for Firefox is currently
not possible due to its incomplete implementation of the [Clipboard API][2].
Because of this, the plugin will degrade to plain text only mode in that
browser. Unfortunately, even that does not work in all cases as Flutter's
built-in clipboard support is also broken due to additional restrictions placed
on the Clipboard API by Firefox. You can find the relevant Flutter bug
[here][3].

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
[2]: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API
[3]: https://github.com/flutter/flutter/issues/48581