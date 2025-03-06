import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/album.dart';

class AlbumPlay extends StatelessWidget {
  final Album album;

  const AlbumPlay({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 480,
              height: 480,
              padding: const EdgeInsets.all(16),
              child: Image.file(File(album.coverPath), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              album.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: album.files.length,
              itemBuilder: (context, index) {
                final file = album.files[index];
                final fileName = file.split('\\').last;
                return ListTile(
                  title: Text(
                    fileName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // TODO: Implement file playback
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
