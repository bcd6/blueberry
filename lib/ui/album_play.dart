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

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  void _playTrack(int index) {
    final file = widget.album.files[index];
    _audioService.playFile(file);
    setState(() {
      _currentTrackIndex = index;
      _isPlaying = true;
    });
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Spacer(), // Push the custom buttons to bottom
                  const SizedBox(height: 16),
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
                            leading: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color:
                                    _currentTrackIndex == index
                                        ? Colors.blue
                                        : Colors.white54,
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
                            trailing: const Text(
                              '0:00',
                              style: TextStyle(color: Colors.white54),
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
