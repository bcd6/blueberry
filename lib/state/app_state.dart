import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../domain/config.dart';

class AppState extends ChangeNotifier {
  Config? _config;
  static const String configPath = 'D:\\~\\album';
  static const String configFileName = '~.json';

  Config? get config => _config;

  Future<void> loadConfig() async {
    try {
      final filePath = '$configPath\\$configFileName';
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        _config = Config.fromJson(json.decode(jsonString));
      } else {
        // Create default config if file doesn't exist
        _config = Config(folders: []);
      }
      debugPrint('Config loaded: ${json.encode(_config?.toJson())}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading config: $e');
      _config = Config(folders: []);
    }
  }
}
