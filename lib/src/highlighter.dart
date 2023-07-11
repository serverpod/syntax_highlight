import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/src/span_parser.dart';

const _bracketStyles = <TextStyle>[
  TextStyle(color: Color(0xFF5caeef)),
  TextStyle(color: Color(0xFFdfb976)),
  TextStyle(color: Color(0xFFc172d9)),
  TextStyle(color: Color(0xFF4fb1bc)),
  TextStyle(color: Color(0xFF97c26c)),
  TextStyle(color: Color(0xFFabb2c0)),
];

const _failedBracketStyle = TextStyle(color: Color(0xFFff0000));

class Highlighter {
  static final _cache = <String, Grammar>{};

  Highlighter({
    required this.language,
    required this.theme,
  }) {
    grammar = _cache[language]!;
  }

  static Future<void> load(List<String> languages) async {
    for (var language in languages) {
      var json = await rootBundle.loadString(
        'packages/syntax_highlight/grammars/$language.json',
      );
      _cache[language] = Grammar.fromJson(jsonDecode(json));
    }
  }

  final String language;
  late final Grammar grammar;
  final HighlighterTheme theme;

  TextSpan highlight(String code) {
    var spans = SpanParser.parse(grammar, code);
    var textSpans = <TextSpan>[];
    var bracketCounter = 0;

    int charPos = 0;
    for (var span in spans) {
      // Add any text before the span.
      if (span.start > charPos) {
        var text = code.substring(charPos, span.start);
        TextSpan? textSpan;
        (textSpan, bracketCounter) = _formatBrackets(text, bracketCounter);
        textSpans.add(
          textSpan,
        );

        charPos = span.start;
      }

      // Add the span.
      var segment = code.substring(span.start, span.end);
      var style = theme.getStyle(span.scopes);
      textSpans.add(
        TextSpan(
          text: segment,
          style: style,
        ),
      );

      charPos = span.end;
    }

    // Add any text after the last span.
    if (charPos < code.length) {
      var text = code.substring(charPos, code.length);
      TextSpan? textSpan;
      (textSpan, bracketCounter) = _formatBrackets(text, bracketCounter);
      textSpans.add(
        textSpan,
      );
    }

    return TextSpan(children: textSpans);
  }

  (TextSpan, int) _formatBrackets(String text, int bracketCounter) {
    var spans = <TextSpan>[];
    var plainText = '';
    for (var char in text.characters) {
      if (_isStartingBracket(char)) {
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText));
          plainText = '';
        }

        spans.add(TextSpan(
          text: char,
          style: _getBracketStyle(bracketCounter),
        ));
        bracketCounter += 1;
        plainText = '';
      } else if (_isEndingBracket(char)) {
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText));
          plainText = '';
        }

        bracketCounter -= 1;
        spans.add(TextSpan(
          text: char,
          style: _getBracketStyle(bracketCounter),
        ));
        plainText = '';
      } else {
        plainText += char;
      }
    }
    if (plainText.isNotEmpty) {
      spans.add(TextSpan(text: plainText));
    }

    if (spans.length == 1) {
      return (spans[0], bracketCounter);
    } else {
      return (TextSpan(children: spans), bracketCounter);
    }
  }

  TextStyle _getBracketStyle(int bracketCounter) {
    if (bracketCounter < 0) {
      return _failedBracketStyle;
    }
    return _bracketStyles[bracketCounter % _bracketStyles.length];
  }

  bool _isStartingBracket(String bracket) {
    return bracket == '{' || bracket == '[' || bracket == '(';
  }

  bool _isEndingBracket(String bracket) {
    return bracket == '}' || bracket == ']' || bracket == ')';
  }
}

class HighlighterTheme {
  late final TextStyle? fallback;
  final scopes = <String, TextStyle>{};

  Future<void> load(List<String> definitions) async {
    for (var definition in definitions) {
      var json = await rootBundle.loadString(
        'packages/syntax_highlight/themes/$definition.json',
      );
      _parseTheme(json);
    }
  }

  void _parseTheme(String json) {
    var theme = jsonDecode(json);
    List settings = theme['settings'];
    for (Map setting in settings) {
      var style = _parseTextStyle(setting['settings']);

      var scopes = setting['scope'];
      if (scopes is String) {
        _addScope(scopes, style);
      } else if (scopes is List) {
        for (String scope in scopes) {
          _addScope(scope, style);
        }
      } else if (scopes == null) {
        fallback = style;
      }
    }
  }

  TextStyle _parseTextStyle(Map setting) {
    Color? color;
    var foregroundSetting = setting['foreground'];
    if (foregroundSetting is String && foregroundSetting.startsWith('#')) {
      color = Color(
        int.parse(
              foregroundSetting.substring(1),
              radix: 16,
            ) |
            0xFF000000,
      );
    }

    FontStyle? fontStyle;
    FontWeight? fontWeight;
    TextDecoration? textDecoration;

    var fontStyleSetting = setting['fontStyle'];
    if (fontStyleSetting is String) {
      if (fontStyleSetting == 'italic') {
        fontStyle = FontStyle.italic;
      } else if (fontStyleSetting == 'bold') {
        fontWeight = FontWeight.bold;
      } else if (fontStyleSetting == 'underline') {
        textDecoration = TextDecoration.underline;
      } else {
        throw Exception('WARNING unknown style: $fontStyleSetting');
      }
    }

    return TextStyle(
      color: color,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      decoration: textDecoration,
    );
  }

  void _addScope(String scope, TextStyle style) {
    scopes[scope] = style;
  }

  TextStyle? getStyle(List<String> scope) {
    for (var s in scope) {
      var fallbacks = _fallbacks(s);
      for (var f in fallbacks) {
        var style = scopes[f];
        if (style != null) {
          return style;
        }
      }
    }
    return fallback;
  }

  List<String> _fallbacks(String scope) {
    var fallbacks = <String>[];
    var parts = scope.split('.');
    for (var i = 0; i < parts.length; i++) {
      var s = parts.sublist(0, i + 1).join('.');
      fallbacks.add(s);
    }
    return fallbacks.reversed.toList();
  }
}
