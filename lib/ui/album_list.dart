import 'dart:io';
import 'dart:math' as math;
import 'package:blueberry/album/album.dart';
import 'package:blueberry/album/album_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  final ScrollController _scrollController = ScrollController();
  final _initLoad = 48;
  List<int> _displayedIndices = [];
  late AlbumState _albumState;
  List<Album> _albums = [];
  bool _precacheDone = false;

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages(_albums);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safety check to prevent range errors
    _displayedIndices =
        _displayedIndices.where((index) => index < _albums.length).toList();

    return Scaffold(
      appBar: null,
      body: Center(
        child: Listener(
          onPointerSignal: (ps) {
            if (ps is PointerScrollEvent) {
              var duration = 100;
              final newOffset =
                  _scrollController.offset + ps.scrollDelta.dy * 6;
              if (ps.scrollDelta.dy.isNegative) {
                _scrollController.animateTo(
                  math.max(0, newOffset),
                  duration: Duration(milliseconds: duration),
                  curve: Curves.linear,
                );
              } else {
                _scrollController.animateTo(
                  math.min(
                    _scrollController.position.maxScrollExtent,
                    newOffset,
                  ),
                  duration: Duration(milliseconds: duration),
                  curve: Curves.linear,
                );
              }
            }
          },
          child: GridView.extent(
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: 480,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            children:
                _displayedIndices.map((index) {
                  final album = _albums[index];
                  return Container(
                    padding: const EdgeInsets.all(36),
                    child: GestureDetector(
                      child: _buildAlbumCover(album.coverFilePath),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // builder: (context) => AlbumPlay(album: album),
                            builder: (context) => Container(),
                          ),
                        );
                      },
                      onSecondaryTap: () => _resetApp(context),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  void _init() {
    _albumState = context.read<AlbumState>();
    _albums = [..._albumState.albums];
    setState(() {
      _displayedIndices = List.generate(
        math.min(_initLoad, _albumState.albums.length),
        (index) => index,
      );
    });
  }

  void _onScroll() {
    final position = _scrollController.position;
    // debugPrint('Scrolling: ${position.pixels}');
    // debugPrint('MaxScrollExtent: ${position.maxScrollExtent}');
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      final currentLength = _displayedIndices.length;
      final totalAlbums = _albumState.albums.length;
      debugPrint('CurrentLength: $currentLength');

      if (currentLength < totalAlbums) {
        final newIndices = List.generate(48, (index) => currentLength + index);
        setState(() {
          _displayedIndices.addAll(newIndices);
        });
      }
    }
  }

  Future<void> _precacheImages(List<Album> albums) async {
    if (_precacheDone) {
      return;
    }

    debugPrint('Starting to precache ${albums.length} album images');

    for (final album in albums) {
      try {
        if (!mounted) continue;
        await precacheImage(
          FileImage(File(album.coverFilePath)),
          context,
          size: const Size(480, 480),
        );
      } catch (error) {
        debugPrint('Failed to precache image ${album.coverFilePath}: $error');
      }
    }

    debugPrint('Finished precaching all album images');
    _precacheDone = true;
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

  void _resetApp(context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    Phoenix.rebirth(context);
  }
}
