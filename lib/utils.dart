import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class Utils {
  static String getAssetPath() {
    // In dev mode, use the current directory
    // In release mode, use the data directory next to the exe
    return kDebugMode
        ? path.join(Directory.current.path, 'assets')
        : path.join(
          path.dirname(Platform.resolvedExecutable),
          'data',
          'flutter_assets',
          'assets',
        );
  }

  static Future<void> openInExplorer(String path) async {
    debugPrint('Opening in explorer: $path');
    await Process.run('explorer', [path]);
  }

  static Future<void> openInExplorerByFile(String filePath) async {
    final path = File(filePath).parent.path;
    debugPrint('Opening in explorer: $path');
    await Process.run('explorer', [path]);
  }

  static Future<Duration> getAudioDurationByFF(String filePath) async {
    try {
      ProcessResult result = await Process.run('ffprobe', [
        '-i',
        filePath,
        '-show_entries',
        'format=duration',
        '-v',
        'quiet',
        '-of',
        'csv=p=0',
      ]);
      // debugPrint('Duration result: ${result.stdout}');

      return Duration(
        seconds: double.tryParse(result.stdout.trim())?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('Error getting duration: $e');
      return Duration.zero;
    }
  }
}
