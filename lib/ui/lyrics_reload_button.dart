import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blueberry/player/player_state.dart';
import 'package:blueberry/lyric/lyric_state.dart';
import 'package:blueberry/lyric/lyric_loader.dart';
import 'package:blueberry/qq_music_api/qq_music_service.dart';
import 'package:blueberry/config/config_state.dart';

class LyricsReloadButton extends StatelessWidget {
  const LyricsReloadButton({super.key});

  @override
  Widget build(BuildContext context) {
    final playerState = context.watch<PlayerState>();

    return IconButton(
      icon: Icon(
        Icons.lyrics,
        color: playerState.currentTrack != null ? Colors.white : Colors.white24,
      ),
      onPressed:
          playerState.currentTrack != null
              ? () => _showLyricsSourceModal(context)
              : null,
      tooltip: 'Reload Lyrics',
    );
  }

  Future<void> _showLyricsSourceModal(BuildContext context) async {
    final playerState = context.read<PlayerState>();
    final lyricState = context.read<LyricState>();
    final configState = context.read<ConfigState>();
    final qqMusicService = QQMusicService(
      configState.config.qqMusicCookie ?? '',
    );

    final keyword =
        '${playerState.currentTrack?.title} ${playerState.currentTrack?.performer}';
    final search = await qqMusicService.searchMusic(keyword, SearchType.song);
    final songs =
        search['req_1']['data']['body']['song']['list'] as List<dynamic>;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Songs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ..._buildLyricsSource(
                        context,
                        songs,
                        playerState,
                        lyricState,
                        qqMusicService,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildLyricsSource(
    BuildContext context,
    List<dynamic> songs,
    PlayerState playerState,
    LyricState lyricState,
    QQMusicService qqMusicService,
  ) {
    return songs.map((song) {
      final songId = song['id'].toString();
      final title = song['title'].toString();
      final album = song['album']['title'].toString();
      final singer = (song['singer'] as List<dynamic>)
          .map((s) => s['title'].toString())
          .join(', ');

      return ListTile(
        title: Text(
          '$title - $album - $singer',
          style: const TextStyle(color: Colors.white),
        ),
        onTap:
            () => _selectLyricsSource(
              context,
              songId,
              playerState,
              lyricState,
              qqMusicService,
            ),
      );
    }).toList();
  }

  Future<void> _selectLyricsSource(
    BuildContext context,
    String songId,
    PlayerState playerState,
    LyricState lyricState,
    QQMusicService qqMusicService,
  ) async {
    if (playerState.currentTrack == null) {
      Navigator.pop(context);
      return;
    }

    final result = await LyricLoader.reloadLocalLyric(
      playerState.currentTrack!.path,
      playerState.currentTrack!.title,
      songId,
      qqMusicService,
    );

    if (!context.mounted) return;

    if (result) {
      await lyricState.load(playerState.currentTrack!);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No lyrics found.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
