/// Playback statistics reported by the active player backend.
///
/// Backends expose different subsets of these values: libmpv can report live
/// bitrate and cache speed, MDK only container metadata, and the native player
/// exposes nothing. Keeping every field nullable lets the UI fall back to the
/// Jellyfin media source information without pretending the value is live.
class PlaybackRuntimeStats {
  const PlaybackRuntimeStats({
    this.videoBitrate,
    this.audioBitrate,
    this.downloadBytesPerSecond,
    this.cachedDuration,
    this.droppedFrames,
    this.renderFps,
    this.hardwareDecoder,
    this.videoCodec,
    this.audioCodec,
    this.container,
    this.loadTime,
  });

  /// Video bitrate in bits per second, as reported by the player.
  final int? videoBitrate;

  /// Audio bitrate in bits per second, as reported by the player.
  final int? audioBitrate;

  /// Current network/cache fill rate in bytes per second.
  final double? downloadBytesPerSecond;

  /// How much media is cached ahead of the playback position.
  final Duration? cachedDuration;

  final int? droppedFrames;
  final double? renderFps;

  /// Active hardware decoder, for example `d3d11va`; null when decoding in software.
  final String? hardwareDecoder;

  final String? videoCodec;
  final String? audioCodec;
  final String? container;

  /// Time from starting a load until the backend reported the media as ready.
  final Duration? loadTime;

  int? get totalBitrate {
    final video = videoBitrate ?? 0;
    final audio = audioBitrate ?? 0;
    if (video <= 0 && audio <= 0) return null;
    return video + audio;
  }

  bool get hasRuntimeValues =>
      videoBitrate != null ||
      audioBitrate != null ||
      downloadBytesPerSecond != null ||
      cachedDuration != null ||
      droppedFrames != null ||
      renderFps != null ||
      hardwareDecoder != null ||
      videoCodec != null ||
      audioCodec != null ||
      container != null ||
      loadTime != null;

  /// Parses the string values returned by mpv's `getProperty`.
  ///
  /// mpv returns the literal `no` for properties that are unavailable for the
  /// current file, so it must not be parsed as a value.
  factory PlaybackRuntimeStats.fromMpvProperties(
    Map<String, String?> properties, {
    Duration? loadTime,
    double? measuredDownloadBytesPerSecond,
  }) {
    return PlaybackRuntimeStats(
      videoBitrate: _positiveInt(properties['video-bitrate']),
      audioBitrate: _positiveInt(properties['audio-bitrate']),
      downloadBytesPerSecond:
          measuredDownloadBytesPerSecond ?? _nonNegativeDouble(properties['cache-speed']),
      cachedDuration: _secondsToDuration(properties['demuxer-cache-duration']),
      droppedFrames: _nonNegativeInt(properties['frame-drop-count']),
      renderFps: _positiveDouble(properties['estimated-vf-fps']),
      hardwareDecoder: _cleanText(properties['hwdec-current']),
      videoCodec: _codecName(properties['video-codec']),
      audioCodec: _codecName(properties['audio-codec']),
      container: _cleanText(properties['file-format']),
      loadTime: loadTime,
    );
  }
}

String? _cleanText(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty || text == 'no') return null;
  return text;
}

/// mpv formats codecs as `hevc (HEVC (High Efficiency Video Coding))`.
String? _codecName(String? value) {
  final text = _cleanText(value);
  if (text == null) return null;
  final descriptionStart = text.indexOf(' (');
  final codec =
      descriptionStart > 0 ? text.substring(0, descriptionStart) : text;
  return codec.trim().isEmpty ? null : codec.trim();
}

int? _positiveInt(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
  return parsed.round();
}

int? _nonNegativeInt(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || !parsed.isFinite || parsed < 0) return null;
  return parsed.round();
}

double? _positiveDouble(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
  return parsed;
}

double? _nonNegativeDouble(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || !parsed.isFinite || parsed < 0) return null;
  return parsed;
}

Duration? _secondsToDuration(String? value) {
  final seconds = _nonNegativeDouble(value);
  if (seconds == null) return null;
  return Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round());
}
