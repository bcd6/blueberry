import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:win32/win32.dart';

class Utils {
  static final DynamicLibrary _shlwapi = DynamicLibrary.open('shlwapi.dll');
  static final _strCmpLogicalW = _shlwapi.lookupFunction<
    Int32 Function(Pointer<Utf16>, Pointer<Utf16>),
    int Function(Pointer<Utf16>, Pointer<Utf16>)
  >('StrCmpLogicalW');

  static void preventScreenSleep() {
    SetThreadExecutionState(
      ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED,
    );
  }

  static void resetScreenSleep() {
    SetThreadExecutionState(ES_CONTINUOUS); // Reset to default behavior
  }

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

    // Use Win32 API to handle paths with special characters like commas
    final pathPtr = path.toNativeUtf16();
    final operationPtr = 'open'.toNativeUtf16();

    try {
      ShellExecute(
        NULL,
        operationPtr,
        pathPtr,
        nullptr,
        nullptr,
        SW_SHOWNORMAL,
      );
    } finally {
      free(pathPtr);
      free(operationPtr);
    }
  }

  static Future<void> openInExplorerByFile(String filePath) async {
    var path = File(filePath).parent.path;
    await openInExplorer(path);
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
