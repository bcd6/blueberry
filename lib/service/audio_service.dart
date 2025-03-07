import 'package:blueberry/domain/loop_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:async';

class AudioService {
  final Player _player = Player();
  final _loopModeController = StreamController<LoopMode>.broadcast();
  LoopMode _loopMode = LoopMode.playlist;
  Function(bool wasLooped)? onTrackComplete;

  AudioService() {
    _initPlayer();
  }

  void _initPlayer() {
    _player.stream.playing.listen((playing) {
      debugPrint('Player state: ${playing ? 'playing' : 'paused'}');
    });

    _player.stream.position.listen((position) {
      // debugPrint('Position: $position');
    });

    _player.stream.completed.listen((_) async {
      if (_loopMode == LoopMode.track) {
        // Replay the current track
        await _player.seek(Duration.zero);
        await _player.play();
        onTrackComplete?.call(true);
      } else {
        // Let the UI handle playlist progression
        onTrackComplete?.call(false);
      }
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
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double volume) => _player.setVolume(volume * 100);

  Future<void> toggleLoopMode() async {
    final modes = [LoopMode.track, LoopMode.playlist];
    final currentIndex = modes.indexOf(_loopMode);
    _loopMode = modes[(currentIndex + 1) % modes.length];
    _loopModeController.add(_loopMode);
    debugPrint('Loop mode set to: $_loopMode');
  }

  LoopMode get loopMode => _loopMode;
  bool get isLoopingTrack => _loopMode == LoopMode.track;
  bool get isLoopingPlaylist => _loopMode == LoopMode.playlist;

  Stream<bool> get playerStateStream => _player.stream.playing;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;

  Future<void> dispose() async {
    await _player.dispose();
    await _loopModeController.close();
  }
}
