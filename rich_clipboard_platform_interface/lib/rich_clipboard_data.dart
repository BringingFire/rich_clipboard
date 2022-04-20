import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _kTextPlain = 'text/plain';
const _kTextHtml = 'text/html';

/// Data from the system clipboard.
@immutable
class RichClipboardData implements ClipboardData {
  const RichClipboardData({this.text, this.html});
  RichClipboardData.fromMap(Map<String, String?> map)
      : this(
          text: map[_kTextPlain],
          html: map[_kTextHtml],
        );

  @override
  final String? text;

  /// HTML variant of this clipboard data.
  final String? html;

  /// Convert this object to a map of MIME types to strings.
  ///
  /// This is primarily a convenience method for passing [RichClipboardData]
  /// instances across a Flutter [MethodChannel].
  Map<String, String?> toMap() => {
        _kTextPlain: text,
        _kTextHtml: html,
      };

  @override
  String toString() => 'RichClipboardData{ text: $text, html: $html }';

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is RichClipboardData &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          html == other.html;

  @override
  int get hashCode => text.hashCode ^ html.hashCode;
}
