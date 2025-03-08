import 'dart:async';
import 'dart:io';
import 'package:blueberry/domain/loop_mode.dart';
import 'package:blueberry/domain/playlist.dart';
import 'package:blueberry/service/audio_service.dart';
import 'package:blueberry/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:blueberry/ui/lyric_display.dart';
import '../domain/album.dart';

class AlbumPlay extends StatefulWidget {
  final Album album;
  const AlbumPlay({super.key, required this.album});

  @override
  State<AlbumPlay> createState() => _AlbumPlayState();
}

class _AlbumPlayState extends State<AlbumPlay> {
  static const double _goldenRatio = 1.618;
  static const double _defaultVolume = 0.6;

  final _audioService = AudioService();
  late final List<Playlist> _playlists;
  StreamSubscription? _currentPositionSubscription;

  int? _currentTrackIndex;
  int? _currentPlaylistIndex;
  bool _isPlaying = false;
  bool _loading = true;
  double _volume = _defaultVolume;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _loadPlaylists();
  }

  void _initializeAudio() {
    _audioService.setVolume(_volume);
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);
    _playlists = List.from(widget.album.playlists);

    if (widget.album.cueFiles.isNotEmpty) {
      final cuePlaylists = await AppState.loadCuePlaylists(
        widget.album.cueFiles,
      );
      _playlists.addAll(cuePlaylists);
    }

    setState(() => _loading = false);
  }

  void _onVolumeChanged(double value) {
    setState(() => _volume = value);
    _audioService.setVolume(value);
  }

  Future<void> _playTrack(int playlistIndex, int trackIndex) async {
    final track = _playlists[playlistIndex].tracks[trackIndex];
    final isSameTrack =
        _currentPlaylistIndex == playlistIndex &&
        _currentTrackIndex == trackIndex;

    debugPrint('\n=== Play Track Request ===');
    debugPrint('Playlist: $playlistIndex, Track: $trackIndex');
    debugPrint(
      'Current playlist: $_currentPlaylistIndex, Current track: $_currentTrackIndex',
    );
    debugPrint('Is same track: $isSameTrack');
    debugPrint('Is currently playing: $_isPlaying');

    try {
      if (isSameTrack) {
        debugPrint('Handling same track toggle...');
        if (_isPlaying) {
          debugPrint('Pausing current track');
          await _audioService.pause();
          setState(() => _isPlaying = false);
        } else {
          debugPrint('Resuming current track');
          await _audioService.play();
          setState(() => _isPlaying = true);
        }
      } else {
        await _audioService.stop();
        debugPrint('Stopping current playback');
        debugPrint('Switching to new track...');
        debugPrint('Starting new track: ${track.title}');
        debugPrint('File path: ${track.path}');
        debugPrint('Start offset: ${track.startOffset}');
        debugPrint('Current position: ${_currentPosition.inSeconds}');

        await _currentPositionSubscription?.cancel();
        _currentPositionSubscription = _audioService
            .currentTrackDurationStream(
              _audioService.positionStream,
              track.startOffset,
            )
            .listen((position) async {
              // Handle _currentPosition
              if (position > Duration.zero) {
                setState(() => _currentPosition = position);
              }

              // Handle track completion
              if (track.duration! > Duration.zero &&
                  track.duration!.inMilliseconds - position.inMilliseconds <
                      200) {
                debugPrint(
                  'Track completed currentTrack.duration: ${track.duration!.inMilliseconds}',
                );
                debugPrint(
                  'Track completed adjustedPosition: ${position.inMilliseconds}',
                );
                debugPrint('Track completed');
                if (_audioService.isLoopingTrack) {
                  await _audioService.seek(track.startOffset);
                  await _audioService.play();
                }
                if (!_audioService.isLoopingTrack && mounted) {
                  _handleTrackComplete();
                }
              }
            });

        await _audioService.playFile(track.path, startFrom: track.startOffset);
        setState(() {
          _currentPlaylistIndex = playlistIndex;
          _currentTrackIndex = trackIndex;
          _isPlaying = true;
          _currentPosition = Duration.zero;
        });
        debugPrint('New track started successfully');
      }
    } catch (e) {
      debugPrint('Error playing track: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
    debugPrint('=== Play Track Request Complete ===\n');
  }

  void _handleTrackComplete() {
    if (_currentPlaylistIndex == null || _currentTrackIndex == null) return;

    final playlist = _playlists[_currentPlaylistIndex!];
    final nextTrackIndex = _currentTrackIndex! + 1;

    if (nextTrackIndex < playlist.tracks.length) {
      _playTrack(_currentPlaylistIndex!, nextTrackIndex);
    } else if (_audioService.isLoopingPlaylist) {
      _playTrack(_currentPlaylistIndex!, 0);
    }
  }

  List<Widget> _getAlbumTitleUI() {
    if (_playlists.length > 1) {
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
    if (_playlists.length > 1) return widget.album.name;

    try {
      final firstTrackAlbum = _playlists[0].tracks[0].album;
      if (firstTrackAlbum?.isNotEmpty == true) return firstTrackAlbum!;

      final playlistName = _playlists[0].name;
      if (playlistName.isNotEmpty) return playlistName;

      return widget.album.name;
    } catch (_) {
      return widget.album.name;
    }
  }

  Widget _buildLoopButton() {
    final (icon, tooltip) = switch (_audioService.loopMode) {
      LoopMode.track => (Icons.repeat_one, 'Loop Track'),
      LoopMode.playlist => (Icons.repeat, 'Loop Playlist'),
    };

    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: () async {
        await _audioService.toggleLoopMode();
        setState(() {}); // Trigger rebuild to update icon
      },
      tooltip: tooltip,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _openInExplorer(String path) async {
    debugPrint('Opening in explorer: $path');
    await Process.run('explorer', [path]);
  }

  void _onPositionChanged(double value) async {
    if (_currentTrackIndex != null && _currentPlaylistIndex != null) {
      final track =
          _playlists[_currentPlaylistIndex!].tracks[_currentTrackIndex!];
      final newPosition = Duration(milliseconds: value.toInt());
      await _audioService.seek(track.startOffset + newPosition);
      setState(() => _currentPosition = newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
                    height:
                        leftPanelWidth, // Make height equal to width for square container
                    child: GestureDetector(
                      onTap: () => _openInExplorer(widget.album.folderPath),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        child: Image.file(
                          File(widget.album.coverPath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Player controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
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
                          const SizedBox(width: 16),
                          Text(
                            _formatDuration(_currentPosition),
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
                                    _currentPosition.inMilliseconds.toDouble(),
                                min: 0,
                                max:
                                    _currentPlaylistIndex != null &&
                                            _currentTrackIndex != null
                                        ? _playlists[_currentPlaylistIndex!]
                                                .tracks[_currentTrackIndex!]
                                                .duration
                                                ?.inMilliseconds
                                                .toDouble() ??
                                            0
                                        : 0,
                                onChanged: _onPositionChanged,
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(
                              _currentPlaylistIndex != null &&
                                      _currentTrackIndex != null
                                  ? _playlists[_currentPlaylistIndex!]
                                          .tracks[_currentTrackIndex!]
                                          .duration ??
                                      Duration.zero
                                  : Duration.zero,
                            ),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(width: 16),
                        _buildLoopButton(),
                      ],
                    ),
                  ),
                  const LyricDisplay(),
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
                        itemCount: _playlists.length,
                        itemBuilder: (context, playlistIndex) {
                          final playlist = _playlists[playlistIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _playlists.length > 1
                                  ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
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
                                    _currentPlaylistIndex == playlistIndex &&
                                    _currentTrackIndex == trackIndex;

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
                                                            _isPlaying)
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
                                        ? '${_formatDuration(_currentPosition)}/${_formatDuration(track.duration ?? Duration.zero)}'
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
                                      () =>
                                          _playTrack(playlistIndex, trackIndex),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
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
    if (_isPlaying) _audioService.stop();
    _audioService.dispose();
    super.dispose();
  }
}
