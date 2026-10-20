import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/danmaku/comment_parser.dart';
import 'package:fladder/danmaku/danmaku_api_client.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';
import 'package:fladder/screens/video_player/components/danmaku_overlay.dart';

/// 5000 条弹幕的解析与绘制基准，用于 Stage A 的压测证据。
///
/// 运行：flutter test test/danmaku/danmaku_perf_test.dart
void main() {
  testWidgets('5000 danmaku: parse + layout + paint', (tester) async {
    const total = 5000;
    const settings = DanmakuSettingsModel(
      fontSize: 36,
      speedSeconds: 8,
      displayArea: 0.7,
    );

    final raw = List.generate(total, (i) {
      final time = (i * 0.25) % 1440; // 24 分钟时间轴
      final mode = i % 11 == 0 ? 5 : (i % 17 == 0 ? 4 : 1);
      return DanmakuApiComment(
        cid: i,
        p: '${time.toStringAsFixed(2)},$mode,16777215,[bilibili1]',
        m: '压测弹幕 #$i 这是一条用于布局性能测试的弹幕文本',
      );
    });

    final parseWatch = Stopwatch()..start();
    final comments = parseDanmakuComments(raw, settings);
    parseWatch.stop();

    expect(comments.length, greaterThan(4500));

    final painter = DanmakuPainter(
      comments: comments,
      settings: settings,
      time: 0,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1920, 1080);

    final firstWatch = Stopwatch()..start();
    painter.paint(canvas, size);
    firstWatch.stop();

    final frameWatch = Stopwatch()..start();
    for (var frame = 0; frame < 120; frame++) {
      DanmakuPainter(
        comments: comments,
        settings: settings,
        time: frame.toDouble(),
      ).paint(canvas, size);
    }
    frameWatch.stop();
    recorder.endRecording();

    final averageMs = frameWatch.elapsedMicroseconds / 120 / 1000;
    // ignore: avoid_print
    print('[danmaku-perf] comments=${comments.length} '
        'parse=${parseWatch.elapsedMilliseconds}ms '
        'firstPaint=${firstWatch.elapsedMilliseconds}ms '
        'avgFrame=${averageMs.toStringAsFixed(2)}ms');

    expect(parseWatch.elapsed, lessThan(const Duration(seconds: 3)));
    expect(firstWatch.elapsed, lessThan(const Duration(seconds: 3)));
    expect(averageMs, lessThan(33.0));
  });
}
