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
  Duration _frozenPosition = Duration.zero;
  bool _wasPlaying = false;
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
    final now = DateTime.now();
    if (position != _lastPosition) {
      _lastPosition = position;
      _lastPositionAt = now;
      _frozenPosition = position;
    }

    final elapsedSincePosition = now.difference(_lastPositionAt);
    final effectivePlaying = playback.playing && !playback.buffering;
    final Duration current;
    if (effectivePlaying) {
      if (!_wasPlaying) {
        // Do not count paused/buffered time as elapsed playback time.
        _lastPositionAt = now;
      }
      _wasPlaying = true;
      current = Duration(
        microseconds: position.inMicroseconds +
            (elapsedSincePosition.inMicroseconds * rate).round(),
      );
    } else {
      // Freeze at the extrapolated time on the pause/buffer transition.
      // Using the raw provider position here makes comments jump backwards.
      if (_wasPlaying) {
        _frozenPosition = Duration(
          microseconds: position.inMicroseconds +
              (elapsedSincePosition.inMicroseconds * rate).round(),
        );
        _wasPlaying = false;
      }
      current = _frozenPosition;
    }

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

    // Assign a stable lane/row to every comment before drawing. Assigning
    // only the currently visible comments made lanes change whenever an older
    // comment left the window, which looked like the rows were jumping.
    final scrollLanes = List<int>.filled(comments.length, 0);
    final topRows = List<int>.filled(comments.length, 0);
    final bottomRows = List<int>.filled(comments.length, 0);
    final scrollEnds = List<double>.filled(maxLanes, double.negativeInfinity);
    final topEnds = List<double>.filled(maxLanes, double.negativeInfinity);
    final bottomEnds = List<double>.filled(maxLanes, double.negativeInfinity);

    for (var i = 0; i < comments.length; i++) {
      final comment = comments[i];
      final duration =
          comment.mode == DanmakuMode.scroll ? settings.speedSeconds : 4.5;

      if (comment.mode == DanmakuMode.scroll) {
        var lane = scrollEnds.indexWhere((end) => end <= comment.time);
        if (lane < 0) lane = _leastEnd(scrollEnds);
        scrollEnds[lane] = comment.time + duration;
        scrollLanes[i] = lane;
      } else if (comment.mode == DanmakuMode.top) {
        var row = topEnds.indexWhere((end) => end <= comment.time);
        if (row < 0) row = _leastEnd(topEnds);
        topEnds[row] = comment.time + duration;
        topRows[i] = row;
      } else {
        var row = bottomEnds.indexWhere((end) => end <= comment.time);
        if (row < 0) row = _leastEnd(bottomEnds);
        bottomEnds[row] = comment.time + duration;
        bottomRows[i] = row;
      }
    }

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
        final y = scrollLanes[i] * lineHeight;
        if (y + lineHeight > areaHeight) continue;
        final x = size.width - progress * (size.width + textPainter.width);
        _paintText(canvas, textPainter, Offset(x, y), comment.color);
      } else if (comment.mode == DanmakuMode.top) {
        final y = topRows[i] * lineHeight;
        final x = (size.width - textPainter.width) / 2;
        _paintText(canvas, textPainter, Offset(x, y), comment.color);
      } else {
        final y = areaHeight - (bottomRows[i] + 1) * lineHeight;
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

  int _leastEnd(List<double> ends) {
    var index = 0;
    for (var i = 1; i < ends.length; i++) {
      if (ends[i] < ends[index]) index = i;
    }
    return index;
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
