import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/danmaku/comment_parser.dart';
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
  Timer? _reloadDebounce;

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
    _reloadDebounce?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  /// 解析类设置变化时重算评论列表；300ms 防抖避免拖动滑杆时反复解析。
  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(danmakuProvider.notifier).reload();
    });
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
      if (previous.enabled != next.enabled) {
        if (!next.enabled) {
          ref.read(danmakuProvider.notifier).stop();
          return;
        }
        _loadedItemId = null;
        _loadFrom(ref.read(playBackModel));
        return;
      }
      // API 地址是边输入边保存的，防抖后再重载，避免每敲一个字符发一次请求。
      final connectionChanged = previous.apiBase != next.apiBase;
      if (connectionChanged) {
        _scheduleReload();
        return;
      }

      // 这些设置会改变解析结果（时间轴/文本/条数），需要重算；
      // 来源与类型开关只影响绘制，由 painter 实时判断。
      final parseChanged = previous.offsetSeconds != next.offsetSeconds ||
          previous.cacheDays != next.cacheDays ||
          previous.maxComments != next.maxComments ||
          previous.mergeDuplicates != next.mergeDuplicates ||
          previous.autoMatch != next.autoMatch ||
          previous.localFile != next.localFile ||
          !listEquals(previous.blockWords, next.blockWords) ||
          !listEquals(previous.blockUsers, next.blockUsers);
      if (parseChanged) _scheduleReload();
    });

    if (!settings.enabled ||
        state.status != DanmakuLoadStatus.ready ||
        state.comments.isEmpty) {
      return const SizedBox.shrink();
    }

    final position = playback.position;
    final now = DateTime.now();
    final effectivePlaying = playback.playing && !playback.buffering;

    // The overlay owns a display clock instead of jumping back to the last
    // provider position. The provider only updates a few times per second;
    // using it directly on resume pulls comments backwards for a frame.
    if (position != _lastPosition) {
      final drift = position - _frozenPosition;
      if (!effectivePlaying || drift.abs() > const Duration(seconds: 1)) {
        // A real pause/seek or a large discontinuity: align to the provider.
        _frozenPosition = position;
      }
      _lastPosition = position;
    }

    final elapsed = now.difference(_lastPositionAt);
    _lastPositionAt = now;

    if (effectivePlaying) {
      if (_wasPlaying) {
        _frozenPosition += Duration(
          microseconds: (elapsed.inMicroseconds * rate).round(),
        );
      } else {
        // Resume from the frozen display time; do not count paused time.
        _wasPlaying = true;
      }
    } else {
      _wasPlaying = false;
    }

    final current = _frozenPosition;

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

class _LaneLayout {
  const _LaneLayout({
    required this.scrollLanes,
    required this.topRows,
    required this.bottomRows,
  });

  final List<int> scrollLanes;
  final List<int> topRows;
  final List<int> bottomRows;
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
  static final Map<int, _LaneLayout> _laneCache = {};

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

    // Assign a stable lane/row to every comment before drawing. This is
    // cached because recomputing thousands of lanes on every frame causes
    // uneven frame times ("jerky" movement).
    final laneKey = Object.hash(
      identityHashCode(comments),
      comments.length,
      fontSize,
      maxLanes,
      settings.speedSeconds,
      settings.showScroll,
      settings.showTop,
      settings.showBottom,
      settings.showLocalSource,
    );
    var layout = _laneCache[laneKey];
    if (layout == null) {
      layout = _buildLaneLayout(comments, settings, maxLanes);
      if (_laneCache.length > 8) _laneCache.clear();
      _laneCache[laneKey] = layout;
    }
    final scrollLanes = layout.scrollLanes;
    final topRows = layout.topRows;
    final bottomRows = layout.bottomRows;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, areaHeight));

    for (var i = startIndex; i < comments.length; i++) {
      final comment = comments[i];
      if (comment.time > time) break;
      if (!isDanmakuVisible(comment, settings)) continue;

      final duration =
          comment.mode == DanmakuMode.scroll ? settings.speedSeconds : 4.5;
      final elapsed = time - comment.time;
      if (elapsed < 0 || elapsed > duration) continue;

      final color = settings.showColor ? comment.color : 0xFFFFFF;
      final textPainter = _layout(comment.text, fontSize, color);
      final strokePainter = settings.strokeWidth > 0
          ? _layout(comment.text, fontSize, color, stroke: true)
          : null;
      final progress = (elapsed / duration).clamp(0.0, 1.0);

      double x;
      double y;
      if (comment.mode == DanmakuMode.scroll) {
        y = scrollLanes[i] * lineHeight;
        if (y + lineHeight > areaHeight) continue;
        x = size.width - progress * (size.width + textPainter.width);
      } else if (comment.mode == DanmakuMode.top) {
        y = topRows[i] * lineHeight;
        x = (size.width - textPainter.width) / 2;
      } else {
        y = areaHeight - (bottomRows[i] + 1) * lineHeight;
        if (y < 0) continue;
        x = (size.width - textPainter.width) / 2;
      }

      final offset = Offset(x, y);
      strokePainter?.paint(canvas, offset);
      textPainter.paint(canvas, offset);
    }

    canvas.restore();
  }

  TextPainter _layout(String text, double fontSize, int color,
      {bool stroke = false}) {
    final key =
        '$text|$fontSize|${settings.fontFamily}|$color|${settings.opacity}'
        '|${stroke ? settings.strokeWidth : 0}';
    final cached = _textCache[key];
    if (cached != null) return cached;

    final TextStyle style;
    if (stroke) {
      style = TextStyle(
        fontSize: fontSize,
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.w600,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = settings.strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.black.withValues(alpha: settings.opacity),
      );
    } else {
      style = TextStyle(
        fontSize: fontSize,
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.w600,
        color: Color(color).withValues(alpha: settings.opacity),
        // 有描边时不再叠加阴影，避免两层黑边糊在一起。
        shadows: settings.strokeWidth > 0
            ? null
            : const [
                Shadow(
                    blurRadius: 2.5,
                    color: Colors.black87,
                    offset: Offset(0, 1)),
              ],
      );
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    if (_textCache.length > 8000) _textCache.clear();
    _textCache[key] = painter;
    return painter;
  }

  _LaneLayout _buildLaneLayout(
    List<DanmakuComment> comments,
    DanmakuSettingsModel settings,
    int maxLanes,
  ) {
    final scrollLanes = List<int>.filled(comments.length, 0);
    final topRows = List<int>.filled(comments.length, 0);
    final bottomRows = List<int>.filled(comments.length, 0);
    final scrollEnds = List<double>.filled(maxLanes, double.negativeInfinity);
    final topEnds = List<double>.filled(maxLanes, double.negativeInfinity);
    final bottomEnds = List<double>.filled(maxLanes, double.negativeInfinity);

    for (var i = 0; i < comments.length; i++) {
      final comment = comments[i];
      // 隐藏的评论不占轨道，切换来源/类型后重新布局不会留下空洞。
      if (!isDanmakuVisible(comment, settings)) continue;
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

    return _LaneLayout(
      scrollLanes: scrollLanes,
      topRows: topRows,
      bottomRows: bottomRows,
    );
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
