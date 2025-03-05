import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_size/window_size.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    setWindowMinSize(const Size(1920, 1080));

    return MaterialApp(
      title: 'blueberry',
      home: null,
      routes: <String, WidgetBuilder>{},
      theme: ThemeData(
        textTheme: GoogleFonts.inconsolataTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 0),
      ),
    );
  }
}
