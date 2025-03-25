import 'package:blueberry/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:async';

class AudioPlayer {
  final Player _player = Player();

  AudioPlayer() {
    _init();
  }

  void _init() {
    _player.stream.playing.listen((playing) {
      debugPrint('Player state: ${playing ? 'playing' : 'paused'}');

      if (playing) {
        Utils.preventScreenSleep();
      } else {
        Utils.resetScreenSleep();
      }
    });
    _player.stream.position.listen((position) {
      // debugPrint('Position: $position');
    });
  }

  Future<void> playFile(
    String filePath, {
    Duration startFrom = Duration.zero,
  }) async {
    try {
      final media = Media(filePath);
      await _player.open(media);
      await _player.stream.buffer.first;
      if (startFrom > Duration.zero) {
        debugPrint('Seeking to: $startFrom');
        await _player.seek(startFrom);
      }
      await _player.play();
    } catch (e) {
      debugPrint('Error playing file: $e');
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> play() => _player.play();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) => _player.setVolume(volume * 100);

  Stream<bool> get playerStateStream => _player.stream.playing;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;

  Stream<Duration> currentTrackDurationStream(
    Stream<Duration> inputStream,
    Duration startOffset,
  ) {
    return inputStream.map((position) {
      return position - startOffset;
    });
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
