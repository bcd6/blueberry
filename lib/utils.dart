import 'dart:io';

import 'package:flutter/foundation.dart';

class Utils {
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
