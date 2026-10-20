import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:fladder/danmaku/danmaku_models.dart';

/// danmu_api 返回的原始评论。
///
/// p 的格式为 `时间,模式,颜色,[来源]`；与旧弹幕协议不同，p[3] 是来源标签
/// （如 `[bilibili1]`），不是用户 id。解析时不要把它当用户。
class DanmakuApiComment {
  final int cid;
  final String p;
  final String m;

  const DanmakuApiComment(
      {required this.cid, required this.p, required this.m});

  factory DanmakuApiComment.fromJson(Map<String, dynamic> json) {
    return DanmakuApiComment(
      cid: (json['cid'] as num?)?.toInt() ?? 0,
      p: json['p']?.toString() ?? '',
      m: json['m']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'cid': cid, 'p': p, 'm': m};
}

/// 规范化弹幕 API 基址；空值回退到公共 danmu_api 实例。
String normalizeDanmakuApiBase(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return kDefaultDanmuApiBase;
  return value.replaceAll(RegExp(r'/+$'), '');
}

/// danmu_api 客户端。
///
/// 只依赖 danmu_api 的 HTTP 接口，不发送应用凭证，也没有旧弹幕签名。
/// 自建服务若设置了 TOKEN，把 `/{TOKEN}` 拼到 baseUrl 路径里即可。
class DanmakuApiClient {
  DanmakuApiClient({
    required String baseUrl,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
  })  : baseUrl = normalizeDanmakuApiBase(baseUrl),
        _http = httpClient ?? http.Client(),
        _timeout = timeout;

  final String baseUrl;
  final http.Client _http;
  final Duration _timeout;

  static const _userAgent =
      'JellyMaku/0.1 (https://github.com/tang-bai/JellyMaku)';

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      };

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    final response =
        await _send(() => _http.get(uri, headers: _headers()), uri);
    return _decode(response, uri);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    final response = await _send(
      () => _http.post(
        uri,
        headers: {
          ..._headers(),
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      ),
      uri,
    );
    return _decode(response, uri);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw DanmakuException('弹幕 API 请求超时（${uri.path}）');
    } on http.ClientException catch (error) {
      throw DanmakuException('无法连接弹幕 API：${error.message}（${uri.host}）');
    } on Exception catch (error) {
      final detail = error.toString();
      final hint =
          detail.contains('Handshake') ? '；若使用自建 HTTPS，请检查证书是否受信任' : '';
      throw DanmakuException('无法连接弹幕 API：$detail$hint（${uri.host}）');
    }
  }

  Map<String, dynamic> _decode(http.Response response, Uri uri) {
    Map<String, dynamic>? data;
    try {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      data = null;
    }

    if (response.statusCode != 200) {
      final headerMessage = response.headers['x-error-message'];
      final bodyMessage = data?['errorMessage'] ?? data?['message'];
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      final hint = response.statusCode == 401 || response.statusCode == 403
          ? '（自建 danmu_api 若设置了 TOKEN，请把 /{TOKEN} 加到 API 地址末尾）'
          : '';
      throw DanmakuException(
        '${headerMessage ?? bodyMessage ?? '弹幕 API 请求失败（${response.statusCode}）'}'
        '$hint（${uri.path}）',
        statusCode: response.statusCode,
        retryAfterSeconds: retryAfter,
      );
    }

    if (data == null) {
      throw const DanmakuException('弹幕 API 返回了无效 JSON');
    }
    final errorCode = data['errorCode'];
    if (data['success'] == false || (errorCode is num && errorCode != 0)) {
      throw DanmakuException(
        data['errorMessage']?.toString() ?? '弹幕 API 请求失败（${uri.path}）',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  /// 自动匹配：danmu_api 的 fileName 匹配接口。
  ///
  /// fileName 建议使用 `标题 S01E02`（电影直接用片名）；服务端会做标题/季集
  /// 解析与平台优选，比客户端对 search/episodes 结果打分更准。
  Future<List<DanmakuCandidate>> matchFile(String fileName) async {
    final name = fileName.trim();
    if (name.isEmpty) return const [];
    final data = await _post('/api/v2/match', {'fileName': name});
    if (data['isMatched'] == false) return const [];
    return _parseCandidates(data['matches']);
  }

  Future<List<DanmakuCandidate>> searchEpisodes(
    String anime, [
    int? episode,
  ]) async {
    final title = anime.trim();
    if (title.isEmpty) return const [];
    final query = <String, String>{'anime': title};
    if (episode != null && episode > 0) query['episode'] = '$episode';
    final data = await _get('/api/v2/search/episodes', query: query);
    return _parseCandidatesFromAnimes(data['animes']);
  }

  /// 手动匹配第一步：搜索番剧，并保留搜索结果内嵌的分集。
  ///
  /// danmu_api 没有可用的 `/bangumi/{animeId}`（实测 404），所以必须一次
  /// 拿到分集；这里不复用 `/search/anime`。
  Future<List<DanmakuAnime>> searchAnime(String keyword) async {
    final title = keyword.trim();
    if (title.isEmpty) return const [];
    final data = await _get(
      '/api/v2/search/episodes',
      query: {'anime': title},
    );

    final animes = <DanmakuAnime>[];
    final rawAnimes = data['animes'];
    if (rawAnimes is List) {
      for (final entry in rawAnimes) {
        if (entry is! Map) continue;
        final animeId = (entry['animeId'] as num?)?.toInt();
        final animeTitle = entry['animeTitle']?.toString() ?? '';
        if (animeId == null || animeId <= 0 || animeTitle.isEmpty) continue;
        animes.add(DanmakuAnime(
          animeId: animeId,
          animeTitle: animeTitle,
          typeDescription: entry['typeDescription']?.toString() ?? '',
          episodes: _parseEpisodeRefs(entry['episodes']),
        ));
      }
    }
    return animes;
  }

  /// 拉取弹幕。
  ///
  /// 主路径是 `/comment?url=<原始页面>&format=json`；id 路由在 danmu_api 上
  /// 常返回 404（搜索得到的 episodeId 无法跨请求稳定映射），只作兜底。
  ///
  /// renren/hanjutv 等源返回的 `url` 不是 http URL，而是 `源-集` 复合 ID；
  /// 这时用无状态的 `/segmentcomment`（带 type + 原样 ID），不依赖服务端搜索缓存。
  Future<List<DanmakuApiComment>> getComments({
    String url = '',
    int episodeId = 0,
    String provider = '',
  }) async {
    final normalized = _normalizeVideoUrl(url);
    if (normalized.isNotEmpty) {
      try {
        final data = await _get(
          '/api/v2/comment',
          query: {'url': normalized, 'format': 'json'},
        );
        return _parseComments(data['comments']);
      } on DanmakuException catch (error) {
        if (error.statusCode != 400 && error.statusCode != 404) rethrow;
      }
    }

    final opaqueId = url.trim();
    if (normalized.isEmpty && opaqueId.isNotEmpty && provider.isNotEmpty) {
      try {
        final data = await _post(
          '/api/v2/segmentcomment',
          {
            'type': provider,
            'segment_start': 0,
            'segment_end': 86400000,
            'url': opaqueId,
          },
          query: const {'format': 'json'},
        );
        final comments = _parseComments(data['comments']);
        if (comments.isNotEmpty) return comments;
      } on DanmakuException catch (error) {
        if (error.statusCode != 400 && error.statusCode != 404) rethrow;
      }
    }

    if (episodeId > 0) {
      try {
        final data = await _get(
          '/api/v2/comment/$episodeId',
          query: const {'format': 'json'},
        );
        return _parseComments(data['comments']);
      } on DanmakuException catch (error) {
        if (error.statusCode != 404) rethrow;
      }
    }
    return const [];
  }

  Future<void> testConnection() async {
    await _get('/api/v2/search/episodes', query: const {'anime': 'test'});
  }

  List<DanmakuCandidate> _parseCandidates(Object? rawMatches) {
    final candidates = <DanmakuCandidate>[];
    if (rawMatches is! List) return candidates;
    for (final entry in rawMatches) {
      if (entry is! Map) continue;
      final episodeId = (entry['episodeId'] as num?)?.toInt();
      if (episodeId == null || episodeId <= 0) continue;
      final episodeTitle = entry['episodeTitle']?.toString() ?? '';
      candidates.add(DanmakuCandidate(
        episodeId: episodeId,
        animeTitle: entry['animeTitle']?.toString() ?? '',
        episodeTitle: episodeTitle,
        shift: (entry['shift'] as num?)?.toDouble() ?? 0,
        url: entry['url']?.toString() ?? '',
        provider: danmakuProviderFromTitle(episodeTitle),
      ));
    }
    return candidates;
  }

  List<DanmakuCandidate> _parseCandidatesFromAnimes(Object? rawAnimes) {
    final candidates = <DanmakuCandidate>[];
    if (rawAnimes is! List) return candidates;
    for (final animeEntry in rawAnimes) {
      if (animeEntry is! Map) continue;
      final animeTitle = animeEntry['animeTitle']?.toString() ?? '';
      final episodes = animeEntry['episodes'];
      if (episodes is! List) continue;
      for (final episodeEntry in episodes) {
        if (episodeEntry is! Map) continue;
        final episodeId = (episodeEntry['episodeId'] as num?)?.toInt();
        if (episodeId == null || episodeId <= 0) continue;
        final episodeTitle = episodeEntry['episodeTitle']?.toString() ?? '';
        candidates.add(DanmakuCandidate(
          episodeId: episodeId,
          animeTitle: animeTitle,
          episodeTitle: episodeTitle,
          shift: (episodeEntry['shift'] as num?)?.toDouble() ?? 0,
          url: episodeEntry['url']?.toString() ?? '',
          provider: danmakuProviderFromTitle(episodeTitle),
        ));
      }
    }
    return candidates;
  }

  List<DanmakuEpisodeRef> _parseEpisodeRefs(Object? rawEpisodes) {
    final episodes = <DanmakuEpisodeRef>[];
    if (rawEpisodes is! List) return episodes;
    for (final entry in rawEpisodes) {
      if (entry is! Map) continue;
      final episodeId = (entry['episodeId'] as num?)?.toInt();
      if (episodeId == null || episodeId <= 0) continue;
      final episodeTitle = entry['episodeTitle']?.toString() ?? '';
      episodes.add(DanmakuEpisodeRef(
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        url: entry['url']?.toString() ?? '',
        provider: danmakuProviderFromTitle(episodeTitle),
      ));
    }
    return episodes;
  }

  List<DanmakuApiComment> _parseComments(Object? rawComments) {
    final comments = <DanmakuApiComment>[];
    if (rawComments is! List) return comments;
    for (final entry in rawComments) {
      if (entry is! Map) continue;
      final json = entry.map((key, value) => MapEntry(key.toString(), value));
      final comment = DanmakuApiComment.fromJson(json);
      if (comment.p.isNotEmpty && comment.m.isNotEmpty) {
        comments.add(comment);
      }
    }
    return comments;
  }

  /// 只接受绝对 http(s)、协议相对或裸域名；其余交给 id 路由/上层重搜。
  String _normalizeVideoUrl(String raw) {
    var url = raw.trim();
    if (url.startsWith('//')) url = 'https:$url';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.contains('.') && !url.contains(' ')) return 'https://$url';
    return '';
  }

  void dispose() {
    _http.close();
  }
}
