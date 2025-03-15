import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

// DLL function signatures
typedef NativeDDes = Int32 Function(Pointer<Uint8>, Pointer<Utf8>, Int32);
typedef DartDDes = int Function(Pointer<Uint8>, Pointer<Utf8>, int);

class QQMusicService {
  static final _dllPath = path.join(
    Directory.current.path,
    r'assets\dlls\QQMusicVerbatim.dll',
  );
  static const String _baseUrl = 'https://c.y.qq.com';
  static final DateTime _epoch = DateTime(1970, 1, 1, 8, 0, 0);

  late final DynamicLibrary _dll;
  late final DartDDes _funcDDes;
  late final DartDDes _funcDes;

  QQMusicService() {
    try {
      _dll = DynamicLibrary.open(_dllPath);
      _funcDDes = _dll.lookupFunction<NativeDDes, DartDDes>('Ddes');
      _funcDes = _dll.lookupFunction<NativeDDes, DartDDes>('des');
    } catch (e) {
      debugPrint('Failed to load QQ Music DLL: $e');
    }
  }

  void _processMusicData(Pointer<Uint8> data, int length) {
    // Allocate memory for keys
    final key1 = r'!@#)(NHLiuy*$%^&'.toNativeUtf8();
    final key2 = r'123ZXC!@#)(*$%^&'.toNativeUtf8();
    final key3 = r'!@#)(*$%^&abcDEF'.toNativeUtf8();

    try {
      _funcDDes(data, key1, length);
      _funcDes(data, key2, length);
      _funcDDes(data, key3, length);
    } finally {
      // Free allocated memory
      calloc.free(key1);
      calloc.free(key2);
      calloc.free(key3);
    }
  }

  Future<Map<String, dynamic>> processLyricContent(String hexContent) async {
    try {
      // Convert hex string to bytes
      final List<int> bytes = [];
      for (int i = 0; i < hexContent.length; i += 2) {
        bytes.add(int.parse(hexContent.substring(i, i + 2), radix: 16));
      }

      // Allocate native memory
      final dataLength = bytes.length;
      final nativeData = calloc<Uint8>(dataLength);

      // Copy data to native memory
      for (int i = 0; i < dataLength; i++) {
        nativeData[i] = bytes[i];
      }

      // Process the data
      _processMusicData(nativeData, dataLength);

      // Copy processed data back
      final processedBytes = List<int>.generate(
        dataLength,
        (i) => nativeData[i],
      );

      // Free native memory
      calloc.free(nativeData);

      // Convert processed bytes to string
      final decodedContent = utf8.decode(processedBytes);

      return {'lyrics': decodedContent};
    } catch (e) {
      debugPrint('Error processing lyric content: $e');
      return {'error': e.toString()};
    }
  }

  static const Map<String, String> _xmlMappingDict = {
    'content': 'orig', // Original
    'contentts': 'ts', // Translation
    'contentroma': 'roma', // Romaji
    'Lyric_1': 'lyric', // Decompressed content
  };

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

  Future<Map<String, dynamic>> getLyric(String songMid) async {
    final currentMillis = DateTime.now().difference(_epoch).inMilliseconds;
    const callback = 'MusicJsonCallback_lrc';

    final data = {
      'callback': callback,
      'pcachetime': currentMillis.toString(),
      'songmid': songMid,
      'g_tk': '5381',
      'jsonpCallback': callback,
      'loginUin': '0',
      'hostUin': '0',
      'format': 'jsonp',
      'inCharset': 'utf8',
      'outCharset': 'utf8',
      'notice': '0',
      'platform': 'yqq',
      'needNewCode': '0',
    };

    final response = await _post(
      '/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
      data,
    );
    return _parseJsonpResponse(callback, response);
  }

  Future<Map<String, dynamic>> getVerbatimLyric(String songId) async {
    final response = await _post('/qqmusic/fcgi-bin/lyric_download.fcg', {
      'version': '15',
      'miniversion': '82',
      'lrctype': '4',
      'musicid': songId,
    });

    // Remove XML comments
    final cleanXml = response.replaceAll('<!--', '').replaceAll('-->', '');

    // Process XML and decrypt content
    // TODO: Implement XML processing and decryption
    return {'lyrics': cleanXml};
  }

  Future<String> getSongLink(String songMid) async {
    final guid = _generateGuid();

    final data = {
      'req': {
        'method': 'GetCdnDispatch',
        'module': 'CDN.SrfCdnDispatchServer',
        'param': {'guid': guid, 'calltype': '0', 'userip': ''},
      },
      'req_0': {
        'method': 'CgiGetVkey',
        'module': 'vkey.GetVkeyServer',
        'param': {
          'guid': '8348972662',
          'songmid': [songMid],
          'songtype': [1],
          'uin': '0',
          'loginflag': 1,
          'platform': '20',
        },
      },
      'comm': {'uin': 0, 'format': 'json', 'ct': 24, 'cv': 0},
    };

    final response = await _postJson(
      'https://u.y.qq.com/cgi-bin/musicu.fcg',
      data,
    );
    return _extractSongLink(response);
  }

  // Helper methods
  Future<dynamic> _get(String endpoint, Map<String, String> params) async {
    final uri = Uri.parse(
      '$_baseUrl$endpoint',
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: _getHeaders());
    return utf8.decode(response.bodyBytes);
  }

  Future<dynamic> _post(String endpoint, Map<String, String> data) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http.post(
      uri,
      headers: {
        ..._getHeaders(),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: data,
    );
    return utf8.decode(response.bodyBytes);
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

    'Cookie':
        'pgv_pvid=5853446373; _qimei_q36=; _qimei_h38=f5f13a7ef1bd3f832354f83a0200000f017c13; qq_domain_video_guid_verify=e2289668199e59d9; fqm_pvqid=5abd1388-37bd-4edc-8c66-b73c982d9762; eas_sid=HgW2zOoQghXSUzt4pfEPn3eZpQ; pac_uid=0_E9csXFtSj8ffR; _qimei_fingerprint=b3d6ca140562d227c5dbd2d80cc2c8e4; _qimei_uuid42=1910b130530100347f4f296e15a7d836d39e0ddee0; fqm_sessionid=9b8ad51a-0fcb-43ce-b78c-0ac70df1e8c0; pgv_info=ssid=s9688118829; ts_refer=www.reddit.com/; ts_uid=353491493; _qpsvr_localtk=0.35841386714100687; RK=2JXNVHj+ff; ptcz=ff50c8cf1bf54fc5c760b1bea074d35c49ca5d919c7301b685c1823e4548daa5; login_type=1; qqmusic_key=Q_H_L_63k3N6yKLKttE2dEX4bC-zwWNt6V8rGkoGwUWG0q1uUx6KtJ3xXS_-QnPzfTL7-tczCEdkYff9RCy8TSo6Zll-A; tmeLoginType=2; psrf_musickey_createtime=1742007842; psrf_qqunionid=54157EDC14EA8FE203C14E7686C0C5BC; wxopenid=; psrf_qqopenid=77A764D8AF510E47B07070C6069C6AFE; psrf_access_token_expiresAt=1747191842; euin=oici7iEPoe-P; psrf_qqaccess_token=E405A13110C01576602FE25DA9F93FAA; wxunionid=; psrf_qqrefresh_token=F705F2F98830A6B5B25C35FFB6D5B269; music_ignore_pskey=202306271436Hn@vBj; wxrefresh_token=; qm_keyst=Q_H_L_63k3N6yKLKttE2dEX4bC-zwWNt6V8rGkoGwUWG0q1uUx6KtJ3xXS_-QnPzfTL7-tczCEdkYff9RCy8TSo6Zll-A; uin=383794024; ts_last=y.qq.com/n/ryqq/singer/004AFVlB2ZPQpj',
  };

  String _generateGuid() {
    final random = Random();
    final buffer = StringBuffer();
    for (var i = 0; i < 10; i++) {
      buffer.write(random.nextInt(10));
    }
    return buffer.toString();
  }

  Map<String, dynamic> _parseJsonpResponse(String callback, String response) {
    if (!response.startsWith(callback)) return {};

    final jsonStr = response
        .replaceFirst('$callback(', '')
        .substring(0, response.length - callback.length - 2);

    return jsonDecode(jsonStr);
  }

  String _extractSongLink(Map<String, dynamic> response) {
    try {
      final sip = response['req']['data']['sip'][0];
      final purl = response['req_0']['data']['midurlinfo'][0]['purl'];
      return '$sip$purl';
    } catch (e) {
      return '';
    }
  }

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

enum SearchType { song, album, playlist }

// Add this at the top of the file with other imports
void debugPrint(String message) {
  debugPrint('[QQMusic] $message');
}
