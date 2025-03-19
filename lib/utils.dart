import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:media_kit/ffi/ffi.dart';
import 'package:win32/win32.dart';

class Utils {
  static final DynamicLibrary _shlwapi = DynamicLibrary.open('shlwapi.dll');
  static final _strCmpLogicalW = _shlwapi.lookupFunction<
    Int32 Function(Pointer<Utf16>, Pointer<Utf16>),
    int Function(Pointer<Utf16>, Pointer<Utf16>)
  >('StrCmpLogicalW');

  static int windowsExplorerSort(String a, String b) {
    final pA = a.toNativeUtf16();
    final pB = b.toNativeUtf16();
    try {
      return _strCmpLogicalW(pA, pB);
    } finally {
      free(pA);
      free(pB);
    }
  }

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
