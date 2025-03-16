import 'dart:convert';
import 'dart:io';
import 'package:blueberry/config/config.dart';
import 'package:flutter/foundation.dart';

class ConfigState extends ChangeNotifier {
  late Config _config;
  final String _configFilePathDefault = r'D:\~\album\~.json';

  Config get config => _config;

  Future<void> init() async {
    try {
      final file = File(_configFilePathDefault);
      _config =
          await file.exists()
              ? Config.fromJson(json.decode(await file.readAsString()))
              : defaultConfig();
      debugPrint('Config loaded: ${json.encode(_config.toJson())}');
    } catch (e) {
      debugPrint('Error loading config: $e');
      _config = defaultConfig();
    }
    notifyListeners();
  }

  Config defaultConfig() {
    return Config(folders: [], coverFileName: '', favFilePath: '');
  }
}
