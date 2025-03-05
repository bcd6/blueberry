import 'package:blueberry/state/app_state.dart';
import 'package:blueberry/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.loadConfig();

  runApp(
    ChangeNotifierProvider(
      create: (context) => appState,
      child: Phoenix(child: App()),
    ),
  );
}
