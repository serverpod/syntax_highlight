import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

// Example code.
const _code = '''class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syntax Highlight Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}''';

const _serverpodYaml = '''
class: Customer
table: customer
fields:
  name: String
  orders: List<Order>?, relation
''';

const _json = '{"name":"John", "age":30, "car":null}';

late final Highlighter _dartLightHighlighter;
late final Highlighter _dartDarkHighlighter;
late final Highlighter _serverpodProtocolLightYamlHighlighter;
late final Highlighter _serverpodProtocolDarkYamlHighlighter;
late final Highlighter _jsonLightHighlighter;
late final Highlighter _jsonDarkHighlighter;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the highlighter.
  await Highlighter.initialize([
    'dart',
    'yaml',
    'sql',
    'serverpod_protocol',
    'json',
  ]);

  // Load the default light theme and create a highlighter.
  var lightTheme = await HighlighterTheme.loadLightTheme();
  _dartLightHighlighter = Highlighter(
    language: 'dart',
    theme: lightTheme,
  );
  _serverpodProtocolLightYamlHighlighter = Highlighter(
    language: 'serverpod_protocol',
    theme: lightTheme,
  );
  _jsonLightHighlighter = Highlighter(
    language: 'json',
    theme: lightTheme,
  );

  // Load the default dark theme and create a highlighter.
  var darkTheme = await HighlighterTheme.loadDarkTheme();
  _dartDarkHighlighter = Highlighter(
    language: 'dart',
    theme: darkTheme,
  );
  _serverpodProtocolDarkYamlHighlighter = Highlighter(
    language: 'serverpod_protocol',
    theme: darkTheme,
  );
  _jsonDarkHighlighter = Highlighter(
    language: 'json',
    theme: darkTheme,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syntax Highlight Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text.rich(
              // Highlight the code.
              _dartLightHighlighter.highlight(_code),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Text.rich(
              // Highlight the code.
              _dartDarkHighlighter.highlight(_code),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text.rich(
              // Highlight the code.
              _serverpodProtocolLightYamlHighlighter.highlight(_serverpodYaml),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Text.rich(
              // Highlight the code.
              _serverpodProtocolDarkYamlHighlighter.highlight(_serverpodYaml),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text.rich(
              // Highlight the code.
              _jsonLightHighlighter.highlight(_json),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Text.rich(
              // Highlight the code.
              _jsonDarkHighlighter.highlight(_json),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
