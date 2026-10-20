import 'dart:convert';

import 'package:fladder/danmaku/danmaku_models.dart';

/// 本地弹幕文件解析失败（格式不认识/内容为空/JSON 损坏）。
class LocalDanmakuFormatException implements Exception {
  const LocalDanmakuFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 解析本地弹幕文件，支持：
/// - Bilibili XML：`<d p="time,mode,fontsize,color,...">text</d>`
/// - DDP JSON：`{"comments":[{"p":"time,mode,color,uid","m":"text"}]}`
///   也接受裸数组，或本项目缓存里的 `{"danmakus":[...]}`。
///
/// 本地导入不依赖 DDP 凭证，只用于离线/演示；所有条目来源标记为 local。
List<DanmakuComment> parseLocalDanmakuFile(
  String content, {
  String fileName = '',
}) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) {
    throw const LocalDanmakuFormatException('文件内容为空');
  }
  final comments = trimmed.startsWith('<')
      ? _parseBilibiliXml(trimmed)
      : _parseDdpJson(trimmed);
  if (comments.isEmpty) {
    throw LocalDanmakuFormatException(
      fileName.isEmpty ? '没有解析到弹幕' : '$fileName 中没有解析到弹幕',
    );
  }
  return comments;
}

final _xmlDanmaku = RegExp(
  r'<d\s+p="([^"]*)"[^>]*>([\s\S]*?)</d>',
  caseSensitive: false,
);
final _entity = RegExp(r'&(#x?[0-9a-fA-F]+|amp|lt|gt|quot|apos);');

List<DanmakuComment> _parseBilibiliXml(String xml) {
  final comments = <DanmakuComment>[];
  final seen = <String>{};
  for (final match in _xmlDanmaku.allMatches(xml)) {
    final fields = match.group(1)!.split(',');
    if (fields.length < 4) continue;
    final time = double.tryParse(fields[0].trim());
    final mode = int.tryParse(fields[1].trim());
    final color = int.tryParse(fields[3].trim());
    if (time == null || time.isNaN || !time.isFinite || time < 0) continue;

    final text = _sanitize(_decodeEntities(match.group(2)!));
    if (text.isEmpty) continue;
    final key = '${time.toStringAsFixed(3)}|$text';
    if (!seen.add(key)) continue;

    comments.add(DanmakuComment(
      time: time,
      mode: _mode(mode),
      color: _color(color),
      uid: fields.length > 6 ? fields[6].trim() : '',
      text: text,
      source: DanmakuSource.local,
    ));
  }
  comments.sort((a, b) => a.time.compareTo(b.time));
  return comments;
}

List<DanmakuComment> _parseDdpJson(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    throw const LocalDanmakuFormatException('JSON 解析失败');
  }

  Object? list;
  if (decoded is List) {
    list = decoded;
  } else if (decoded is Map) {
    list = decoded['comments'] ?? decoded['danmakus'];
  }
  if (list is! List) {
    throw const LocalDanmakuFormatException('JSON 中没有 comments/danmakus 数组');
  }

  final comments = <DanmakuComment>[];
  final seen = <String>{};
  for (final entry in list) {
    if (entry is! Map) continue;
    final p = entry['p']?.toString() ?? '';
    final m = entry['m']?.toString() ?? '';
    final fields = p.split(',');
    if (fields.length < 4 || m.trim().isEmpty) continue;
    final time = double.tryParse(fields[0].trim());
    final mode = int.tryParse(fields[1].trim());
    final color = int.tryParse(fields[2].trim());
    if (time == null || time.isNaN || !time.isFinite || time < 0) continue;

    final text = _sanitize(m);
    if (text.isEmpty) continue;
    final key = '${time.toStringAsFixed(3)}|$text';
    if (!seen.add(key)) continue;

    comments.add(DanmakuComment(
      time: time,
      mode: _mode(mode),
      color: _color(color),
      uid: fields[3].trim(),
      text: text,
      source: DanmakuSource.local,
    ));
  }
  comments.sort((a, b) => a.time.compareTo(b.time));
  return comments;
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

String _sanitize(String input) {
  var text = input
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.length > 200) text = text.substring(0, 200);
  return text;
}

String _decodeEntities(String input) {
  return input.replaceAllMapped(_entity, (match) {
    final token = match.group(1)!.toLowerCase();
    switch (token) {
      case 'amp':
        return '&';
      case 'lt':
        return '<';
      case 'gt':
        return '>';
      case 'quot':
        return '"';
      case 'apos':
        return "'";
    }
    if (token.startsWith('#x')) {
      final code = int.tryParse(token.substring(2), radix: 16);
      if (code != null && code > 0 && code <= 0x10FFFF) {
        return String.fromCharCode(code);
      }
    } else if (token.startsWith('#')) {
      final code = int.tryParse(token.substring(1));
      if (code != null && code > 0 && code <= 0x10FFFF) {
        return String.fromCharCode(code);
      }
    }
    return match.group(0)!;
  });
}
