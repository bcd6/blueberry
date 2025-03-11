import 'dart:io';
import 'dart:math' as math;
import 'package:blueberry/domain/album.dart';
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final appState = context.read<AppState>();
    final albumCount = appState.albums.length;

    // Set initial display indices
    setState(() {
      displayedIndices = List.generate(
        math.min(initLoad, albumCount),
        (index) => index,
      );
    });

    // Precache all album images in background
    _precacheImages(appState.albums);
  }

  Future<void> _precacheImages(List<Album> albums) async {
    debugPrint('Starting to precache ${albums.length} album images');

    for (final album in albums) {
      try {
        await precacheImage(
          FileImage(File(album.coverPath)),
          context,
          size: const Size(480, 480),
        );
      } catch (error) {
        debugPrint('Failed to precache image ${album.coverPath}: $error');
      }
    }

    debugPrint('Finished precaching all album images');
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
