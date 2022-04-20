# rich_clipboard_platform_interface

A common platform interface for the [`rich_clipboard`][1] plugin.

This interface allows platform-specific implementations of the `rich_clipboard`
plugin, as well as the plugin itself, to ensure they are supporting the same
interface.

## Usage

To implement a new platform-specific implementation of `rich_clipboard`, extend
`RichClipboardPlatform`[2] with an implementation that performs the
platform-specific behavior. Within your class, be sure to implement the static
function `registerWith` to register the plugin. See the implementation in
[`rich_clipboard_windows`][3] for an example.

If you're platform implementation is entirely in native code that will be called
over a platform channel, you can use the default
[`MethodChannelRichClipboard`][4] to register the method channel. See the
implementation in [`rich_clipboard_macos`][5] for an example.

[1]: ../rich_clipboard
[2]: lib/rich_clipboard_platform_interface.dart
[3]: ../rich_clipboard_windows
[4]: lib/src/method_channel_rich_clipboard.dart
[5]: ../rich_clipboard_macos