import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/models/playback/playback_stats.dart';
import 'package:fladder/util/byte_formatting.dart';

void main() {
  group('PlaybackRuntimeStats.fromMpvProperties', () {
    test('parses live bitrate, cache and decoder values', () {
      final stats = PlaybackRuntimeStats.fromMpvProperties(
        {
          'video-bitrate': '8000000.000000',
          'audio-bitrate': '192000',
          'cache-speed': '1250000.5',
          'demuxer-cache-duration': '12.5',
          'frame-drop-count': '3',
          'estimated-vf-fps': '23.976',
          'hwdec-current': 'd3d11va',
          'video-codec': 'hevc (HEVC (High Efficiency Video Coding))',
          'audio-codec': 'aac (AAC (Advanced Audio Coding))',
          'file-format': 'matroska,webm',
        },
        loadTime: const Duration(milliseconds: 420),
      );

      expect(stats.videoBitrate, 8000000);
      expect(stats.audioBitrate, 192000);
      expect(stats.downloadBytesPerSecond, 1250000.5);
      expect(stats.cachedDuration, const Duration(milliseconds: 12500));
      expect(stats.droppedFrames, 3);
      expect(stats.renderFps, 23.976);
      expect(stats.hardwareDecoder, 'd3d11va');
      expect(stats.videoCodec, 'hevc');
      expect(stats.audioCodec, 'aac');
      expect(stats.container, 'matroska,webm');
      expect(stats.loadTime, const Duration(milliseconds: 420));
      expect(stats.totalBitrate, 8192000);
    });

    test('ignores unavailable mpv values', () {
      final stats = PlaybackRuntimeStats.fromMpvProperties({
        'video-bitrate': 'no',
        'audio-bitrate': '',
        'cache-speed': 'no',
        'demuxer-cache-duration': '-1',
        'frame-drop-count': 'no',
        'estimated-vf-fps': '0',
        'hwdec-current': 'no',
        'video-codec': 'no',
        'audio-codec': '',
        'file-format': 'no',
      });

      expect(stats.videoBitrate, isNull);
      expect(stats.audioBitrate, isNull);
      expect(stats.downloadBytesPerSecond, isNull);
      expect(stats.cachedDuration, isNull);
      expect(stats.droppedFrames, isNull);
      expect(stats.renderFps, isNull);
      expect(stats.hardwareDecoder, isNull);
      expect(stats.videoCodec, isNull);
      expect(stats.audioCodec, isNull);
      expect(stats.container, isNull);
      expect(stats.totalBitrate, isNull);
      expect(stats.hasRuntimeValues, isFalse);
    });

    test('keeps zero dropped frames and total bitrate from one track', () {
      final stats = PlaybackRuntimeStats.fromMpvProperties({
        'frame-drop-count': '0',
        'video-bitrate': '1500000',
      });

      expect(stats.droppedFrames, 0);
      expect(stats.totalBitrate, 1500000);
    });
  });

  group('byte formatting', () {
    test('formats byte counts', () {
      expect(formatBytes(null), isNull);
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1536), '1.50 KB');
      expect(formatBytes(1024 * 1024), '1.00 MB');
    });

    test('formats transfer rates', () {
      expect(formatBytesPerSecond(null), isNull);
      expect(formatBytesPerSecond(-1), isNull);
      expect(formatBytesPerSecond(0), '0 B/s');
      expect(formatBytesPerSecond(1250000), '1.19 MB/s');
      expect(formatBytesPerSecond(15 * 1024 * 1024), '15.0 MB/s');
    });
  });
}
