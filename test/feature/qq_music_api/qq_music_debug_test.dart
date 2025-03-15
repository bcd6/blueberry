import 'package:flutter_test/flutter_test.dart';
import 'package:blueberry/feature/qq_music_api/qq_music_service.dart';

void main() {
  final qqMusic = QQMusicService();

  group('QQ Music API Debug Tests', () {
    test('Search Music Test', () async {
      final result = await qqMusic.searchMusic(
        'Rock over Japan Arb', // Test with a known song
        SearchType.song,
      );
      print('\nSearch Result:');
      // print(result);
      expect(result, isNotNull);
    });

    test('Get Verbatim Lyric Test', () async {
      // final searchResult = await qqMusic.searchMusic('Angel', SearchType.song);
      // final songId =
      //     searchResult['req_1']['data']['body']['song']['list'][1]['mid'];

      final songId = '1403288'; // Test with a known song
      final verbatimLyric = await qqMusic.getVerbatimLyric(songId);
      print(verbatimLyric.code.toString());
      print(verbatimLyric.lyric.toString());
      expect(verbatimLyric, isNotNull);
    });
  });
}
