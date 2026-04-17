import 'package:flutter_test/flutter_test.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HighlighterTheme theme;

  setUpAll(() async {
    await Highlighter.initialize(['typescript', 'swift']);
    theme = await HighlighterTheme.loadLightTheme();
  });

  group('documentation comments', () {
    test('highlights TypeScript doc comments without throwing', () {
      const source = '''
/**
 * @remarks Example
 */
export function answer(): number {
  return 42;
}
''';

      final span = Highlighter(
        language: 'typescript',
        theme: theme,
      ).highlight(source);

      expect(span.toPlainText(), source);
    });

    test('highlights Swift doc comments without throwing', () {
      const source = '''
/**
 * - Returns: Example
 */
func answer() -> Int {
  42
}
''';

      final span = Highlighter(
        language: 'swift',
        theme: theme,
      ).highlight(source);

      expect(span.toPlainText(), source);
    });
  });
}
