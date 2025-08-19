/// A code editor widget that provides syntax highlighting and line numbers.
///
/// This widget creates a text editor with the following features:
/// * Line numbers in a gutter on the left side.
/// * Syntax highlighting for supported languages.
/// * Automatic line wrapping.
/// * Optional read-only mode.
///
/// The editor consists of two main parts:
/// 1. A line number gutter that automatically updates as text changes.
/// 2. The main text editing area with syntax highlighting.
import 'dart:convert';
import 'dart:math' as math;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

/// Width of the line number gutter in logical pixels
const _gutterWidth = 40.0;

/// Margin between the gutter and main text area in logical pixels
const _gutterMargin = 8.0;

/// A code editor widget with syntax highlighting and line numbers.
class CodeEditor extends StatefulWidget {
  /// Creates a code editor widget.
  ///
  /// The [textStyle] parameter defines the base text style for the editor content.
  /// The [controller] parameter manages the text content and syntax highlighting.
  /// Set [readOnly] to true to prevent editing of the content.
  const CodeEditor({
    required this.textStyle,
    required this.controller,
    this.readOnly = false,
    super.key,
  });

  /// The base text style for the editor content.
  final TextStyle textStyle;

  /// Controller that manages the text content and syntax highlighting.
  final CodeEditorController controller;

  /// Whether the editor content can be modified.
  ///
  /// When true, the editor becomes read-only and user input is ignored.
  final bool readOnly;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final _lineNumberController = TextEditingController();
  double? _codeFieldWidth;
  final _codeScrollController = ScrollController();
  final _lineNumberScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      _lineNumberController.text = _computeLineNumbers();
    });

    _codeScrollController.addListener(() {
      _lineNumberScrollController.jumpTo(_codeScrollController.offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Key combos for all platforms
    final combos = <LogicalKeySet>{
      LogicalKeySet(
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.keyC,
      ), // macOS/web on Mac
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.keyC,
      ), // Windows/Linux/web on PC
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: _gutterWidth - _gutterMargin,
          padding: const EdgeInsets.only(right: 4.0),
          margin: const EdgeInsets.only(right: _gutterMargin),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: IgnorePointer(
            child: ScrollConfiguration(
              behavior: const _HiddenHandleScrollBehavior(),
              child: TextField(
                scrollController: _lineNumberScrollController,
                readOnly: true,
                scrollPadding: EdgeInsets.zero,
                style: widget.textStyle.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
                controller: _lineNumberController,
                textAlign: TextAlign.right,
                maxLines: null,
                expands: true,
                decoration: null,
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            var codeFieldWidth = constraints.maxWidth;
            if (codeFieldWidth != _codeFieldWidth) {
              _codeFieldWidth = codeFieldWidth;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _lineNumberController.text = _computeLineNumbers();
              });
            }

            return Shortcuts(
              shortcuts: {
                for (final c in combos) c: const _CopyIntent(),
                LogicalKeySet(LogicalKeyboardKey.tab): const _TabIntent(),
                LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
                    const _ShiftTabIntent(),
              },
              child: Actions(
                actions: {
                  _CopyIntent: _CopyAction(widget.controller, context),
                  _TabIntent: _TabAction(widget.controller),
                  _ShiftTabIntent: _ShiftTabAction(widget.controller),
                },
                child: TextField(
                  readOnly: widget.readOnly,
                  scrollPadding: EdgeInsets.zero,
                  scrollController: _codeScrollController,
                  style: widget.textStyle,
                  controller: widget.controller,
                  maxLines: null,
                  expands: true,
                  decoration: null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _computeLineNumbers() {
    if (_codeFieldWidth == null) {
      return '';
    }

    var text = widget.controller.text;
    var textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: widget.textStyle,
      ),
    );
    textPainter.layout(
      maxWidth: _codeFieldWidth!,
    );

    var lineNumberText = '';
    var lineNumber = 1;
    var wroteLineNumber = false;
    var metrics = textPainter.computeLineMetrics();

    for (var metric in metrics) {
      if (!wroteLineNumber) {
        lineNumberText += '$lineNumber\n';
        lineNumber += 1;
        wroteLineNumber = true;
      } else {
        lineNumberText += '\n';
      }

      if (metric.hardBreak) {
        wroteLineNumber = false;
      }
    }

    if (lineNumberText.isEmpty) {
      lineNumberText = '1';
    }

    return lineNumberText;
  }
}

/// A specialized [TextEditingController] that provides syntax highlighting.
///
/// This controller extends the standard text editing controller to add
/// language-specific syntax highlighting to the text content.
class CodeEditorController extends TextEditingController {
  /// Creates a code editor controller.
  ///
  /// The [text] parameter sets the initial text content.
  /// The [language] parameter specifies the programming language for syntax highlighting.
  /// Defaults to 'dart' if not specified.
  CodeEditorController({
    super.text,
    required this.lightHighlighter,
    required this.darkHighlighter,
  });

  /// The highlighter instance used in light theme mode.
  final Highlighter lightHighlighter;

  /// The highlighter instance used in dark theme mode.
  final Highlighter darkHighlighter;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    var highlighted = Theme.of(context).brightness == Brightness.light
        ? lightHighlighter.highlight(text)
        : darkHighlighter.highlight(text);

    return TextSpan(
      style: style,
      children: [highlighted],
    );
  }
}

/// A custom scroll behavior that hides the scrollbar.
///
/// This is used for the line number gutter to ensure it matches
/// the main text area's scrolling without showing its own scrollbar.
class _HiddenHandleScrollBehavior extends ScrollBehavior {
  const _HiddenHandleScrollBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _CopyAction extends Action<_CopyIntent> {
  _CopyAction(
    this._textEditingController,
    this._context,
  );

  final TextEditingController _textEditingController;
  final BuildContext _context;

  @override
  Object? invoke(_CopyIntent intent) {
    final html = _getSelectedTextAsHtml(_textEditingController, _context);

    // TODO: Use the HTML output for clipboard or other purposes
    // For now, just copy the plain text
    final text = _textEditingController.selection
        .textInside(_textEditingController.text);

    if (text.isNotEmpty) {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem();
        item.add(Formats.plainText(text));
        if (html.isNotEmpty) {
          final wrappedHtml =
              "<meta charset='utf-8'><meta charset=\"utf-8\"><b style=\"font-weight:normal;\"><span style=\"font-size:12pt;font-family:'JetBrains Mono',monospace;color:#c6f7ff;background-color:transparent;font-weight:700;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;\">$html</span></b>";
          item.add(Formats.htmlText(wrappedHtml));
        }
        clipboard.write([item]);
      } else {
        Clipboard.setData(ClipboardData(text: text));
      }
    }
    return null;
  }
}

class _CopyIntent extends Intent {
  const _CopyIntent();
}

class _TabAction extends Action<_TabIntent> {
  _TabAction(
    this._textEditingController,
  );

  final TextEditingController _textEditingController;

  @override
  Object? invoke(_TabIntent intent) {
    final selection = _textEditingController.selection;
    final text = _textEditingController.text;

    if (selection.isCollapsed) {
      // Single cursor - insert 2 spaces
      final newText = text.substring(0, selection.start) +
          '  ' +
          text.substring(selection.end);
      _textEditingController.text = newText;
      _textEditingController.selection = TextSelection.collapsed(
        offset: selection.start + 2,
      );
    } else {
      // Multi-line selection - indent each line from the beginning
      final start = selection.start;
      final end = selection.end;

      // Find the start of the first line that contains selection
      int lineStart = start;
      while (lineStart > 0 && text[lineStart - 1] != '\n') {
        lineStart--;
      }

      // Find the end of the last line that contains selection
      int lineEnd = end;
      while (lineEnd < text.length && text[lineEnd] != '\n') {
        lineEnd++;
      }

      // Get the text from the start of first line to end of last line
      final fullLineText = text.substring(lineStart, lineEnd);
      final lines = fullLineText.split('\n');
      final indentedLines = lines.map((line) => '  $line').join('\n');

      final newText = text.substring(0, lineStart) +
          indentedLines +
          text.substring(lineEnd);
      _textEditingController.text = newText;

      // Maintain selection but adjust for added spaces and line boundaries
      final addedSpaces = lines.length * 2;
      final startOffset = start - lineStart;
      final endOffset = end - lineStart;

      _textEditingController.selection = TextSelection(
        baseOffset: lineStart + startOffset + (start == lineStart ? 2 : 0),
        extentOffset: lineStart + endOffset + addedSpaces,
      );
    }
    return null;
  }
}

class _TabIntent extends Intent {
  const _TabIntent();
}

class _ShiftTabAction extends Action<_ShiftTabIntent> {
  _ShiftTabAction(
    this._textEditingController,
  );

  final TextEditingController _textEditingController;

  @override
  Object? invoke(_ShiftTabIntent intent) {
    final selection = _textEditingController.selection;
    final text = _textEditingController.text;

    if (selection.isCollapsed) {
      // Single cursor - insert 2 spaces
      final newText = text.substring(0, selection.start) +
          '  ' +
          text.substring(selection.end);
      _textEditingController.text = newText;
      _textEditingController.selection = TextSelection.collapsed(
        offset: selection.start + 2,
      );
    } else {
      // Multi-line selection - unindent each line by 2 spaces
      final start = selection.start;
      final end = selection.end;

      // Find the start of the first line that contains selection
      int lineStart = start;
      while (lineStart > 0 && text[lineStart - 1] != '\n') {
        lineStart--;
      }

      // Find the end of the last line that contains selection
      int lineEnd = end;
      while (lineEnd < text.length && text[lineEnd] != '\n') {
        lineEnd++;
      }

      // Get the text from the start of first line to end of last line
      final fullLineText = text.substring(lineStart, lineEnd);
      final lines = fullLineText.split('\n');
      final unindentedLines = lines.map((line) {
        if (line.startsWith('  ')) {
          return line.substring(2);
        }
        return line;
      }).join('\n');

      final newText = text.substring(0, lineStart) +
          unindentedLines +
          text.substring(lineEnd);
      _textEditingController.text = newText;

      // Calculate how many spaces were removed
      int removedSpaces = 0;
      for (final line in lines) {
        if (line.startsWith('  ')) {
          removedSpaces += 2;
        }
      }

      // Maintain selection but adjust for removed spaces and line boundaries
      final startOffset = start - lineStart;
      final endOffset = end - lineStart;

      _textEditingController.selection = TextSelection(
        baseOffset: lineStart + startOffset,
        extentOffset: lineStart + endOffset - removedSpaces,
      );
    }
    return null;
  }
}

class _ShiftTabIntent extends Intent {
  const _ShiftTabIntent();
}

/// Converts the selected text range to HTML, preserving syntax highlighting colors.
///
/// This function requires a BuildContext to properly build the text span with styling.
/// Returns an empty string if no text is selected or if the selection is invalid.
String _getSelectedTextAsHtml(
    TextEditingController controller, BuildContext context) {
  // Get the current selection
  final TextSelection selection = controller.selection;
  if (!selection.isValid || selection.isCollapsed) {
    return '';
  }

  // Get the selected text
  final String selectedText = selection.textInside(controller.text);
  if (selectedText.isEmpty) {
    return '';
  }

  // Get the full text span with styling
  final TextSpan fullTextSpan = controller.buildTextSpan(
    context: context,
    withComposing: false,
  );

  final StringBuffer html = StringBuffer();
  const htmlEscape = HtmlEscape();

  _processTextSpan(fullTextSpan, 0, selection, html, htmlEscape);
  return html.toString();
}

/// Converts a Flutter Color to CSS hex format.
String _colorToCss(Color? color) {
  if (color == null) return 'inherit';
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}

/// Computes the total number of text characters contained in this span,
/// including all descendants. This is used to advance the running
/// position correctly while traversing the tree.
int _textSpanLength(TextSpan span) {
  var length = 0;
  if (span.text != null) {
    length += span.text!.length;
  }
  if (span.children != null) {
    for (final child in span.children!) {
      if (child is TextSpan) {
        length += _textSpanLength(child);
      }
    }
  }
  return length;
}

/// Recursive function to process text spans within the selection range
void _processTextSpan(
  TextSpan span,
  int currentPosition,
  TextSelection selection,
  StringBuffer html,
  HtmlEscape htmlEscape,
) {
  if (span.children != null) {
    for (final child in span.children!) {
      if (child is TextSpan) {
        final childLength = _textSpanLength(child);
        // Recurse into the child; only leaves emit text
        _processTextSpan(child, currentPosition, selection, html, htmlEscape);
        currentPosition += childLength;
      }
    }
  } else if (span.text != null) {
    _processTextSpanContent(span, currentPosition, selection, html, htmlEscape);
  }
}

/// Processes the content of a text span that contains actual text.
void _processTextSpanContent(
  TextSpan span,
  int currentPosition,
  TextSelection selection,
  StringBuffer html,
  HtmlEscape htmlEscape,
) {
  final String text = span.text!;
  final textLength = text.length;

  // Check if this text overlaps with the selection
  if (currentPosition < selection.end &&
      currentPosition + textLength > selection.start) {
    // Calculate the overlap
    final start = math.max(selection.start - currentPosition, 0);
    final end = math.min(selection.end - currentPosition, textLength);

    if (start < end) {
      final overlappingText = text.substring(start, end);
      _writeHtmlText(overlappingText, span.style?.color, html, htmlEscape);
    }
  }
}

/// Writes the text content to HTML with appropriate styling.
void _writeHtmlText(
  String text,
  Color? color,
  StringBuffer html,
  HtmlEscape htmlEscape,
) {
  if (color != null) {
    html.write('<span style="color: ${_colorToCss(color)}">');
    html.write(htmlEscape.convert(text));
    html.write('</span>');
  } else {
    html.write(htmlEscape.convert(text));
  }
}
