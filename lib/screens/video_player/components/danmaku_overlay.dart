import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';
import 'package:fladder/providers/danmaku_provider.dart';
import 'package:fladder/providers/settings/danmaku_settings_provider.dart';
import 'package:fladder/providers/settings/video_player_settings_provider.dart';
import 'package:fladder/providers/video_player_provider.dart';

class DanmakuOverlay extends ConsumerStatefulWidget {
  const DanmakuOverlay({super.key});

  @override
  ConsumerState<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends ConsumerState<DanmakuOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastPosition = Duration.zero;
  DateTime _lastPositionAt = DateTime.now();
  String? _loadedItemId;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    });
    _ticker.start();
    Future.microtask(() {
      if (mounted) _loadFrom(ref.read(playBackModel));
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _loadFrom(dynamic model) {
    final media = DanmakuMediaInfo.fromPlayback(model);
    if (media == null) {
      _loadedItemId = null;
      ref.read(danmakuProvider.notifier).stop();
      return;
    }
    if (_loadedItemId == media.itemId) return;
    _loadedItemId = media.itemId;
    ref.read(danmakuProvider.notifier).load(media);
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(mediaPlaybackProvider);
    final settings = ref.watch(danmakuSettingsProvider);
    final state = ref.watch(danmakuProvider);
    final rate = ref.watch(playbackRateProvider);

    ref.listen(playBackModel, (previous, next) {
      if (previous?.item.id != next?.item.id) {
        _loadedItemId = null;
        _loadFrom(next);
      }
    });

    ref.listen(danmakuSettingsProvider, (previous, next) {
      if (previous == null) return;
      final connectionChanged = previous.enabled != next.enabled ||
          previous.appId != next.appId ||
          previous.appSecret != next.appSecret ||
          previous.apiBase != next.apiBase ||
          previous.chConvert != next.chConvert ||
          previous.cacheDays != next.cacheDays;
      if (!connectionChanged) return;
      if (!next.enabled) {
        ref.read(danmakuProvider.notifier).stop();
        return;
      }
      if (previous.enabled != next.enabled) {
        _loadedItemId = null;
        _loadFrom(ref.read(playBackModel));
      } else {
        ref.read(danmakuProvider.notifier).reload();
      }
    });

    if (!settings.enabled ||
        state.status != DanmakuLoadStatus.ready ||
        state.comments.isEmpty) {
      return const SizedBox.shrink();
    }

    final position = playback.position;
    if (position != _lastPosition) {
      _lastPosition = position;
      _lastPositionAt = DateTime.now();
    }
    final elapsedSincePosition = DateTime.now().difference(_lastPositionAt);
    final current = playback.playing
        ? Duration(
            microseconds: position.inMicroseconds +
                (elapsedSincePosition.inMicroseconds * rate).round(),
          )
        : position;

    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: DanmakuPainter(
              comments: state.comments,
              settings: settings,
              time: current.inMicroseconds / Duration.microsecondsPerSecond,
            ),
          ),
        ),
      ),
    );
  }
}

class DanmakuPainter extends CustomPainter {
  DanmakuPainter({
    required this.comments,
    required this.settings,
    required this.time,
  });

  final List<DanmakuComment> comments;
  final DanmakuSettingsModel settings;
  final double time;

  static final Map<String, TextPainter> _textCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    if (comments.isEmpty || size.width <= 0 || size.height <= 0) return;

    final fontSize = settings.fontSize;
    final lineHeight = fontSize * 1.45;
    final areaHeight =
        (size.height * settings.displayArea).clamp(lineHeight, size.height);
    final maxLanes = math.max(1, (areaHeight / lineHeight).floor());
    final maxDuration = math.max(settings.speedSeconds, 6.0) + 2;
    final startIndex = _lowerBound(comments, time - maxDuration);

    final scrollEnds = List<double>.filled(maxLanes, -1);
    var topRow = 0;
    var bottomRow = 0;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, areaHeight));

    for (var i = startIndex; i < comments.length; i++) {
      final comment = comments[i];
      if (comment.time > time) break;

      final duration =
          comment.mode == DanmakuMode.scroll ? settings.speedSeconds : 4.5;
      final elapsed = time - comment.time;
      if (elapsed < 0 || elapsed > duration) continue;

      final textPainter = _layout(comment.text, fontSize);
      final progress = (elapsed / duration).clamp(0.0, 1.0);

      if (comment.mode == DanmakuMode.scroll) {
        var lane = scrollEnds.indexWhere((end) => end <= comment.time);
        if (lane < 0) {
          lane = scrollEnds.indexOf(scrollEnds.reduce(math.min));
        }
        scrollEnds[lane] = comment.time + duration;
        final y = lane * lineHeight;
        if (y + lineHeight > areaHeight) continue;
        final x = size.width - progress * (size.width + textPainter.width);
        _paintText(canvas, textPainter, Offset(x, y), comment.color);
      } else if (comment.mode == DanmakuMode.top) {
        final row = topRow++ % maxLanes;
        final y = row * lineHeight;
        final x = (size.width - textPainter.width) / 2;
        _paintText(canvas, textPainter, Offset(x, y), comment.color);
      } else {
        final row = bottomRow++ % maxLanes;
        final y = areaHeight - (row + 1) * lineHeight;
        if (y < 0) continue;
        final x = (size.width - textPainter.width) / 2;
        _paintText(canvas, textPainter, Offset(x, y), comment.color);
      }
    }

    canvas.restore();
  }

  TextPainter _layout(String text, double fontSize) {
    final key = '$text|$fontSize|${settings.fontFamily}';
    final cached = _textCache[key];
    if (cached != null) return cached;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: settings.fontFamily,
          fontWeight: FontWeight.w600,
          shadows: const [
            Shadow(
                blurRadius: 2.5, color: Colors.black87, offset: Offset(0, 1)),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    if (_textCache.length > 8000) _textCache.clear();
    _textCache[key] = painter;
    return painter;
  }

  void _paintText(
      Canvas canvas, TextPainter painter, Offset offset, int color) {
    final paint = TextPainter(
      text: TextSpan(
        text: painter.plainText,
        style: painter.text?.style?.copyWith(
          color: Color(color).withValues(alpha: settings.opacity),
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    paint.paint(canvas, offset);
  }

  int _lowerBound(List<DanmakuComment> values, double target) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (values[mid].time < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  @override
  bool shouldRepaint(covariant DanmakuPainter oldDelegate) => true;
}
