import 'package:blueberry/album/album_state.dart';
import 'package:blueberry/config/config_state.dart';
import 'package:blueberry/fav/fav_state.dart';
import 'package:blueberry/ui/album_list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

class App extends StatelessWidget {
  const App({super.key});

  Future<void> _initializeApp(BuildContext context) async {
    final configState = context.read<ConfigState>();
    final albumState = context.read<AlbumState>();
    final favState = context.read<FavState>();
    await configState.init();
    await albumState.init();
    await favState.init();
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
