import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'models/lyric_result.dart';

enum SearchType { song, album, playlist }

class QQMusicService {
  final String _cookie;

  QQMusicService(this._cookie);

  Future<Map<String, dynamic>> searchMusic(
    String keyword,
    SearchType type,
  ) async {
    final searchTypeNum = _getSearchTypeNumber(type);
    final data = {
      'req_1': {
        'method': 'DoSearchForQQMusicDesktop',
        'module': 'music.search.SearchCgiService',
        'param': {
          'num_per_page': '20',
          'page_num': '1',
          'query': keyword,
          'search_type': searchTypeNum,
        },
      },
    };
    final response = await _postJson(
      'https://u.y.qq.com/cgi-bin/musicu.fcg',
      data,
    );
    return response;
  }

  Future<LyricResult> getVerbatimLyric(String songId) async {
    try {
      debugPrint('Getting verbatim lyric for songId: $songId');

      // Path to the executable - adjust as needed
      final exePath = path.join(
        Directory.current.path,
        'assets',
        'tools',
        'QQMusicApi.exe',
      );

      // Check if executable exists
      if (!File(exePath).existsSync()) {
        debugPrint('Executable not found at: $exePath');
        return LyricResult(code: -1);
      }

      // debugPrint('Running lyric extractor: $exePath $songId $_cookie');

      // Execute the command
      final process = await Process.run(
        exePath,
        [songId, _cookie],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (process.exitCode != 0) {
        debugPrint('Process failed with exit code: ${process.exitCode}');
        debugPrint('Error: ${process.stderr}');
        return LyricResult(code: process.exitCode);
      }

      // Parse the output as JSON
      final output = process.stdout.toString().trim();
      debugPrint(
        'Received output: ${output.substring(0, min(100, output.length))}...',
      );

      try {
        final json = jsonDecode(output);

        return LyricResult(
          code: json['Code'] ?? 0,
          lyric: json['Lyric'] ?? '',
          trans: json['Trans'] ?? '',
        );
      } catch (e) {
        debugPrint('Failed to parse output as JSON: $e');
        return LyricResult(
          code: -2,
          lyric: output, // Include raw output for debugging
        );
      }
    } catch (e, stack) {
      debugPrint('Error getting verbatim lyric: $e');
      debugPrint('Stack trace: $stack');
      return LyricResult(code: -3);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse(url);
    final response = await http.post(
      uri,
      headers: {
        ..._getHeaders(),
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
      );
    }

    // Handle potential JSONP response
    String responseBody = utf8.decode(response.bodyBytes);
    debugPrint('Response: $responseBody');

    if (responseBody.startsWith('callback(')) {
      responseBody = responseBody
          .replaceFirst('callback(', '')
          .replaceFirst(');', '');
    }

    try {
      return jsonDecode(responseBody);
    } catch (e) {
      debugPrint('Failed to decode JSON: $responseBody');
      throw Exception('Invalid JSON response: $e');
    }
  }

  Map<String, String> _getHeaders() => {
    'Referer': 'https://c.y.qq.com/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36',
    'Cookie': _cookie,
  };

  int _getSearchTypeNumber(SearchType type) {
    switch (type) {
      case SearchType.song:
        return 0;
      case SearchType.album:
        return 2;
      case SearchType.playlist:
        return 3;
    }
  }
}
