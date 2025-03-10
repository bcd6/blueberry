import 'dart:io';
import 'dart:math' as math;
import 'package:blueberry/ui/album_play.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  final ScrollController scrollController = ScrollController();
  static const initLoad = 48;
  List<int> displayedIndices = [];

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
  }

  Future<void> _initializeData() async {
    final appState = context.read<AppState>();
    final albumCount = appState.albums.length;
    setState(() {
      displayedIndices = List.generate(
        math.min(initLoad, albumCount),
        (index) => index,
      );
    });
  }

  Future<void> _precacheImages() async {
    final appState = context.read<AppState>();
    for (final index in displayedIndices) {
      if (index < appState.albums.length) {
        final album = appState.albums[index];
        await precacheImage(
          FileImage(File(album.coverPath)),
          context,
          size: const Size(480, 480),
        ).onError((error, stackTrace) {
          debugPrint('Failed to precache image: $error');
          return;
        });
      }
    }
  }

  Future<void> _precacheNextBatch(List<int> newIndices) async {
    final appState = context.read<AppState>();
    for (final index in newIndices) {
      if (index < appState.albums.length) {
        final album = appState.albums[index];
        await precacheImage(
          FileImage(File(album.coverPath)),
          context,
          size: const Size(480, 480),
        );
      }
    }
  }

  Widget _buildAlbumCover(String coverPath) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: Image.file(
        File(coverPath),
        fit: BoxFit.cover,
        cacheHeight: 480,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image: $error');
          return const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = scrollController.position;
    // debugPrint('Scrolling: ${position.pixels}');
    // debugPrint('MaxScrollExtent: ${position.maxScrollExtent}');
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      final appState = context.read<AppState>();
      final currentLength = displayedIndices.length;
      final totalAlbums = appState.albums.length;
      debugPrint('CurrentLength: $currentLength');

      if (currentLength < totalAlbums) {
        final newIndices = [currentLength, currentLength + 1];
        setState(() {
          displayedIndices.addAll(newIndices);
        });
        // Precache next batch of images
        _precacheNextBatch(newIndices);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final albums = appState.albums;

    // Safety check to prevent range errors
    displayedIndices =
        displayedIndices.where((index) => index < albums.length).toList();

    return Scaffold(
      appBar: null,
      body: Center(
        child: Listener(
          onPointerSignal: (ps) {
            if (ps is PointerScrollEvent) {
              var duration = 100;
              final newOffset = scrollController.offset + ps.scrollDelta.dy * 6;
              if (ps.scrollDelta.dy.isNegative) {
                scrollController.animateTo(
                  math.max(0, newOffset),
                  duration: Duration(milliseconds: duration),
                  curve: Curves.linear,
                );
              } else {
                scrollController.animateTo(
                  math.min(
                    scrollController.position.maxScrollExtent,
                    newOffset,
                  ),
                  duration: Duration(milliseconds: duration),
                  curve: Curves.linear,
                );
              }
            }
          },
          child: GridView.extent(
            controller: scrollController,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: 480,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            children:
                displayedIndices.map((index) {
                  final album = appState.albums[index];
                  return Container(
                    padding: const EdgeInsets.all(36),
                    child: GestureDetector(
                      child: _buildAlbumCover(album.coverPath),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumPlay(album: album),
                          ),
                        );
                      },
                      onSecondaryTap: () => resetApp(context),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  void resetApp(context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    Phoenix.rebirth(context);
  }
}
