import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:fladder/danmaku/danmaku_models.dart';

class DdpComment {
  final int cid;
  final String p;
  final String m;

  const DdpComment({required this.cid, required this.p, required this.m});

  factory DdpComment.fromJson(Map<String, dynamic> json) {
    return DdpComment(
      cid: (json['cid'] as num?)?.toInt() ?? 0,
      p: json['p']?.toString() ?? '',
      m: json['m']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'cid': cid, 'p': p, 'm': m};
}

class DdpClient {
  DdpClient({
    required String baseUrl,
    required this.appId,
    required this.appSecret,
    http.Client? httpClient,
  })  : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final String appId;
  final String appSecret;
  final http.Client _http;

  static const _timeout = Duration(seconds: 15);

  static String signature({
    required String appId,
    required String appSecret,
    required int timestamp,
    required String path,
  }) {
    final raw = '$appId$timestamp$path$appSecret';
    return base64Encode(sha256.convert(utf8.encode(raw)).bytes);
  }

  Map<String, String> _headers(String path) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'JellyMaku/0.1 (https://github.com/tang-bai/JellyMaku)',
    };
    // 自建 DDP 兼容服务器（如 danmu_api）不校验签名；只有填了凭证才发认证头。
    if (appId.isNotEmpty && appSecret.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      headers['X-AppId'] = appId;
      headers['X-Timestamp'] = '$timestamp';
      headers['X-Signature'] = signature(
        appId: appId,
        appSecret: appSecret,
        timestamp: timestamp,
        path: path,
      );
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    final response =
        await _http.get(uri, headers: _headers(uri.path)).timeout(_timeout);

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      data = null;
    }

    if (response.statusCode != 200) {
      final headerMessage = response.headers['x-error-message'];
      final bodyMessage = data?['errorMessage'] ?? data?['message'];
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      throw DanmakuException(
        '${headerMessage ?? bodyMessage ?? 'DanDanPlay request failed (${response.statusCode})'}'
        '（${uri.path}）',
        statusCode: response.statusCode,
        retryAfterSeconds: retryAfter,
      );
    }

    if (data == null) {
      throw const DanmakuException('DanDanPlay returned invalid JSON');
    }
    return data;
  }

  Future<List<DanmakuCandidate>> searchEpisodes(
      String anime, int episode) async {
    final data = await _get(
      '/api/v2/search/episodes',
      query: {
        'anime': anime,
        'episode': '$episode',
        'v2': 'true',
      },
    );

    final candidates = <DanmakuCandidate>[];
    final animes = data['animes'];
    if (animes is List) {
      for (final animeEntry in animes) {
        if (animeEntry is! Map) continue;
        final animeTitle = animeEntry['animeTitle']?.toString() ?? '';
        final episodes = animeEntry['episodes'];
        if (episodes is! List) continue;
        for (final episodeEntry in episodes) {
          if (episodeEntry is! Map) continue;
          final episodeId = (episodeEntry['episodeId'] as num?)?.toInt();
          if (episodeId == null || episodeId <= 0) continue;
          candidates.add(DanmakuCandidate(
            episodeId: episodeId,
            animeTitle: animeTitle,
            episodeTitle: episodeEntry['episodeTitle']?.toString() ?? '',
            shift: (episodeEntry['shift'] as num?)?.toDouble() ?? 0,
            url: episodeEntry['url']?.toString() ?? '',
          ));
        }
      }
    }
    return candidates;
  }

  /// 手动匹配第一步：按番名搜索弹弹play 的番剧条目。
  Future<List<DanmakuAnime>> searchAnime(String anime) async {
    final data = await _get(
      '/api/v2/search/episodes',
      query: {'anime': anime, 'v2': 'true'},
    );

    final animes = <DanmakuAnime>[];
    final rawAnimes = data['animes'];
    if (rawAnimes is List) {
      for (final entry in rawAnimes) {
        if (entry is! Map) continue;
        final animeId = (entry['animeId'] as num?)?.toInt();
        final title = entry['animeTitle']?.toString() ?? '';
        if (animeId == null || animeId <= 0 || title.isEmpty) continue;
        final episodes = <DanmakuEpisodeRef>[];
        final rawEpisodes = entry['episodes'];
        if (rawEpisodes is List) {
          for (final episodeEntry in rawEpisodes) {
            if (episodeEntry is! Map) continue;
            final episodeId = (episodeEntry['episodeId'] as num?)?.toInt();
            if (episodeId == null || episodeId <= 0) continue;
            episodes.add(DanmakuEpisodeRef(
              episodeId: episodeId,
              episodeTitle:
                  episodeEntry['episodeTitle']?.toString() ?? '',
              url: episodeEntry['url']?.toString() ?? '',
            ));
          }
        }
        animes.add(DanmakuAnime(
          animeId: animeId,
          animeTitle: title,
          typeDescription: entry['typeDescription']?.toString() ?? '',
          episodes: episodes,
        ));
      }
    }
    return animes;
  }

  /// 手动匹配第二步：列出某个番剧的全部分集。
  Future<List<DanmakuEpisodeRef>> getEpisodes(int animeId) async {
    final data = await _get('/api/v2/bangumi/$animeId');

    final episodes = <DanmakuEpisodeRef>[];
    final bangumi = data['bangumi'];
    if (bangumi is Map) {
      final rawEpisodes = bangumi['episodes'];
      if (rawEpisodes is List) {
        for (final entry in rawEpisodes) {
          if (entry is! Map) continue;
          final episodeId = (entry['episodeId'] as num?)?.toInt();
          if (episodeId == null || episodeId <= 0) continue;
          episodes.add(DanmakuEpisodeRef(
            episodeId: episodeId,
            episodeTitle: entry['episodeTitle']?.toString() ?? '',
            url: entry['url']?.toString() ?? '',
          ));
        }
      }
    }
    return episodes;
  }

  Future<List<DdpComment>> getComments(
    int episodeId, {
    int chConvert = 1,
    bool withRelated = true,
    String url = '',
  }) async {
    final query = {
      'withRelated': withRelated ? 'true' : 'false',
      'chConvert': '$chConvert',
    };
    final normalized = _normalizeVideoUrl(url);

    // danmu_api 的 /comment/{id} 依赖它自己的内存映射，直接请求常为空；
    // 它支持 /comment?url=<原始页面>，用搜索结果里的 url 最稳。
    Map<String, dynamic>? data;
    if (normalized.isNotEmpty) {
      try {
        data = await _get(
          '/api/v2/comment',
          query: {...query, 'url': normalized},
        );
      } on DanmakuException {
        // 候选 url 可能不是绝对 http(s)，或被服务器判定无效；退回 id 路由。
        data = null;
      }
    }
    data ??= await _get(
      '/api/v2/comment/$episodeId',
      query: query,
    );

    var comments = _parseComments(data['comments']);
    if (comments.isEmpty && normalized.isNotEmpty && episodeId > 0) {
      // URL 命中但 0 条时再试一次 id（服务器可能刚重启、映射丢失）。
      try {
        final fallback = await _get(
          '/api/v2/comment/$episodeId',
          query: query,
        );
        final fallbackComments = _parseComments(fallback['comments']);
        if (fallbackComments.isNotEmpty) comments = fallbackComments;
      } catch (_) {
        // 保留空结果，交给上层显示“暂无弹幕”。
      }
    }
    return comments;
  }

  List<DdpComment> _parseComments(Object? rawComments) {
    final comments = <DdpComment>[];
    if (rawComments is List) {
      for (final entry in rawComments) {
        if (entry is! Map) continue;
        final json = entry.map((key, value) => MapEntry(key.toString(), value));
        final comment = DdpComment.fromJson(json);
        if (comment.p.isNotEmpty && comment.m.isNotEmpty) {
          comments.add(comment);
        }
      }
    }
    return comments;
  }

  /// 只接受绝对 http(s)、协议相对或 local: 资源；其余交给 id 路由。
  String _normalizeVideoUrl(String raw) {
    var url = raw.trim();
    if (url.startsWith('local:')) return url;
    if (url.startsWith('//')) url = 'https:$url';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.contains('.') && !url.contains(' ')) return 'https://$url';
    return '';
  }

  Future<void> testConnection() async {
    await searchEpisodes('test', 1);
  }

  void dispose() {
    _http.close();
  }
}
