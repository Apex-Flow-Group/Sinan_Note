import 'package:meta/meta.dart';

import 'clipboard/quill_clipboard_config.dart';

export 'clipboard/quill_clipboard_config.dart';

/// Offset a collapsed caret at [caret] in [text] moves to.
typedef CaretResolver = int Function(String text, int caret);

class QuillControllerConfig {
  const QuillControllerConfig({
    this.requireScriptFontFeatures = false,
    @experimental this.clipboardConfig,
    this.caretResolver,
  });

  /// Where a collapsed caret may sit: given the text around it and its
  /// offset in that text, returns the offset to use. Scripts with combining
  /// marks use it to keep the caret off the gap between a letter and its
  /// marks, so typing there does not take the mark. Null keeps every offset.
  final CaretResolver? caretResolver;

  @experimental
  final QuillClipboardConfig? clipboardConfig;

  /// Render subscript and superscript text using Open Type FontFeatures
  ///
  /// Default is false to use built-in script rendering that is independent of font capabilities
  final bool requireScriptFontFeatures;
}
