import 'dart:async';
import 'dart:io';
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
  final _audioService = AudioService();
  int? _currentTrackIndex;
  bool _isPlaying = false;
  // Update initial volume
  double _volume = 0.6;

  // Add new state variables
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Add StreamSubscription variables
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _durationSubscription;

  // Add playlist tracking
  int? _currentPlaylistIndex;

  late final List<Playlist> _playlists;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Set initial volume
    _audioService.setVolume(_volume);
    // Store stream subscriptions
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (_currentTrackIndex != null && mounted) {
        setState(() => _currentPosition = position);
      }
    });
    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() => _totalDuration = duration);
      }
    });
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);

    // Start with regular playlists
    _playlists = List.from(widget.album.playlists);

    // Load CUE playlists
    if (widget.album.cueFiles.isNotEmpty) {
      final cuePlaylists = await widget.album.loadCuePlaylists();
      _playlists.addAll(cuePlaylists);
    }

    setState(() => _loading = false);
  }

  // Add volume control method
  void _onVolumeChanged(double value) {
    setState(() {
      _volume = value;
    });
    _audioService.setVolume(value);
  }

  @override
  void dispose() async {
    // Cancel stream subscriptions
    await _positionSubscription.cancel();
    await _durationSubscription.cancel();

    // Stop playback
    if (_isPlaying) {
      await _audioService.stop();
    }
    // Dispose audio service
    _audioService.dispose();
    super.dispose();
  }

  void _playTrack(int playlistIndex, int trackIndex) async {
    final track = _playlists[playlistIndex].tracks[trackIndex];

    if (_currentPlaylistIndex == playlistIndex &&
        _currentTrackIndex == trackIndex &&
        _isPlaying) {
      // Pause current track
      await _audioService.pause();
      setState(() {
        _isPlaying = false;
      });
    } else if (_currentPlaylistIndex == playlistIndex &&
        _currentTrackIndex == trackIndex &&
        !_isPlaying) {
      // Resume current track
      await _audioService.resume();
      setState(() {
        _isPlaying = true;
      });
    } else {
      // Play new track
      await _audioService.playFile(track.path, startFrom: track.startOffset);
      setState(() {
        _currentPlaylistIndex = playlistIndex;
        _currentTrackIndex = trackIndex;
        _isPlaying = true;
        _currentPosition = Duration.zero;
        _totalDuration = track.duration ?? Duration.zero;
      });
    }
  }

  // Golden ratio constant
  static const double goldenRatio = 1.618;

  Future<void> _openInExplorer(String path) async {
    await Process.run('explorer', [path]);
  }

  // Add helper method to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Calculate left panel width based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final leftPanelWidth = screenWidth / (1 + goldenRatio);

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
                      widget.album.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _playlists.length,
                        itemBuilder: (context, playlistIndex) {
                          final playlist = _playlists[playlistIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text(
                                playlist.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              ...playlist.tracks.asMap().entries.map((entry) {
                                final trackIndex = entry.key;
                                final track = entry.value;
                                final isCurrentTrack =
                                    _currentPlaylistIndex == playlistIndex &&
                                    _currentTrackIndex == trackIndex;

                                return ListTile(
                                  leading: SizedBox(
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
                                            (isCurrentTrack && _isPlaying)
                                                ? null
                                                : 1,
                                      ),
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
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
