import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:fladder/danmaku/danmaku_api_client.dart';

/// 评论缓存的稳定 key。
///
/// danmu_api 的 episodeId 只在其服务端内存映射里有意义，跨服务器/重启不稳定；
/// 以“服务器 + 原始页面 URL”的哈希做 key，换服务器不会串数据。
String danmakuCommentCacheKey({
  required String baseUrl,
  String url = '',
  int episodeId = 0,
}) {
  final normalizedUrl = url.trim();
  final raw = normalizedUrl.isNotEmpty
      ? '$baseUrl|$normalizedUrl'
      : '$baseUrl|id:$episodeId';
  return sha1.convert(utf8.encode(raw)).toString();
}

class DanmakuCache {
  DanmakuCache(this.root);

  final Directory root;

  Future<File> _file(String name) async {
    await root.create(recursive: true);
    return File('${root.path}${Platform.pathSeparator}$name');
  }

  Future<List<DanmakuApiComment>?> readComments(
    String key,
    int ttlDays,
  ) async {
    if (ttlDays <= 0) return null;
    final file = await _file('comments-$key.json');
    if (!await file.exists()) return null;
    final stat = await file.stat();
    if (DateTime.now().difference(stat.modified) > Duration(days: ttlDays)) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((entry) =>
              DanmakuApiComment.fromJson(Map<String, dynamic>.from(entry)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeComments(
    String key,
    List<DanmakuApiComment> comments,
  ) async {
    final file = await _file('comments-$key.json');
    await _writeAtomic(
        file, jsonEncode(comments.map((e) => e.toJson()).toList()));
  }

  Future<Map<String, dynamic>?> readMapping(String itemId) async {
    final file = await _file('mapping.json');
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final value = decoded[itemId];
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> writeMapping(String itemId, Map<String, dynamic> value) async {
    final file = await _file('mapping.json');
    Map<String, dynamic> all = {};
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) all = Map<String, dynamic>.from(decoded);
      } catch (_) {
        all = {};
      }
    }
    all[itemId] = value;
    await _writeAtomic(file, jsonEncode(all));
  }

  Future<void> removeMapping(String itemId) async {
    final file = await _file('mapping.json');
    if (!await file.exists()) return;
    Map<String, dynamic> all;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      all = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }
    if (all.remove(itemId) == null) return;
    if (all.isEmpty) {
      await file.delete();
    } else {
      await _writeAtomic(file, jsonEncode(all));
    }
  }

  Future<void> clear() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }

  Future<void> _writeAtomic(File file, String contents) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(contents, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }
}
