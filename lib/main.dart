import 'package:blueberry/album/album_state.dart';
import 'package:blueberry/config/config_state.dart';
import 'package:blueberry/lyric/lyric_state.dart';
import 'package:blueberry/player/player_state.dart';
import 'package:blueberry/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  MetadataGod.initialize();
  // debugPaintSizeEnabled = true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConfigState()),
        ChangeNotifierProvider(
          create: (context) => AlbumState(context.read<ConfigState>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PlayerState(context.read<ConfigState>()),
        ),
        ChangeNotifierProvider(create: (context) => LyricState()),
      ],
      child: Phoenix(child: App()),
    ),
  );
}
