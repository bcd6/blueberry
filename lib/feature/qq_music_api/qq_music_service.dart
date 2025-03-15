import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'models/lyric_result.dart';

enum SearchType { song, album, playlist }

class QQMusicService {
  static const String _cookie =
      'pgv_pvid=5853446373; _qimei_q36=; _qimei_h38=f5f13a7ef1bd3f832354f83a0200000f017c13; qq_domain_video_guid_verify=e2289668199e59d9; fqm_pvqid=5abd1388-37bd-4edc-8c66-b73c982d9762; eas_sid=HgW2zOoQghXSUzt4pfEPn3eZpQ; pac_uid=0_E9csXFtSj8ffR; _qimei_fingerprint=b3d6ca140562d227c5dbd2d80cc2c8e4; _qimei_uuid42=1910b130530100347f4f296e15a7d836d39e0ddee0; fqm_sessionid=9b8ad51a-0fcb-43ce-b78c-0ac70df1e8c0; pgv_info=ssid=s9688118829; ts_refer=www.reddit.com/; ts_uid=353491493; _qpsvr_localtk=0.35841386714100687; RK=2JXNVHj+ff; ptcz=ff50c8cf1bf54fc5c760b1bea074d35c49ca5d919c7301b685c1823e4548daa5; login_type=1; qqmusic_key=Q_H_L_63k3N6yKLKttE2dEX4bC-zwWNt6V8rGkoGwUWG0q1uUx6KtJ3xXS_-QnPzfTL7-tczCEdkYff9RCy8TSo6Zll-A; tmeLoginType=2; psrf_musickey_createtime=1742007842; psrf_qqunionid=54157EDC14EA8FE203C14E7686C0C5BC; wxopenid=; psrf_qqopenid=77A764D8AF510E47B07070C6069C6AFE; psrf_access_token_expiresAt=1747191842; euin=oici7iEPoe-P; psrf_qqaccess_token=E405A13110C01576602FE25DA9F93FAA; wxunionid=; psrf_qqrefresh_token=F705F2F98830A6B5B25C35FFB6D5B269; music_ignore_pskey=202306271436Hn@vBj; wxrefresh_token=; qm_keyst=Q_H_L_63k3N6yKLKttE2dEX4bC-zwWNt6V8rGkoGwUWG0q1uUx6KtJ3xXS_-QnPzfTL7-tczCEdkYff9RCy8TSo6Zll-A; uin=383794024; ts_last=y.qq.com/n/ryqq/singer/004AFVlB2ZPQpj';
  QQMusicService();

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

      debugPrint('Running lyric extractor: $exePath $songId $_cookie');

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
    // debugPrint('Response: $responseBody');

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
