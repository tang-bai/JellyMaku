import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fladder/danmaku/cache.dart';
import 'package:fladder/danmaku/comment_parser.dart';
import 'package:fladder/danmaku/danmaku_api_client.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/local_import.dart';
import 'package:fladder/danmaku/matcher.dart';
import 'package:fladder/providers/settings/danmaku_settings_provider.dart';

enum DanmakuLoadStatus {
  idle,
  disabled,
  loading,
  ready,
  noMatch,
  error,
}

class DanmakuState {
  final DanmakuLoadStatus status;
  final List<DanmakuComment> comments;
  final String? itemId;
  final String? title;
  final String? error;
  final DanmakuMatch? match;

  const DanmakuState({
    this.status = DanmakuLoadStatus.idle,
    this.comments = const [],
    this.itemId,
    this.title,
    this.error,
    this.match,
  });

  bool get hasComments => comments.isNotEmpty;

  DanmakuState copyWith({
    DanmakuLoadStatus? status,
    List<DanmakuComment>? comments,
    String? itemId,
    String? title,
    String? error,
    DanmakuMatch? match,
  }) {
    return DanmakuState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      error: error ?? this.error,
      match: match ?? this.match,
    );
  }
}

final danmakuProvider =
    StateNotifierProvider<DanmakuController, DanmakuState>((ref) {
  return DanmakuController(ref);
});

class DanmakuController extends StateNotifier<DanmakuState> {
  DanmakuController(this.ref) : super(const DanmakuState());

  final Ref ref;
  int _generation = 0;
  DanmakuMediaInfo? _media;
  DanmakuCache? _cacheInstance;

  DanmakuMediaInfo? get media => _media;

  Future<void> load(DanmakuMediaInfo? media, {bool force = false}) async {
    if (media == null) {
      stop();
      return;
    }

    final settings = ref.read(danmakuSettingsProvider);
    if (!settings.enabled) {
      _media = media;
      state = DanmakuState(
        status: DanmakuLoadStatus.disabled,
        itemId: media.itemId,
      );
      return;
    }

    // 本地文件优先于在线 API：不依赖网络，也不写评论缓存。
    final localFile = settings.localFile?.trim() ?? '';
    if (localFile.isNotEmpty) {
      _media = media;
      final generation = ++_generation;
      state = DanmakuState(
        status: DanmakuLoadStatus.loading,
        itemId: media.itemId,
      );
      try {
        final file = File(localFile);
        if (!await file.exists()) {
          throw const LocalDanmakuFormatException('本地弹幕文件不存在');
        }
        final name = _localFileName(localFile);
        final comments = parseLocalDanmakuFile(
          await file.readAsString(),
          fileName: name,
        );
        if (generation != _generation) return;
        state = DanmakuState(
          status: DanmakuLoadStatus.ready,
          comments: comments,
          itemId: media.itemId,
          title: name,
          match: DanmakuMatch(
            episodeId: 0,
            animeTitle: name,
            episodeTitle: '',
            shift: 0,
            source: 'local',
          ),
        );
      } catch (error) {
        if (generation != _generation) return;
        state = DanmakuState(
          status: DanmakuLoadStatus.error,
          itemId: media.itemId,
          error: '本地弹幕读取失败：$error',
        );
      }
      return;
    }

    if (!force &&
        _media?.itemId == media.itemId &&
        state.status == DanmakuLoadStatus.ready) {
      return;
    }

    _media = media;
    final generation = ++_generation;
    state = DanmakuState(
      status: DanmakuLoadStatus.loading,
      itemId: media.itemId,
    );

    DanmakuApiClient? client;
    try {
      final cache = await _cache();
      final mapping = await cache.readMapping(media.itemId);
      client = DanmakuApiClient(baseUrl: settings.effectiveApiBase);

      var match = await matchDanmaku(
        client,
        media,
        mapping: mapping,
        settings: settings,
      );
      if (generation != _generation) return;

      // 旧 mapping 可能只有 episodeId 没有 url（旧版本写入），而 danmu_api
      // 的 id 路由常 404；重新搜索一次，拿带 http(s) 的分集并更新匹配。
      if (match.url.isEmpty && media.searchTitle.isNotEmpty) {
        match = await _reSearchMatch(client, media, match);
        if (generation != _generation) return;
      }

      final cacheKey = danmakuCommentCacheKey(
        baseUrl: client.baseUrl,
        url: match.url,
        episodeId: match.episodeId,
      );
      var raw = await cache.readComments(cacheKey, settings.cacheDays);
      if (raw == null) {
        raw = await _fetchCommentsWithFallback(client, media, match);
        if (generation != _generation) return;
        if (raw.isNotEmpty) {
          await cache.writeComments(cacheKey, raw);
        }
      }

      if (raw.isEmpty) {
        final sourceLabel = match.provider.isEmpty ? '' : '在 ${match.provider} 源';
        state = DanmakuState(
          status: DanmakuLoadStatus.noMatch,
          itemId: media.itemId,
          title: match.animeTitle,
          match: match,
          error: '该分集$sourceLabel暂无可用弹幕，可尝试换一集或手动匹配其他来源',
        );
        return;
      }

      await cache.writeMapping(media.itemId, {
        'episodeId': match.episodeId,
        'animeTitle': match.animeTitle,
        'episodeTitle': match.episodeTitle,
        'shift': match.shift,
        'source': match.source,
        'url': match.url,
        'provider': match.provider,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (generation != _generation) return;

      final comments = parseDanmakuComments(raw, settings, shift: match.shift);
      state = DanmakuState(
        status: DanmakuLoadStatus.ready,
        comments: comments,
        itemId: media.itemId,
        title: match.animeTitle,
        match: match,
      );
    } on DanmakuNoMatch catch (error) {
      if (generation != _generation) return;
      state = DanmakuState(
        status: DanmakuLoadStatus.noMatch,
        itemId: media.itemId,
        error: error.toString(),
      );
    } on DanmakuException catch (error) {
      if (generation != _generation) return;
      state = DanmakuState(
        status: DanmakuLoadStatus.error,
        itemId: media.itemId,
        error: error.message,
      );
    } catch (error) {
      if (generation != _generation) return;
      state = DanmakuState(
        status: DanmakuLoadStatus.error,
        itemId: media.itemId,
        error: error.toString(),
      );
    } finally {
      client?.dispose();
    }
  }

  /// 旧 mapping 没有 url 时，按标题+集号重搜，优先选带 http(s) 的分集。
  Future<DanmakuMatch> _reSearchMatch(
    DanmakuApiClient client,
    DanmakuMediaInfo media,
    DanmakuMatch match,
  ) async {
    final candidates = await _searchEpisodes(
      client,
      media.searchTitle,
      media.isMovie ? null : media.episodeNumber,
    );
    final ordered = candidates
        .where((candidate) =>
            candidate.url.trim().isNotEmpty &&
            candidate.url.trim() != match.url.trim())
        .toList()
      ..sort((a, b) => _sourceRank(b.url).compareTo(_sourceRank(a.url)));
    if (ordered.isEmpty) return match;

    final candidate = ordered.first;
    return DanmakuMatch(
      episodeId: candidate.episodeId,
      animeTitle: candidate.animeTitle,
      episodeTitle: candidate.episodeTitle,
      shift: candidate.shift,
      source: 'search',
      url: candidate.url,
      provider: candidate.provider,
    );
  }

  /// 先试匹配到的地址；0 条/源不可用时按标题+集号换源重试。
  Future<List<DanmakuApiComment>> _fetchCommentsWithFallback(
    DanmakuApiClient client,
    DanmakuMediaInfo media,
    DanmakuMatch match,
  ) async {
    final primary = await client.getComments(
      url: match.url,
      episodeId: match.episodeId,
      provider: match.provider,
    );
    if (primary.isNotEmpty) return primary;

    final title = media.searchTitle.trim();
    if (title.isEmpty) return const [];

    final candidates = await _searchEpisodes(
      client,
      title,
      media.isMovie ? null : media.episodeNumber,
    );
    final ordered = candidates
        .where((candidate) =>
            candidate.url.trim().isNotEmpty &&
            candidate.url.trim() != match.url.trim())
        .toList()
      ..sort((a, b) => _sourceRank(b.url).compareTo(_sourceRank(a.url)));

    for (final candidate in ordered.take(5)) {
      try {
        final raw = await client.getComments(
          url: candidate.url,
          provider: candidate.provider,
        );
        if (raw.isNotEmpty) return raw;
      } on DanmakuException {
        continue;
      }
    }
    return const [];
  }

  /// 搜索标题变体；`标题 (2026)` 这类写法公共实例搜不到，去掉尾部年份/季集再试。
  Future<List<DanmakuCandidate>> _searchEpisodes(
    DanmakuApiClient client,
    String title,
    int? episode,
  ) async {
    for (final query in danmakuSearchQueries(title)) {
      final candidates = await client.searchEpisodes(query, episode);
      if (candidates.isNotEmpty) return candidates;
    }
    return const [];
  }

  int _sourceRank(String url) {
    final value = url.toLowerCase();
    if (value.contains('bilibili.com')) return 3;
    if (value.contains('gamer.com.tw') || value.contains('bahamut.com.tw')) {
      return 2;
    }
    return 1;
  }

  Future<void> reload() async {
    final media = _media;
    if (media == null) return;
    state = const DanmakuState();
    await load(media, force: true);
  }

  /// 手动匹配第一步：搜索番剧（分集内嵌在结果里）。调用方负责错误提示。
  Future<List<DanmakuAnime>> searchAnime(String keyword) async {
    final client = _requireClient();
    try {
      for (final query in danmakuSearchQueries(keyword)) {
        final animes = await client.searchAnime(query);
        if (animes.isNotEmpty) return animes;
      }
      return const [];
    } finally {
      client.dispose();
    }
  }

  /// 手动匹配第二步：拿某个番剧的分集。
  ///
  /// 正常情况下搜索结果已带分集；只有旧服务/异常响应才需要按番名重搜。
  Future<List<DanmakuEpisodeRef>> episodesForAnime(DanmakuAnime anime) async {
    if (anime.episodes.isNotEmpty) return anime.episodes;
    final client = _requireClient();
    try {
      final animes = await client.searchAnime(anime.animeTitle);
      for (final entry in animes) {
        if (entry.animeId == anime.animeId && entry.episodes.isNotEmpty) {
          return entry.episodes;
        }
      }
      return const [];
    } finally {
      client.dispose();
    }
  }

  /// 写入手动映射并重新加载当前条目（成功后 source 会变成 manual）。
  Future<void> applyManualMatch({
    required int episodeId,
    required String animeTitle,
    required String episodeTitle,
    double shift = 0,
    String url = '',
    String provider = '',
  }) async {
    final media = _media;
    if (media == null) {
      throw const DanmakuException('当前没有正在播放的条目');
    }
    final cache = await _cache();
    await cache.writeMapping(media.itemId, {
      'episodeId': episodeId,
      'animeTitle': animeTitle,
      'episodeTitle': episodeTitle,
      'shift': shift,
      'source': 'manual',
      'url': url,
      'provider': provider,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    state = const DanmakuState();
    await load(media, force: true);
  }

  /// 删除当前条目的匹配（自动/手动均可），回退到自动匹配。
  Future<void> clearManualMatch() async {
    final media = _media;
    if (media == null) return;
    final cache = await _cache();
    await cache.removeMapping(media.itemId);
    state = const DanmakuState();
    await load(media, force: true);
  }

  DanmakuApiClient _requireClient() {
    final settings = ref.read(danmakuSettingsProvider);
    return DanmakuApiClient(baseUrl: settings.effectiveApiBase);
  }

  void stop() {
    _generation++;
    _media = null;
    state = const DanmakuState();
  }

  String _localFileName(String path) => path.split(RegExp(r'[\\/]')).last;

  Future<DanmakuCache> _cache() async {
    final existing = _cacheInstance;
    if (existing != null) return existing;
    final support = await getApplicationSupportDirectory();
    final directory =
        Directory('${support.path}${Platform.pathSeparator}danmaku');
    return _cacheInstance = DanmakuCache(directory);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
