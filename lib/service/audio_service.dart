import 'package:blueberry/domain/loop_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final Map<String, Duration> _durationCache = {};
  final _loopModeController = StreamController<LoopMode>.broadcast();

  LoopMode _loopMode = LoopMode.playlist;
  Function(bool wasLooped)? onTrackComplete;

  AudioService() {
    _initPlayer();
  }

  void _initPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      debugPrint('Player state: $state');
    });

    _player.onPositionChanged.listen((position) {
      debugPrint('Position: $position');
    });

    // Handle track completion
    _player.onPlayerComplete.listen((_) async {
      if (_loopMode == LoopMode.track) {
        // Replay the current track
        await _player.seek(Duration.zero);
        await _player.resume();
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
      // Play the file first
      await _player.play(DeviceFileSource(filePath));

      // If this is a CUE track, seek to the start position
      if (startFrom > Duration.zero) {
        await _player.seek(startFrom);
      }
    } catch (e) {
      debugPrint('Error playing file: $e');
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.resume();
  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  // Add method to get current playing position
  Future<Duration> getCurrentPosition() async {
    return await _player.getCurrentPosition() ?? Duration.zero;
  }

  // Add method to check if position is within track bounds
  bool isWithinTrackBounds(
    Duration position,
    Duration startOffset,
    Duration? duration,
  ) {
    if (duration == null) return true;
    return position >= startOffset && position <= (startOffset + duration);
  }

  Future<void> toggleLoopMode() async {
    final modes = [LoopMode.track, LoopMode.playlist];
    final currentIndex = modes.indexOf(_loopMode);
    _loopMode = modes[(currentIndex + 1) % modes.length];
    _loopModeController.add(_loopMode); // Notify listeners
    debugPrint('Loop mode set to: $_loopMode');
  }

  // Add getters
  LoopMode get loopMode => _loopMode;
  bool get isLoopingTrack => _loopMode == LoopMode.track;
  bool get isLoopingPlaylist => _loopMode == LoopMode.playlist;

  // Add getters for streams
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration?> get durationStream => _player.onDurationChanged;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;

  Future<Duration?> getTrackDuration(String filePath) async {
    try {
      // Check cache first
      if (_durationCache.containsKey(filePath)) {
        return _durationCache[filePath];
      }

      // Use the main player to get duration
      await _player.setSource(DeviceFileSource(filePath));
      final duration = await _player.getDuration();

      if (duration != null) {
        _durationCache[filePath] = duration;
      }

      return duration;
    } catch (e) {
      debugPrint('Error getting duration for $filePath: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
    await _loopModeController.close();
  }
}
