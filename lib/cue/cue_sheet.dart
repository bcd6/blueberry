import 'package:blueberry/cue/cue_track.dart';

class CueSheet {
  final String audioFile;
  final List<CueTrack> tracks;
  final String title;
  final String performer;

  CueSheet({
    required this.audioFile,
    required this.tracks,
    this.title = '',
    this.performer = '',
  });
}
