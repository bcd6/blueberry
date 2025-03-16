import 'package:blueberry/album/album_state.dart';
import 'package:blueberry/config/config_state.dart';
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

  final configState = ConfigState();
  final albumState = AlbumState(configState);
  final playerState = PlayerState(configState);

  configState.init().then((_) {
    albumState.init();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfigState>.value(value: configState),
        ChangeNotifierProvider<AlbumState>.value(value: albumState),
        ChangeNotifierProvider<PlayerState>.value(value: playerState),
      ],
      child: Phoenix(child: App()),
    ),
  );
}
