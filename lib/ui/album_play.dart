import 'dart:io';
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
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    // Set initial volume
    _audioService.setVolume(_volume);
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
    // Stop playback
    if (_isPlaying) {
      await _audioService.stop();
    }
    // Dispose audio service
    _audioService.dispose();
    super.dispose();
  }

  void _playTrack(int index) async {
    if (_currentTrackIndex == index && _isPlaying) {
      // Pause current track
      await _audioService.pause();
      setState(() {
        _isPlaying = false;
      });
    } else if (_currentTrackIndex == index && !_isPlaying) {
      // Resume current track
      await _audioService.resume();
      setState(() {
        _isPlaying = true;
      });
    } else {
      // Play new track
      final file = widget.album.files[index];
      await _audioService.playFile(file);
      setState(() {
        _currentTrackIndex = index;
        _isPlaying = true;
      });
    }
  }

  // Golden ratio constant
  static const double goldenRatio = 1.618;

  Future<void> _openInExplorer(String path) async {
    await Process.run('explorer', [path]);
  }

  @override
  Widget build(BuildContext context) {
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
                      onTap: () => _openInExplorer(widget.album.path),
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
                    const SizedBox(height: 16),
                    Text(
                      'Tracks',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.white54),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.album.files.length,
                        itemBuilder: (context, index) {
                          final fileName =
                              widget.album.files[index].split('\\').last;
                          return ListTile(
                            leading:
                                _currentTrackIndex == index
                                    ? SizedBox(
                                      width: 10, // Reduced size to match text
                                      height: 10, // Reduced size to match text
                                      child: CircularProgressIndicator(
                                        strokeWidth:
                                            1.5, // Thinner stroke for better appearance
                                        color: Colors.blue,
                                        value:
                                            _isPlaying
                                                ? null
                                                : 1, // null for spinning, 0 for stopped circle
                                      ),
                                    )
                                    : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                            title: Text(
                              fileName,
                              style: TextStyle(
                                color:
                                    _currentTrackIndex == index
                                        ? Colors.blue
                                        : Colors.white,
                              ),
                            ),
                            trailing: Text(
                              '0:00',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            onTap: () => _playTrack(index),
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
