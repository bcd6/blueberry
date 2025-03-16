import 'dart:async';
import 'dart:io';
import 'package:blueberry/lyric/lyric_state.dart';
import 'package:blueberry/player/player_state.dart';
import 'package:blueberry/lyric/lyric_loader.dart';
import 'package:blueberry/qq_music_api/qq_music_service.dart';
import 'package:blueberry/ui/lyric_viewer.dart';
import 'package:blueberry/player/audio_player.dart';
import 'package:blueberry/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum LoopMode { track, playlist }

class AlbumPlay extends StatefulWidget {
  const AlbumPlay({super.key});

  @override
  State<AlbumPlay> createState() => _AlbumPlayState();
}

class _AlbumPlayState extends State<AlbumPlay> {
  static const double _goldenRatio = 1.618;
  static const double _defaultVolume = 0.6;

  final _audioPlayer = AudioPlayer();
  final _qqMusicService = QQMusicService();

  late PlayerState _playerState;
  late LyricState _lyricState;
  StreamSubscription? _currentPositionSubscription;
  double _volume = _defaultVolume;
  LoopMode _loopMode = LoopMode.playlist;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final leftPanelWidth = screenWidth / (1 + _goldenRatio);

    return GestureDetector(
      onSecondaryTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Row(
          children: [
            // Left panel with album art and info
            Container(
              width: leftPanelWidth,
              color: Colors.black87,
              child: Column(
                children: [
                  // Album Cover with Consumer
                  Container(
                    padding: const EdgeInsets.all(32),
                    width: leftPanelWidth,
                    height: leftPanelWidth,
                    child: Consumer<PlayerState>(
                      builder: (context, playerState, child) {
                        return GestureDetector(
                          onTap:
                              () => Utils.openInExplorerByFile(
                                playerState.currentAlbum.coverFilePath,
                              ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: SizedBox(
                              key: ValueKey(
                                playerState.currentTrack?.albumCoverPath ??
                                    playerState.currentAlbum.coverFilePath,
                              ),
                              width: leftPanelWidth - 64,
                              height: leftPanelWidth - 64,
                              child: Image.file(
                                File(
                                  playerState.currentTrack?.albumCoverPath ??
                                      playerState.currentAlbum.coverFilePath,
                                ),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Player controls with Consumer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Consumer<PlayerState>(
                      builder: (context, playerState, child) {
                        return Row(
                          children: [
                            _buildLyricsSourceButton(),
                            const SizedBox(width: 16),
                            // Volume control
                            const Icon(
                              Icons.volume_up,
                              color: Colors.white54,
                              size: 24,
                            ),
                            SizedBox(
                              width: leftPanelWidth * 0.2,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  trackHeight: 2.0,
                                ),
                                child: Slider(
                                  value: _volume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: _onVolumeChanged,
                                ),
                              ),
                            ),
                            // Position control with time
                            Text(
                              _formatDuration(playerState.currentPosition),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.blue,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.blue,
                                  trackHeight: 2.0,
                                ),
                                child: Slider(
                                  value:
                                      playerState.currentPosition.inMilliseconds
                                          .toDouble(),
                                  min: 0,
                                  max:
                                      playerState
                                          .currentTrack
                                          ?.duration
                                          ?.inMilliseconds
                                          .toDouble() ??
                                      0,
                                  onChanged: _onPositionChanged,
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(
                                playerState.currentTrack?.duration ??
                                    Duration.zero,
                              ),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildLoopButton(),
                          ],
                        );
                      },
                    ),
                  ),
                  // Lyrics UI with Consumer
                  Consumer<PlayerState>(
                    builder: (context, playerState, child) {
                      return _getLyricUI();
                    },
                  ),
                ],
              ),
            ),
            // Right panel with tracklist
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album title with Consumer
                    Consumer<PlayerState>(
                      builder: (context, playerState, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _getAlbumTitleUI(),
                        );
                      },
                    ),
                    // Playlist with Consumer (already implemented)
                    Expanded(
                      child: Consumer<PlayerState>(
                        builder: (context, playerState, child) {
                          return ListView.builder(
                            itemCount: playerState.currentAlbumPlaylists.length,
                            itemBuilder: (context, playlistIndex) {
                              final playlist =
                                  playerState
                                      .currentAlbumPlaylists[playlistIndex];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  playerState.currentAlbumPlaylists.length > 1
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: 24,
                                          bottom: 16,
                                        ),
                                        child: Text(
                                          playlist.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(color: Colors.white54),
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                                  ...playlist.tracks.asMap().entries.map((
                                    entry,
                                  ) {
                                    final trackIndex = entry.key;
                                    final track = entry.value;
                                    final isCurrentTrack =
                                        playerState.currentPlaylistIndex ==
                                            playlistIndex &&
                                        playerState.currentTrackIndex ==
                                            trackIndex;

                                    return ListTile(
                                      leading:
                                          isCurrentTrack
                                              ? SizedBox(
                                                width: 10,
                                                height: 10,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color:
                                                        isCurrentTrack
                                                            ? Colors.blue
                                                            : Colors.white54,
                                                    value:
                                                        (isCurrentTrack &&
                                                                playerState
                                                                    .currentTrackPlaying)
                                                            ? null
                                                            : 1,
                                                  ),
                                                ),
                                              )
                                              : Text(
                                                (trackIndex + 1).toString(),
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                      title: Text(
                                        track.title,
                                        style: TextStyle(
                                          color:
                                              isCurrentTrack
                                                  ? Colors.blue
                                                  : Colors.white,
                                        ),
                                      ),
                                      trailing: Text(
                                        isCurrentTrack
                                            ? '${_formatDuration(playerState.currentPosition)}/${_formatDuration(track.duration ?? Duration.zero)}'
                                            : _formatDuration(
                                              track.duration ?? Duration.zero,
                                            ),
                                        style: TextStyle(
                                          color:
                                              isCurrentTrack
                                                  ? Colors.blue
                                                  : Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap:
                                          () => _playTrack(
                                            playlistIndex,
                                            trackIndex,
                                            true,
                                          ),
                                    );
                                  }),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPositionSubscription?.cancel();
    if (_playerState.currentTrackPlaying) {
      _audioPlayer.stop();
    }
    _audioPlayer.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerState.resetCurrent();
    });

    super.dispose();
  }

  void _init() {
    _playerState = context.read<PlayerState>();
    _lyricState = context.read<LyricState>();
    _audioPlayer.setVolume(_volume);
  }

  void _onVolumeChanged(double value) {
    setState(() => _volume = value);
    _audioPlayer.setVolume(value);
  }

  Future<void> _playTrack(
    int playlistIndex,
    int trackIndex,
    bool byClick,
  ) async {
    if (!mounted) return; // Add early return if widget is disposed
    final track =
        _playerState.currentAlbumPlaylists[playlistIndex].tracks[trackIndex];
    final isSameTrack =
        _playerState.currentPlaylistIndex == playlistIndex &&
        _playerState.currentTrackIndex == trackIndex;

    debugPrint('\n=== Play Track Request ===');
    debugPrint('Playlist: $playlistIndex, Track: $trackIndex');
    debugPrint('isSameTrack: $isSameTrack');

    try {
      if (isSameTrack) {
        if (!mounted) return;

        if (_playerState.currentTrackPlaying) {
          if (_playerState.currentAlbumPlaylists[playlistIndex].tracks.length ==
                  1 &&
              !byClick) {
            await _audioPlayer.seek(track.startOffset);
            if (mounted) {
              _playerState.setPosition(Duration.zero);
            }
          } else {
            await _audioPlayer.pause();
            _playerState.setPlaying(false);
          }
        } else {
          debugPrint('Resuming current track');
          await _audioPlayer.play();
          _playerState.setPlaying(true);
        }
      } else {
        await _audioPlayer.stop();
        debugPrint('Stopping current playback');
        debugPrint('Switching to new track...');
        debugPrint('Starting new track: ${track.title}');
        debugPrint('File path: ${track.path}');
        debugPrint('Start offset: ${track.startOffset}');
        debugPrint(
          'Current position: ${_playerState.currentPosition.inSeconds}',
        );

        final currentPositionStream = _audioPlayer.currentTrackDurationStream(
          _audioPlayer.positionStream,
          track.startOffset,
        );

        await _currentPositionSubscription?.cancel();
        _currentPositionSubscription = currentPositionStream.listen((
          position,
        ) async {
          if (position > Duration.zero) {
            _playerState.setPosition(position);
          }

          // Handle track completion
          if (track.duration! > Duration.zero &&
              track.duration!.inMilliseconds - position.inMilliseconds < 200) {
            debugPrint(
              'Track completed currentTrack.duration: ${track.duration!.inMilliseconds}',
            );
            debugPrint(
              'Track completed adjustedPosition: ${position.inMilliseconds}',
            );
            debugPrint('Track completed');
            if (_loopMode == LoopMode.track) {
              await _audioPlayer.seek(track.startOffset);
              await _audioPlayer.play();
            }
            if (_loopMode != LoopMode.track && mounted) {
              _handleTrackComplete();
            }
          }
        });

        await _audioPlayer.playFile(track.path, startFrom: track.startOffset);
        _playerState.startNewCurrent(
          playlistIndex,
          trackIndex,
          track,
          Duration.zero,
          currentPositionStream,
          true,
        );

        debugPrint('New track started successfully');
      }
    } catch (e) {
      debugPrint('Error playing track: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
    debugPrint('=== Play Track Request Complete ===\n');
  }

  void _handleTrackComplete() {
    if (_playerState.currentPlaylistIndex == null ||
        _playerState.currentTrackIndex == null) {
      return;
    }

    final playlist =
        _playerState.currentAlbumPlaylists[_playerState.currentPlaylistIndex!];
    final nextTrackIndex = _playerState.currentTrackIndex! + 1;

    if (nextTrackIndex < playlist.tracks.length) {
      _playTrack(_playerState.currentPlaylistIndex!, nextTrackIndex, false);
    } else if (_loopMode == LoopMode.playlist) {
      _playTrack(_playerState.currentPlaylistIndex!, 0, false);
    }
  }

  Widget _getLyricUI() {
    if (_playerState.currentTrack == null) return const SizedBox.shrink();

    return LyricViewer();
  }

  List<Widget> _getAlbumTitleUI() {
    if (_playerState.currentAlbumPlaylists.length > 1) {
      return [
        const SizedBox(height: 32),
        Text(
          _getAlbumTitle(),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: 32),
      Text(
        _getAlbumTitle(),
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  String _getAlbumTitle() {
    if (_playerState.currentAlbumPlaylists.length > 1) {
      return _playerState.currentAlbum.folderName;
    }

    try {
      final firstTrackAlbum =
          _playerState.currentAlbumPlaylists[0].tracks[0].album;
      if (firstTrackAlbum?.isNotEmpty == true) return firstTrackAlbum!;

      final playlistName = _playerState.currentAlbumPlaylists[0].name;
      if (playlistName.isNotEmpty) return playlistName;

      return _playerState.currentAlbum.folderName;
    } catch (_) {
      return _playerState.currentAlbum.folderName;
    }
  }

  Widget _buildLoopButton() {
    final (icon, tooltip) = switch (_loopMode) {
      LoopMode.track => (Icons.repeat_one, 'Loop Track'),
      LoopMode.playlist => (Icons.repeat, 'Loop Playlist'),
    };

    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () async {
        await _toggleLoopMode();
        setState(() {}); // Trigger rebuild to update icon
      },
      tooltip: tooltip,
    );
  }

  Widget _buildFavButton() {
    final isTrackSelected = _playerState.currentTrack != null;

    return IconButton(
      icon: Icon(
        Icons.favorite,
        color: isTrackSelected ? Colors.white : Colors.white24,
      ),
      onPressed:
          isTrackSelected
              ? () {
                debugPrint(
                  'Add to favorites: ${_playerState.currentTrack!.title}',
                );
              }
              : null,
      tooltip: 'Add to Favorites',
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _onPositionChanged(double value) async {
    if (_playerState.currentTrackIndex != null &&
        _playerState.currentPlaylistIndex != null) {
      final track =
          _playerState
              .currentAlbumPlaylists[_playerState.currentPlaylistIndex!]
              .tracks[_playerState.currentTrackIndex!];
      final newPosition = Duration(milliseconds: value.toInt());
      await _audioPlayer.seek(track.startOffset + newPosition);
      _playerState.setPosition(newPosition);
    }
  }

  // Add this method to _AlbumPlayState class
  Future<void> _showLyricsSourceModal() async {
    final keyword =
        '${_playerState.currentTrack?.title}  ${_playerState.currentTrack?.performer}';
    final search = await _qqMusicService.searchMusic(keyword, SearchType.song);
    final songs =
        search['req_1']['data']['body']['song']['list'] as List<dynamic>;

    // debugPrint('Search Result:');
    // debugPrint(songs.toString());
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
                    children: [..._buildLyricsSource(songs)],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildLyricsSource(List<dynamic> songs) {
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
        onTap: () {
          _selectLyricsSource(songId);
        },
      );
    }).toList();
  }

  Future<void> _selectLyricsSource(songId) async {
    if (_playerState.currentTrack == null) {
      Navigator.pop(context);
    }
    final result = await LyricLoader.reloadLocalLyric(
      _playerState.currentTrack!.path,
      _playerState.currentTrack!.title,
      songId,
    );

    if (result) {
      _lyricState.load(_playerState.currentTrack!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // Add a button to open the modal
  Widget _buildLyricsSourceButton() {
    return IconButton(
      icon: Icon(
        Icons.lyrics,
        color:
            _playerState.currentTrack != null ? Colors.white : Colors.white24,
      ),
      onPressed:
          _playerState.currentTrack != null ? _showLyricsSourceModal : null,
      tooltip: 'Reload Lyrics',
    );
  }

  Future<void> _toggleLoopMode() async {
    final modes = [LoopMode.track, LoopMode.playlist];
    final currentIndex = modes.indexOf(_loopMode);
    _loopMode = modes[(currentIndex + 1) % modes.length];
    debugPrint('Loop mode set to: $_loopMode');
  }
}
