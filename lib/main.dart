import 'package:blueberry/state/app_state.dart';
import 'package:blueberry/state/fav_state.dart';
import 'package:blueberry/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:media_kit/media_kit.dart';
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
        ChangeNotifierProvider(create: (_) => FavState()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Phoenix(child: App()),
    ),
  );
}
