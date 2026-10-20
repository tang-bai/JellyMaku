import 'dart:math' as math;

import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

final _controlCharacters = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
final _whitespace = RegExp(r'\s+');
final _mergeSymbols = RegExp(
  r'[^\w\u4e00-\u9fff\u3040-\u309F\u30A0-\u30FF\u31F0-\u31FF\uFF65-\uFF9F]',
  unicode: true,
);
final _repeatedRun = RegExp(r'(.)\1{2,}');

/// Kazumi 的合并窗口：5 秒内相同文本折叠成一条。
const double danmakuMergeWindowSeconds = 5;

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
    final rawField = fields[3].trim();
    if (time == null || time.isNaN || !time.isFinite) continue;
    if (rawField.isNotEmpty && blockUsers.contains(rawField)) continue;

    final text = _sanitize(entry.m, blockWords);
    if (text.isEmpty) continue;

    final adjusted = time + settings.offsetSeconds + shift;
    if (adjusted < 0) continue;

    final source = parseDanmakuSource(rawField);
    final key = '$rawField|$adjusted|$text';
    if (!seen.add(key)) continue;

    parsed.add(DanmakuComment(
      time: adjusted,
      mode: _mode(mode),
      color: _color(color),
      uid: rawField,
      text: text,
      source: source,
    ));
  }

  parsed.sort((a, b) => a.time.compareTo(b.time));

  // 去重合并只改变展示密度，不改变"哪些来源/类型可见"；后者交给
  // isDanmakuVisible 在绘制时实时判断，切换开关无需重新请求。
  final merged =
      settings.mergeDuplicates ? _mergeRepeated(parsed) : parsed;

  final maxComments = settings.maxComments;
  if (maxComments > 0 && merged.length > maxComments) {
    final step = merged.length / maxComments;
    final sampled = <DanmakuComment>[];
    for (var i = 0; i < maxComments; i++) {
      sampled.add(merged[math.min(merged.length - 1, (i * step).floor())]);
    }
    return sampled;
  }
  return merged;
}

/// 绘制时的实时可见性判断。
///
/// 来源与类型开关放在这里而不是解析阶段，播放中切换设置可以立刻生效。
bool isDanmakuVisible(
  DanmakuComment comment,
  DanmakuSettingsModel settings,
) {
  final modeVisible = switch (comment.mode) {
    DanmakuMode.scroll => settings.showScroll,
    DanmakuMode.top => settings.showTop,
    DanmakuMode.bottom => settings.showBottom,
  };
  if (!modeVisible) return false;
  return switch (comment.source) {
    DanmakuSource.biliBili => settings.showBiliBiliSource,
    DanmakuSource.gamer => settings.showGamerSource,
    DanmakuSource.danDanPlay => settings.showDanDanPlaySource,
    DanmakuSource.local => settings.showLocalSource,
  };
}

List<DanmakuComment> _mergeRepeated(List<DanmakuComment> comments) {
  final groups = <String, List<DanmakuComment>>{};
  var opaque = 0;
  for (final comment in comments) {
    final key = _normalizeForMerge(comment.text);
    if (key.isEmpty) {
      // 纯符号弹幕没有可比较的归一化文本，保持原样。
      groups['\u0000${opaque++}'] = [comment];
      continue;
    }
    groups.putIfAbsent(key, () => []).add(comment);
  }

  final merged = <DanmakuComment>[];
  for (final group in groups.values) {
    if (group.length == 1) {
      merged.add(group.first);
      continue;
    }
    group.sort((a, b) => a.time.compareTo(b.time));
    var start = 0;
    for (var i = 1; i <= group.length; i++) {
      final windowEnds = i == group.length ||
          group[i].time - group[start].time > danmakuMergeWindowSeconds;
      if (!windowEnds) continue;
      final slice = group.sublist(start, i);
      if (slice.length == 1) {
        merged.add(slice.first);
      } else {
        merged.add(DanmakuComment(
          time: slice.first.time,
          // 合并结果统一做成顶部白字，和 Kazumi 的表现一致。
          mode: DanmakuMode.top,
          color: 0xFFFFFF,
          uid: slice.first.uid,
          text: '${slice.first.text} x${slice.length}',
          source: slice.first.source,
        ));
      }
      start = i;
    }
  }

  merged.sort((a, b) => a.time.compareTo(b.time));
  return merged;
}

/// 全角转半角、去掉空白与符号、压缩连续重复字符，用于识别同义弹幕。
String _normalizeForMerge(String input) {
  final buffer = StringBuffer();
  for (final code in input.trim().toLowerCase().codeUnits) {
    if (code == 0x3000) {
      buffer.writeCharCode(0x20);
    } else if (code >= 0xFF01 && code <= 0xFF5E) {
      buffer.writeCharCode(code - 0xFEE0);
    } else {
      buffer.writeCharCode(code);
    }
  }
  var text = buffer.toString().replaceAll(_whitespace, '');
  text = text.replaceAll(_mergeSymbols, '');
  return text.replaceAllMapped(_repeatedRun, (match) => match.group(1)! * 3);
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
