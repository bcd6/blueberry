import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/album.dart';

class AlbumPlay extends StatelessWidget {
  final Album album;
  // Golden ratio constant
  static const double goldenRatio = 1.618;

  const AlbumPlay({super.key, required this.album});

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
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.file(
                        File(album.coverPath),
                        fit: BoxFit.cover,
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
                      album.name,
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
                        itemCount: album.files.length,
                        itemBuilder: (context, index) {
                          final fileName = album.files[index].split('\\').last;
                          return ListTile(
                            leading: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: const Text(
                              '0:00',
                              style: TextStyle(color: Colors.white54),
                            ),
                            onTap: () {},
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
