import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:fladder/models/items/media_streams_model.dart';
import 'package:fladder/models/playback/playback_model.dart';
import 'package:fladder/models/playback/playback_stats.dart';
import 'package:fladder/providers/session_info_provider.dart';
import 'package:fladder/providers/video_player_provider.dart';
import 'package:fladder/util/bitrate_formatting.dart';
import 'package:fladder/util/byte_formatting.dart';
import 'package:fladder/util/clipboard_helper.dart';
import 'package:fladder/util/duration_extensions.dart';
import 'package:fladder/util/localization_helper.dart';

Future<void> showVideoPlaybackInformation(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const VideoPlaybackInformationDialog(),
  );
}

/// Playback information dialog shared by the playback-type and quality badges.
///
/// The static media details come from the Jellyfin playback response; the live
/// rows are polled from the player backend once a second so bitrate and
/// download speed reflect what is actually playing.
class VideoPlaybackInformationDialog extends ConsumerStatefulWidget {
  const VideoPlaybackInformationDialog({super.key});

  @override
  ConsumerState<VideoPlaybackInformationDialog> createState() =>
      _VideoPlaybackInformationDialogState();
}

class _VideoPlaybackInformationDialogState
    extends ConsumerState<VideoPlaybackInformationDialog> {
  Timer? _refreshTimer;
  PlaybackRuntimeStats? _runtimeStats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _refreshStats();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _refreshStats());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStats() async {
    PlaybackRuntimeStats? stats;
    try {
      stats = await ref.read(videoPlayerProvider).getPlaybackStats();
    } catch (_) {
      // A backend that does not implement stats must not break the dialog.
    }
    if (!mounted) return;
    setState(() {
      _runtimeStats = stats;
      _loadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playbackModel = ref.watch(playBackModel);
    final mediaPlayback = ref.watch(mediaPlaybackProvider);
    final backend =
        ref.watch(videoPlayerProvider.select((value) => value.backend));
    final sessionInfo = ref.watch(sessionInfoProvider);

    final videoStream = playbackModel?.mediaStreams?.videoStreams.firstOrNull;
    final audioStream = playbackModel?.mediaStreams?.currentAudioStream;
    final mediaSource = playbackModel?.playbackInfo?.mediaSources?.firstOrNull;
    final runtime = _runtimeStats;
    final transcodeInfo = sessionInfo.transCodeInfo;

    final status = mediaPlayback.buffering
        ? context.localized.playbackStatusBuffering
        : mediaPlayback.playing
            ? context.localized.playbackStatusPlaying
            : context.localized.playbackStatusPaused;

    final url = playbackModel?.media?.url;
    final downloadSpeed = _isLocalUrl(url)
        ? context.localized.playbackStatsLocalFile
        : formatBytesPerSecond(runtime?.downloadBytesPerSecond) ??
            context.localized.unknown;

    final streamBitrate =
        _combinedBitrate(videoStream?.bitRate, audioStream?.bitRate);
    final sourceBitrate = mediaSource?.bitrate ?? streamBitrate;
    final currentBitrate = runtime?.totalBitrate ?? sourceBitrate;
    final videoBitrate = runtime?.videoBitrate ?? videoStream?.bitRate;
    final audioBitrate = runtime?.audioBitrate ?? audioStream?.bitRate;
    final container = mediaSource?.container ?? runtime?.container;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(IconsaxPlusLinear.info_circle, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.localized.playbackInformationTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_loadingStats)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: context.localized.close,
                    icon: const Icon(IconsaxPlusLinear.close_circle),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _section(
                context,
                title: context.localized.playbackStatsSection,
                children: [
                  if ((runtime == null || !runtime.hasRuntimeValues) &&
                      !_loadingStats)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        context.localized.playbackStatsUnavailable,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  _InfoRow(
                      label: context.localized.playbackStatusLabel,
                      value: status),
                  _InfoRow(
                    label: context.localized.currentBitrateLabel,
                    value: _orUnknown(context, _bitrateText(currentBitrate)),
                  ),
                  _InfoRow(
                    label: context.localized.videoBitrateLabel,
                    value: _orUnknown(context, _bitrateText(videoBitrate)),
                  ),
                  _InfoRow(
                    label: context.localized.audioBitrateLabel,
                    value: _orUnknown(context, _bitrateText(audioBitrate)),
                  ),
                  _InfoRow(
                      label: context.localized.downloadSpeedLabel,
                      value: downloadSpeed),
                  _InfoRow(
                    label: context.localized.bufferDurationLabel,
                    value: runtime?.cachedDuration != null
                        ? runtime!.cachedDuration!.readAbleDuration
                        : mediaPlayback.buffer.readAbleDuration,
                  ),
                  _InfoRow(
                    label: context.localized.droppedFramesLabel,
                    value:
                        _orUnknown(context, runtime?.droppedFrames?.toString()),
                  ),
                  _InfoRow(
                    label: context.localized.hardwareDecoderLabel,
                    value: _orUnknown(context, runtime?.hardwareDecoder),
                  ),
                  _InfoRow(
                    label: context.localized.renderFpsLabel,
                    value: _orUnknown(context, _fpsText(runtime?.renderFps)),
                  ),
                  if (runtime?.loadTime != null)
                    _InfoRow(
                      label: context.localized.loadTimeLabel,
                      value: _loadTimeText(runtime!.loadTime!),
                    ),
                ],
              ),
              _section(
                context,
                title: context.localized.playbackMediaSection,
                children: [
                  _InfoRow(
                    label: context.localized.videoStreamLabel,
                    value: _orUnknown(
                        context,
                        _videoSummary(videoStream,
                            fallbackCodec: runtime?.videoCodec)),
                  ),
                  _InfoRow(
                    label: context.localized.audioStreamLabel,
                    value: _orUnknown(
                        context,
                        _audioSummary(audioStream,
                            fallbackCodec: runtime?.audioCodec)),
                  ),
                  _InfoRow(
                    label: context.localized.containerLabel,
                    value: _orUnknown(context, container),
                  ),
                  _InfoRow(
                    label: context.localized.resolutionLabel,
                    value: _orUnknown(
                      context,
                      playbackModel?.mediaStreams?.resolutionText ??
                          _resolutionText(videoStream),
                    ),
                  ),
                  if (runtime?.totalBitrate != null &&
                      sourceBitrate != null &&
                      sourceBitrate != runtime?.totalBitrate)
                    _InfoRow(
                      label: context.localized.sourceBitrateLabel,
                      value: _orUnknown(context, _bitrateText(sourceBitrate)),
                    ),
                  _InfoRow(
                    label: context.localized.fileSizeLabel,
                    value: _orUnknown(context, formatBytes(mediaSource?.size)),
                  ),
                  _InfoRow(
                    label: context.localized.playbackType,
                    value: _orUnknown(context, playbackModel?.label(context)),
                  ),
                  _InfoRow(
                    label: context.localized.playerBackendLabel,
                    value: _orUnknown(context, backend?.label(context)),
                  ),
                  if (transcodeInfo?.transcodeReasons?.isNotEmpty == true)
                    _InfoRow(
                      label: context.localized.transcodeReasonLabel,
                      value: transcodeInfo!.transcodeReasons!
                          .map((reason) => reason.name)
                          .join(', '),
                    ),
                  if (transcodeInfo?.completionPercentage != null)
                    _InfoRow(
                      label: context.localized.transcodeProgressLabel,
                      value:
                          '${transcodeInfo!.completionPercentage!.toStringAsFixed(2)} %',
                    ),
                ],
              ),
              _urlRow(context, url),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        ...children,
        const Divider(height: 24),
      ],
    );
  }

  Widget _urlRow(BuildContext context, String? url) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 122,
          child: Text(
            context.localized.playbackUrlLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Text(
              url ?? context.localized.unknown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              context.copyToClipboard(url ?? context.localized.unknown),
          icon: const Icon(IconsaxPlusLinear.copy, size: 18),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _orUnknown(BuildContext context, String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? context.localized.unknown : text;
}

String? _bitrateText(int? bitrate) {
  if (bitrate == null || bitrate <= 0) return null;
  return bitrate.videoBitrateFormat;
}

String? _fpsText(double? fps) {
  if (fps == null || fps <= 0) return null;
  return '${fps.toStringAsFixed(fps >= 10 ? 2 : 3)} fps';
}

String _loadTimeText(Duration duration) {
  if (duration.inMilliseconds < 1000) return '${duration.inMilliseconds} ms';
  return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)} s';
}

String? _videoSummary(VideoStreamModel? stream, {String? fallbackCodec}) {
  final codec =
      stream?.codec.isNotEmpty == true ? stream!.codec : (fallbackCodec ?? '');
  final parts = <String>[
    if (codec.isNotEmpty) codec.toUpperCase(),
    if (stream != null && stream.width > 0 && stream.height > 0)
      '${stream.width}x${stream.height}',
    if (stream != null && stream.frameRate > 0)
      '${stream.frameRate.toStringAsFixed(3)} fps',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String? _audioSummary(AudioStreamModel? stream, {String? fallbackCodec}) {
  final codec =
      stream?.codec.isNotEmpty == true ? stream!.codec : (fallbackCodec ?? '');
  final parts = <String>[
    if (codec.isNotEmpty) codec.toUpperCase(),
    if (stream != null && stream.channelLayout.isNotEmpty) stream.channelLayout,
    if (stream?.sampleRate != null && stream!.sampleRate! > 0)
      '${(stream.sampleRate! / 1000).toStringAsFixed(1)} kHz',
    if (stream?.bitRate != null && stream!.bitRate! > 0)
      stream.bitRate!.audioBitrateFormat ?? '',
  ].where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

int? _combinedBitrate(int? videoBitrate, int? audioBitrate) {
  final video = videoBitrate ?? 0;
  final audio = audioBitrate ?? 0;
  if (video <= 0 && audio <= 0) return null;
  return video + audio;
}

String? _resolutionText(VideoStreamModel? stream) {
  if (stream == null || stream.width <= 0 || stream.height <= 0) return null;
  return '${stream.width}x${stream.height}';
}

bool _isLocalUrl(String? url) {
  final uri = Uri.tryParse(url ?? '');
  if (uri == null) return false;
  return uri.scheme != 'http' && uri.scheme != 'https';
}
