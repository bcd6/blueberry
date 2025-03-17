import 'dart:convert';
import 'dart:io';
import 'package:blueberry/config/config.dart';
import 'package:blueberry/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ConfigState extends ChangeNotifier {
  late Config _config;
  final String _configFilePathDefault = r'D:\~\album\~.json';

  Config get config => _config;

  Future<void> init() async {
    try {
      final file1 = File(_configFilePathDefault);
      final c1 = await file1.exists();

      if (!c1) {
        final d2 = Directory(_getConfigPath());
        if (!await d2.exists()) {
          await d2.create();
        }
        final file2 = File(path.join(_getConfigPath(), '~.json'));
        final c2 = await file2.exists();
        if (!c2) {
          _config = _defaultConfig();
          await file2.writeAsString(json.encode(_config.toJson()));
          Utils.openInExplorerByFile(file2.path);
        } else {
          _config = Config.fromJson(json.decode(await file2.readAsString()));
        }
      } else {
        _config = Config.fromJson(json.decode(await file1.readAsString()));
      }
      debugPrint('Config loaded: ${json.encode(_config.toJson())}');
    } catch (e) {
      debugPrint('Error loading config: $e');
      _config = _defaultConfig();
    }
    notifyListeners();
  }

  String _getConfigPath() {
    String appDataPath = Platform.environment['APPDATA'] ?? "";
    return path.join(appDataPath, 'blueberry');
  }

  Config _defaultConfig() {
    return Config(
      folders: [],
      coverFileName: 'folder.jpg',
      favFilePath: path.join(_getConfigPath(), '~fav.json'),
      qqMusicCookie: '',
    );
  }
}
