import 'dart:async';
import 'dart:io';
import 'package:blueberry/player/loop_mode.dart';
import 'package:blueberry/player/player_state.dart';
import 'package:blueberry/player/playlist.dart';
import 'package:blueberry/player/track.dart';
import 'package:blueberry/feature/lyric/lyric_loader.dart';
import 'package:blueberry/feature/qq_music_api/qq_music_service.dart';
import 'package:blueberry/state/fav_state.dart';
import 'package:blueberry/ui/lyric_viewer.dart';
import 'package:blueberry/player/audio_player.dart';
import 'package:blueberry/state/app_state.dart';
import 'package:blueberry/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../album/album.dart';

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
  StreamSubscription? _currentPositionSubscription;
  double _volume = _defaultVolume;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate left panel width based on screen width
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
              width: leftPanelWidth, // Updated width
              color: Colors.black87,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    width: leftPanelWidth,
                    height: leftPanelWidth, // Keep square aspect ratio
                    child: GestureDetector(
                      onTap:
                          () => Utils.openInExplorerByFile(
                            _playerState.currentAlbum.coverFilePath,
                          ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          key: ValueKey(
                            _playerState.currentTrack?.albumCoverPath ??
                                _playerState.currentAlbum.coverFilePath,
                          ),
                          width: leftPanelWidth - 64, // Account for padding
                          height: leftPanelWidth - 64,
                          child: Image.file(
                            File(
                              _playerState.currentTrack?.albumCoverPath ??
                                  _playerState.currentAlbum.coverFilePath,
                            ),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Player controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        // Add lyrics source button before volume control
                        _buildLyricsSourceButton(),
                        const SizedBox(width: 16),
                        // Volume control
                        const Icon(
                          Icons.volume_up,
                          color: Colors.white54,
                          size: 24,
                        ),
                        SizedBox(
                          width: leftPanelWidth * 0.2, // 20% of panel width
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
                        // Position control
                        ...[
                          Text(
                            _formatDuration(_playerState.currentPosition),
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
                                    _playerState.currentPosition.inMilliseconds
                                        .toDouble(),
                                min: 0,
                                max:
                                    _playerState
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
                              _playerState.currentTrack?.duration ??
                                  Duration.zero,
                            ),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(width: 16),
                        _buildLoopButton(),
                        // _playerState.currentTrack != null
                        //     ? IconButton(
                        //       icon: Icon(
                        //         Icons.favorite,
                        //         color:
                        //             context.watch<FavState>().isFavorite(
                        //                   _playerState.currentTrack!,
                        //                 )
                        //                 ? Colors.red
                        //                 : Colors.white24,
                        //       ),
                        //       onPressed:
                        //           () => context.read<FavState>().toggleFavorite(
                        //             _playerState.currentTrack!,
                        //           ),
                        //     )
                        //     : _buildFavButton(),
                      ],
                    ),
                  ),
                  _getLyricUI(),
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
                    ..._getAlbumTitleUI(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _playerState.currentAlbumPlaylists.length,
                        itemBuilder: (context, playlistIndex) {
                          final playlist =
                              _playerState.currentAlbumPlaylists[playlistIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _playerState.currentAlbumPlaylists.length > 1
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
                              ...playlist.tracks.asMap().entries.map((entry) {
                                final trackIndex = entry.key;
                                final track = entry.value;
                                final isCurrentTrack =
                                    _playerState.currentPlaylistIndex ==
                                        playlistIndex &&
                                    _playerState.currentTrackIndex ==
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
                                                            _playerState
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
                                        ? '${_formatDuration(_playerState.currentPosition)}/${_formatDuration(track.duration ?? Duration.zero)}'
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
    if (_playerState.currentTrackPlaying) _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _init() {
    _playerState = context.read<PlayerState>();
    _playerState.setPosition(Duration.zero);
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
            if (_audioPlayer.isLoopingTrack) {
              await _audioPlayer.seek(track.startOffset);
              await _audioPlayer.play();
            }
            if (!_audioPlayer.isLoopingTrack && mounted) {
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
    } else if (_audioPlayer.isLoopingPlaylist) {
      _playTrack(_playerState.currentPlaylistIndex!, 0, false);
    }
  }

  Widget _getLyricUI() {
    if (_playerState.currentTrack == null) return const SizedBox.shrink();

    return LyricViewer(
      track: _playerState.currentTrack!,
      currentPositionStream: _playerState.currentPositionStream!,
    );
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
    final (icon, tooltip) = switch (_audioPlayer.loopMode) {
      LoopMode.track => (Icons.repeat_one, 'Loop Track'),
      LoopMode.playlist => (Icons.repeat, 'Loop Playlist'),
    };

    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () async {
        await _audioPlayer.toggleLoopMode();
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
    final result = await LyricLoader.reloadLocalLyric(
      _playerState.currentTrack?.path ?? '',
      _playerState.currentTrack?.title ?? '',
      songId,
    );

    if (result) {
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
}
