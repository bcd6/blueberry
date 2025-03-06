import 'package:blueberry/state/app_state.dart';
import 'package:blueberry/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: Phoenix(child: App()),
    ),
  );
}
