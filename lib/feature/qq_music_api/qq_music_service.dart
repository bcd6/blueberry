import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';
import 'package:archive/archive.dart';
import 'models/lyric_result.dart';

// DLL function signatures
typedef NativeDDes = Int32 Function(Pointer<Uint8>, Pointer<Utf8>, Int32);
typedef DartDDes = int Function(Pointer<Uint8>, Pointer<Utf8>, int);

enum SearchType { song, album, playlist }

class QQMusicService {
  static const String _baseUrl = 'https://c.y.qq.com';
  // Dictionary for XML mapping
  static const Map<String, String> _xmlMappingDict = {
    'content': 'orig', // Original lyrics
    'contentts': 'ts', // Translation
    'contentroma': 'roma', // Romanization
    'Lyric_1': 'lyric', // Decompressed content
  };
  static final _dllPath = path.join(
    Directory.current.path,
    r'assets\dlls\QQMusicVerbatim.dll',
  );

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
      final response = await _post('/qqmusic/fcgi-bin/lyric_download.fcg', {
        'version': '15',
        'miniversion': '82',
        'lrctype': '4',
        'musicid': songId,
      });
      debugPrint(response);
      // Remove XML comments
      final cleanXml = response
          .replaceAll('<!--', '')
          .replaceAll('-->', '')
          .replaceAll('<miniversion="1" />', '');
      debugPrint(cleanXml);

      // Parse XML and create node dictionary
      final document = XmlDocument.parse(cleanXml);
      final dict = <String, XmlNode>{};
      _findXmlElements(document.rootElement, _xmlMappingDict, dict);

      var result = LyricResult();

      for (final pair in dict.entries) {
        final text = pair.value.innerText;

        if (text.isEmpty) continue;

        // Convert hex string to bytes
        final bytes = _hexStringToBytes(text);
        if (bytes == null) continue;

        // Process bytes through DLL functions
        final processedBytes = await _processLyricBytes(bytes);
        if (processedBytes == null) continue;

        // Decompress and decode
        final decompressedBytes = ZLibDecoder().decodeBytes(processedBytes);
        var decompressText = utf8.decode(decompressedBytes);

        // Handle BOM if present
        if (decompressText.startsWith('\uFEFF')) {
          decompressText = decompressText.substring(1);
        }

        String lyricContent = '';
        if (decompressText.contains('<?xml')) {
          // Parse inner XML
          final innerDoc = XmlDocument.parse(decompressText);
          final subDict = <String, XmlNode>{};
          _findXmlElements(innerDoc.rootElement, _xmlMappingDict, subDict);

          if (subDict.containsKey('lyric')) {
            final lyricNode = subDict['lyric']!;
            lyricContent = lyricNode.getAttribute('LyricContent') ?? '';
          }
        } else {
          lyricContent = decompressText;
        }

        if (lyricContent.isNotEmpty) {
          switch (pair.key) {
            case 'orig':
              result.lyric = _processVerbatimLyric(lyricContent);
              break;
            case 'ts':
              result.trans = _processVerbatimLyric(lyricContent);
              break;
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error getting verbatim lyric: $e');
      return LyricResult(code: -1);
    }
  }

  void _findXmlElements(
    XmlNode node,
    Map<String, String> mappings,
    Map<String, XmlNode> result,
  ) {
    for (final child in node.childElements) {
      final name = child.name.local;
      if (mappings.containsKey(name)) {
        result[mappings[name]!] = child;
      }
      _findXmlElements(child, mappings, result);
    }
  }

  Uint8List? _hexStringToBytes(String hex) {
    try {
      final bytes = <int>[];
      for (var i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Error converting hex string to bytes: $e');
      return null;
    }
  }

  Future<Uint8List?> _processLyricBytes(Uint8List input) async {
    final length = input.length;
    final nativeData = calloc<Uint8>(length);

    try {
      // Copy input to native memory
      for (var i = 0; i < length; i++) {
        nativeData[i] = input[i];
      }

      // Process data
      _processMusicData(nativeData, length);

      // Copy result back
      return Uint8List.fromList(
        List<int>.generate(length, (i) => nativeData[i]),
      );
    } finally {
      calloc.free(nativeData);
    }
  }

  String _processVerbatimLyric(String input) {
    // Add any QQ Music specific lyric processing here
    return input.trim();
  }

  // Helper methods
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
    'Cookie':
        'pgv_pvid=5853446373; _qimei_q36=; _qimei_h38=f5f13a7ef1bd3f832354f83a0200000f017c13; qq_domain_video_guid_verify=e2289668199e59d9; fqm_pvqid=5abd1388-37bd-4edc-8c66-b73c982d9762; eas_sid=HgW2zOoQghXSUzt4pfEPn3eZpQ; pac_uid=0_E9csXFtSj8ffR; _qimei_fingerprint=b3d6ca140562d227c5dbd2d80cc2c8e4; _qimei_uuid42=1910b130530100347f4f296e15a7d836d39e0ddee0; fqm_sessionid=9b8ad51a-0fcb-43ce-b78c-0ac70df1e8c0; pgv_info=ssid=s9688118829; ts_refer=www.reddit.com/; ts_uid=353491493; _qpsvr_localtk=0.35841386714100687; RK=2JXNVHj+ff; ptcz=ff50c8cf1bf54fc5c760b1bea074d35c49ca5d919c7301b685c1823e4548daa5; login_type=1; qqmusic_key=Q_H_L_63k3N6yKLKttE2dEX4bC-zwWNt6V8rGkoGwUWG0q1uUx6KtJ3xXS_-QnPzfTL7-tczCEdkYff9RCy8TSo6Zll-A; tmeLoginType=2; psrf_musickey_createtime=1742007842; psrf_qqunionid=54157EDC14EA8FE203C14E7686C0C5BC; wxopenid=; psrf_qqopenid=77A764D8AF510E47B07070C6069C6AFE; psrf_access_token_expiresAt=1747191842; euin=oici7iEPoe-P; psrf_qqaccess_token=E405A13110C01576602FE25DA9F93FAA; wxunionid=; psrf_qqrefresh_token=F705F2F98830A6B5B25C35FFB6D5B269; music_ignore_pskey=202306271436Hn@vBj; wxrefresh_token=; qm_keyst=Q_H_L_63k3N6yKLKttE2dEX4bC-zwWNt6V8rGkoGwUWG0q1uUx6KtJ3xXS_-QnPzfTL7-tczCEdkYff9RCy8TSo6Zll-A; uin=383794024; ts_last=y.qq.com/n/ryqq/singer/004AFVlB2ZPQpj',
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

void debugPrint(String message) {
  print('[QQMusic] $message');
}
