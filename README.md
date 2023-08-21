# Syntax Highlight

The Syntax Highlight package uses the TextMate rules for highlighting code, which is used by many popular applications such as VSCode. Currently supported languages are Dart, SQL (Postgres), and YAML, but it is easy to extend the language support by dropping in new grammar files in the `grammar` directory.

## Usage
Before you can use the `Highlighter` class it needs to be initialized. The initialization will load the requested grammar files and parse them.

```dart
// Initialize the highlighter.
await Highlighter.initialize(['dart', 'yaml', 'sql']);
```

Next load a theme and create a highlighter.
```dart
// Load the default light theme and create a highlighter.
var theme = await HighlighterTheme.loadLightTheme();
var highlighter = Highlighter(
  language: 'dart',
  theme: theme,
);
```

Now, you can highlight your code by calling the `highlight` method. The `highlight` method will return a `TextSpan`, which you can use in a `Text` widget.
```dart
Widget build(BuildContext context) {
  var highlightedCode = highlighter.highlight(myCodeString);
  return Text.rich(highlightedCode);
}
```

An example of highlighted code:
![Highlighted code](https://raw.githubusercontent.com/serverpod/syntax_highlight/main/images/screenshot.png
)