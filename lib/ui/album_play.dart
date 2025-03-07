import 'dart:async';
import 'dart:io';
import 'package:blueberry/domain/loop_mode.dart';
import 'package:blueberry/domain/playlist.dart';
import 'package:blueberry/service/audio_service.dart';
import 'package:flutter/material.dart';
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
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _durationSubscription;

  int? _currentTrackIndex;
  int? _currentPlaylistIndex;
  bool _isPlaying = false;
  bool _loading = true;
  double _volume = _defaultVolume;
  Duration _currentPosition = Duration.zero;
  // ignore: unused_field
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _loadPlaylists();
  }

  void _initializeAudio() {
    _audioService.setVolume(_volume);
    _setupSubscriptions();
    _audioService.onTrackComplete = _onTrackComplete;
  }

  void _setupSubscriptions() {
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (_currentTrackIndex != null && mounted) {
        final currentTrack =
            _playlists[_currentPlaylistIndex!].tracks[_currentTrackIndex!];
        // Adjust position relative to track start
        final adjustedPosition = position - currentTrack.startOffset;
        if (adjustedPosition > Duration.zero) {
          setState(() => _currentPosition = adjustedPosition);
        }
      }
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration);
      }
    });
  }

  void _onTrackComplete(bool wasLooped) {
    if (!wasLooped && mounted) {
      _handleTrackComplete();
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);
    _playlists = List.from(widget.album.playlists);

    if (widget.album.cueFiles.isNotEmpty) {
      final cuePlaylists = await widget.album.loadCuePlaylists();
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
          await _audioService.resume();
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

        await _audioService.playFile(track.path, startFrom: track.startOffset);
        setState(() {
          _currentPlaylistIndex = playlistIndex;
          _currentTrackIndex = trackIndex;
          _isPlaying = true;
          _currentPosition = Duration.zero;
          _totalDuration = track.duration ?? Duration.zero;
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

  String _getAlbumTitle() {
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
                        fit: BoxFit.contain,
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
                        const Icon(
                          Icons.volume_up,
                          color: Colors.white54,
                          size: 24,
                        ),
                        Expanded(
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
                        const SizedBox(width: 16),
                        _buildLoopButton(),
                      ],
                    ),
                  ),
                  const Spacer(), // Push the custom buttons to bottom
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
                    const SizedBox(height: 32),
                    Text(
                      _getAlbumTitle(),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _playlists.length,
                        itemBuilder: (context, playlistIndex) {
                          final playlist = _playlists[playlistIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   playlist.name,
                              //   style: Theme.of(context).textTheme.titleLarge
                              //       ?.copyWith(color: Colors.white54),
                              // ),
                              // const SizedBox(height: 8),
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
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    if (_isPlaying) _audioService.stop();
    _audioService.dispose();
    super.dispose();
  }
}
