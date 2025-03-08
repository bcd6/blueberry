import 'dart:async';
import 'package:blueberry/feature/lyric/models/lyric.dart';

/// Base class for all lyric parsers.
abstract class LyricParser<T> {
  FutureOr<Lyric> parse(T input, Object audio);
}
