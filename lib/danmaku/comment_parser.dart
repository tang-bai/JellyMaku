import 'dart:math' as math;

import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

final _controlCharacters = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
final _whitespace = RegExp(r'\s+');

List<DanmakuComment> parseDanmakuComments(
  Iterable<DdpComment> raw,
  DanmakuSettingsModel settings, {
  double shift = 0,
}) {
  final blockWords = settings.blockWords
      .map((word) => word.trim().toLowerCase())
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  final blockUsers = settings.blockUsers
      .map((user) => user.trim())
      .where((user) => user.isNotEmpty)
      .toSet();

  final seen = <String>{};
  final parsed = <DanmakuComment>[];

  for (final entry in raw) {
    final fields = entry.p.split(',');
    if (fields.length < 4) continue;

    final time = double.tryParse(fields[0].trim());
    final mode = int.tryParse(fields[1].trim());
    final color = int.tryParse(fields[2].trim());
    final uid = fields[3].trim();
    if (time == null || time.isNaN || !time.isFinite) continue;
    if (uid.isNotEmpty && blockUsers.contains(uid)) continue;

    final text = _sanitize(entry.m, blockWords);
    if (text.isEmpty) continue;

    final danmakuMode = _mode(mode);
    if (danmakuMode == DanmakuMode.scroll && !settings.showScroll) continue;
    if (danmakuMode == DanmakuMode.top && !settings.showTop) continue;
    if (danmakuMode == DanmakuMode.bottom && !settings.showBottom) continue;

    final adjusted = time + settings.offsetSeconds + shift;
    if (adjusted < 0) continue;

    final key = '$uid|${adjusted.toStringAsFixed(1)}|$text';
    if (!seen.add(key)) continue;

    parsed.add(DanmakuComment(
      time: adjusted,
      mode: danmakuMode,
      color: _color(color),
      uid: uid,
      text: text,
    ));
  }

  parsed.sort((a, b) => a.time.compareTo(b.time));

  final maxComments = settings.maxComments;
  if (maxComments > 0 && parsed.length > maxComments) {
    final step = parsed.length / maxComments;
    final sampled = <DanmakuComment>[];
    for (var i = 0; i < maxComments; i++) {
      sampled.add(parsed[math.min(parsed.length - 1, (i * step).floor())]);
    }
    return sampled;
  }
  return parsed;
}

DanmakuMode _mode(int? value) {
  return switch (value) {
    4 => DanmakuMode.bottom,
    5 => DanmakuMode.top,
    _ => DanmakuMode.scroll,
  };
}

int _color(int? value) {
  if (value == null || value < 0 || value > 0xFFFFFF) return 0xFFFFFF;
  return value;
}

String _sanitize(String input, List<String> blockWords) {
  var text = input
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ')
      .replaceAll(_controlCharacters, '')
      .replaceAll(_whitespace, ' ')
      .trim();
  if (text.length > 200) text = text.substring(0, 200);
  if (blockWords.isNotEmpty) {
    final lower = text.toLowerCase();
    if (blockWords.any(lower.contains)) return '';
  }
  return text;
}
