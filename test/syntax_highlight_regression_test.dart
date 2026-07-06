import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntax_highlight/src/highlighter.dart';
import 'package:syntax_highlight/src/span_parser.dart';

void main() {
  group('SpanParser regressions', () {
    test('null pattern lists are treated as empty pattern lists', () {
      final grammar = Grammar.fromJson({
        'name': 'Null patterns grammar',
        'scopeName': 'source.test',
        'patterns': null,
      });

      expect(SpanParser.parse(grammar, 'plain text'), isEmpty);
    });

    test('capture offsets use the actual capture group location', () {
      final grammar = Grammar.fromJson({
        'name': 'Repeated capture grammar',
        'scopeName': 'source.test',
        'patterns': [
          {
            'match': r'(foo).*?(foo)',
            'captures': {
              '1': {'name': 'entity.first'},
              '2': {'name': 'entity.second'},
            },
          },
        ],
      });

      final spans = SpanParser.parse(grammar, 'foo bar foo');

      expect(
        spans,
        contains(
          isA<ScopeSpan>()
              .having((span) => span.start, 'start', 8)
              .having((span) => span.end, 'end', 11)
              .having((span) => span.scopes, 'scopes', ['entity.second']),
        ),
      );
    });
  });

  group('HighlighterTheme regressions', () {
    test('most specific matching scope wins during fallback lookup', () {
      final theme = HighlighterTheme.fromConfiguration(
        '''
        {
          "settings": [
            {
              "scope": "keyword",
              "settings": {"foreground": "#ff0000"}
            },
            {
              "scope": "keyword.control",
              "settings": {"foreground": "#00ff00"}
            }
          ]
        }
        ''',
        const TextStyle(color: Colors.black),
      );
      Highlighter.addLanguage(
        'specific-scope-test',
        '''
        {
          "name": "Specific scope test",
          "scopeName": "source.test",
          "patterns": [
            {
              "name": "keyword.control.test",
              "match": "word"
            }
          ]
        }
        ''',
      );

      final span = Highlighter(
        language: 'specific-scope-test',
        theme: theme,
      ).highlight('word');
      final styledSpan = span.children!.single as TextSpan;

      expect(styledSpan.style!.color, const Color(0xFF00ff00));
    });

    test('fontStyle can combine bold italic and underline flags', () {
      final theme = HighlighterTheme.fromConfiguration(
        '''
        {
          "settings": [
            {
              "scope": "keyword.control.test",
              "settings": {
                "foreground": "#112233",
                "fontStyle": "bold italic underline"
              }
            }
          ]
        }
        ''',
        const TextStyle(color: Colors.black),
      );
      Highlighter.addLanguage(
        'combined-font-style-test',
        '''
        {
          "name": "Combined font style test",
          "scopeName": "source.test",
          "patterns": [
            {
              "name": "keyword.control.test",
              "match": "word"
            }
          ]
        }
        ''',
      );

      final span = Highlighter(
        language: 'combined-font-style-test',
        theme: theme,
      ).highlight('word');
      final styledSpan = span.children!.single as TextSpan;

      expect(styledSpan.style!.color, const Color(0xFF112233));
      expect(styledSpan.style!.fontWeight, FontWeight.bold);
      expect(styledSpan.style!.fontStyle, FontStyle.italic);
      expect(styledSpan.style!.decoration, TextDecoration.underline);
    });
  });

  group('Highlighter regressions', () {
    test('balanced unscoped brackets are highlighted without failure style', () {
      final theme = HighlighterTheme.fromConfiguration(
        '{"settings": []}',
        const TextStyle(color: Colors.black),
      );
      Highlighter.addLanguage(
        'bracket-balance-test',
        '''
        {
          "name": "Bracket balance test",
          "scopeName": "source.test",
          "patterns": []
        }
        ''',
      );

      final span = Highlighter(
        language: 'bracket-balance-test',
        theme: theme,
      ).highlight('({[]})');
      final bracketContainer = span.children!.single as TextSpan;
      final bracketSpans = bracketContainer.children!.cast<TextSpan>();

      expect(bracketSpans.map((span) => span.text).join(), '({[]})');
      expect(
        bracketSpans.map((span) => span.style?.color),
        isNot(contains(const Color(0xFFFF0000))),
      );
    });

    test('unknown languages fail with a deliberate unsupported error', () {
      final theme = HighlighterTheme.fromConfiguration(
        '{"settings": []}',
        const TextStyle(color: Colors.black),
      );

      expect(
        () => Highlighter(language: 'missing-language-test', theme: theme),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
