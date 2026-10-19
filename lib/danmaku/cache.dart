import 'dart:convert';
import 'dart:io';

import 'package:fladder/danmaku/ddp_client.dart';

class DanmakuCache {
  DanmakuCache(this.root);

  final Directory root;

  Future<File> _file(String name) async {
    await root.create(recursive: true);
    return File('${root.path}${Platform.pathSeparator}$name');
  }

  Future<List<DdpComment>?> readComments(
    int episodeId,
    int chConvert,
    int ttlDays,
  ) async {
    if (ttlDays <= 0) return null;
    final file = await _file('comments-$episodeId-$chConvert.json');
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
          .map((entry) => DdpComment.fromJson(Map<String, dynamic>.from(entry)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeComments(
    int episodeId,
    int chConvert,
    List<DdpComment> comments,
  ) async {
    final file = await _file('comments-$episodeId-$chConvert.json');
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
