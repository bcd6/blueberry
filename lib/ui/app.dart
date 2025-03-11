import 'package:blueberry/state/app_state.dart';
import 'package:blueberry/ui/album_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

class App extends StatelessWidget {
  const App({super.key});

  Future<void> _initializeApp(BuildContext context) async {
    final appState = context.read<AppState>();
    await appState.loadConfig();
    await appState.scanAlbums();
    // if (kReleaseMode) {
    //   appState.shuffleAlbums();
    // }
  }

  @override
  Widget build(BuildContext context) {
    setWindowMinSize(const Size(1920, 1080));

    return MaterialApp(
      title: 'blueberry',
      home: FutureBuilder(
        future: _initializeApp(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(),
            );
          }

          return const AlbumList();
        },
      ),
      theme: ThemeData(
        textTheme: GoogleFonts.inconsolataTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 0),
      ),
    );
  }
}
