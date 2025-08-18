import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

late final Highlighter _dartLightHighlighter;
late final Highlighter _dartDarkHighlighter;

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

  // Load the default dark theme and create a highlighter.
  var darkTheme = await HighlighterTheme.loadDarkTheme();
  _dartDarkHighlighter = Highlighter(
    language: 'dart',
    theme: darkTheme,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _brightness = Brightness.dark;

  void _setBrightness(Brightness brightness) {
    setState(() {
      _brightness = brightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syntax Highlight Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: _brightness,
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(
        brightness: _brightness,
        onSetBrightness: _setBrightness,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Brightness brightness;
  final void Function(Brightness) onSetBrightness;

  const MyHomePage({
    Key? key,
    required this.brightness,
    required this.onSetBrightness,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CodeEditor(
              textStyle: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.3,
              ),
              controller: CodeEditorController(
                  lightHighlighter: _dartLightHighlighter,
                  darkHighlighter: _dartDarkHighlighter),
            ),
          ),
          const Divider(
            height: 1,
          ),
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: Icon(
                  widget.brightness == Brightness.light
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  widget.onSetBrightness(
                    widget.brightness == Brightness.light
                        ? Brightness.dark
                        : Brightness.light,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
