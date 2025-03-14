import 'dart:convert';
import 'dart:io';
import 'package:blueberry/domain/album.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../domain/track.dart';

class FavState extends ChangeNotifier {
  static const String _favFileName = '~fav.json';
  static const String _favFolderPath = 'D:\\~\\album';
  final Album _favAlbum = Album(
    folderPath: _favFolderPath,
    name: 'Favorites',
    coverPath: path.join(_favFolderPath, 'folder.jpg'),
  );

  String get _favFilePath => path.join(_favFolderPath, _favFileName);
}
