import 'package:blueberry/feature/lyric/models/lyric_line.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

/// Converts [seconds] to human readable time in mm:ss
String getTimeString(int seconds) {
  String minuteString =
      '${(seconds / 60).floor() < 10 ? 0 : ''}${(seconds / 60).floor()}';
  String secondString = '${seconds % 60 < 10 ? 0 : ''}${seconds % 60}';
  return '$minuteString:$secondString'; // Returns a string with the format mm:ss
}

/// returns a SizedBox of height [height]
Widget verticalSpace(double height) => SizedBox(height: height);

/// returns a SizedBox of width [width]
Widget horizontalSpace(double width) => SizedBox(width: width);

/// Define type that accept [player], and boolean [isPlaying]
typedef PlaybackControlBuilder = Function(Player player, bool isPlaying);

/// Define type that accept [LyricLine] and [String]
typedef LyricChangedCallback = Function(LyricLine, String);
