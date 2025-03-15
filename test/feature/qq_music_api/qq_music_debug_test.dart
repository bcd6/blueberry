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
      print(result);
      expect(result, isNotNull);
    });

    test('Get Lyric Test', () async {
      // First search for a song to get its songMid
      final searchResult = await qqMusic.searchMusic(
        'Rock over Japan Arb',
        SearchType.song,
      );
      final songMid =
          searchResult['req_1']['data']['body']['song']['list'][1]['mid'];

      final lyricResult = await qqMusic.getLyric(songMid);
      print('\nLyric Result:');
      print(lyricResult);
      expect(lyricResult, isNotNull);
    });

    test('Get Song Link Test', () async {
      // Use the same song from search
      final searchResult = await qqMusic.searchMusic(
        'Rock over Japan Arb',
        SearchType.song,
      );
      final songMid =
          searchResult['req_1']['data']['song']['list'][0]['songmid'];

      final songLink = await qqMusic.getSongLink(songMid);
      print('\nSong Link:');
      print(songLink);
      expect(songLink, isNotEmpty);
    });

    test('Get Verbatim Lyric Test', () async {
      final searchResult = await qqMusic.searchMusic(
        'Rock over Japan Arb',
        SearchType.song,
      );
      final songId =
          searchResult['req_1']['data']['body']['song']['list'][0]['mid'];

      final verbatimLyric = await qqMusic.getVerbatimLyric(songId);
      print('\nVerbatim Lyric:');
      print(verbatimLyric);
      expect(verbatimLyric, isNotNull);
    });
  });
}
