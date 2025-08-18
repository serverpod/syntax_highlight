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
import 'package:flutter/material.dart';
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

            return TextField(
              readOnly: widget.readOnly,
              scrollPadding: EdgeInsets.zero,
              scrollController: _codeScrollController,
              style: widget.textStyle,
              controller: widget.controller,
              maxLines: null,
              expands: true,
              decoration: null,
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
