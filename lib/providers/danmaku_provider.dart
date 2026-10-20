import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fladder/danmaku/cache.dart';
import 'package:fladder/danmaku/comment_parser.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/danmaku/local_import.dart';
import 'package:fladder/danmaku/matcher.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';
import 'package:fladder/providers/settings/danmaku_settings_provider.dart';

const _officialApiBase = 'https://api.dandanplay.net';

enum DanmakuLoadStatus {
  idle,
  disabled,
  loading,
  ready,
  noCredentials,
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

    // 本地文件优先于 DDP：无凭证也能播放/演示，且不回源到弹弹play。
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

    final customServer = _isCustomServer(settings);
    if (!settings.hasCredentials && !customServer) {
      _media = media;
      state = DanmakuState(
        status: DanmakuLoadStatus.noCredentials,
        itemId: media.itemId,
      );
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

    DdpClient? client;
    try {
      final cache = await _cache();
      final manual = await cache.readMapping(media.itemId);
      client = DdpClient(
        baseUrl: settings.apiBase,
        appId: settings.appId,
        appSecret: settings.appSecret,
      );

      var match = await matchDanmaku(
        client,
        media,
        manual: manual,
        settings: settings,
      );
      if (generation != _generation) return;

      // 旧 mapping 可能只有 episodeId 没有 url（官方 DDP 时代写入），
      // 自建服务器上 id 路由常 404；重新搜索一次，拿带 http(s) 的分集。
      if (customServer &&
          !match.url.trim().startsWith('http') &&
          media.searchTitle.trim().isNotEmpty) {
        final candidates = await client.searchEpisodes(
          media.searchTitle,
          media.episodeNumber,
        );
        final withUrl = candidates.where(
          (candidate) => candidate.url.trim().startsWith('http'),
        );
        if (withUrl.isNotEmpty) {
          final candidate = withUrl.first;
          match = DanmakuMatch(
            episodeId: candidate.episodeId,
            animeTitle: candidate.animeTitle,
            episodeTitle: candidate.episodeTitle,
            shift: candidate.shift,
            source: 'search',
            url: candidate.url,
          );
        }
      }
      if (generation != _generation) return;

      // URL 型结果（danmu_api）的 episodeId 只在该服务器内有意义，
      // 不写数值 key 的缓存，避免换服务器后串数据。
      var raw = match.url.isEmpty
          ? await cache.readComments(
              match.episodeId,
              settings.chConvert,
              settings.cacheDays,
            )
          : null;
      if (raw == null) {
        raw = await _fetchCommentsWithFallback(
          client,
          media,
          match,
          settings,
          customServer,
        );
        if (raw.isNotEmpty) {
          if (match.url.isEmpty) {
            await cache.writeComments(match.episodeId, settings.chConvert, raw);
          }
          await cache.writeMapping(media.itemId, {
            'episodeId': match.episodeId,
            'animeTitle': match.animeTitle,
            'episodeTitle': match.episodeTitle,
            'shift': match.shift,
            'source': match.source,
            'url': match.url,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
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

  /// 先试匹配到的地址；自建服务器上若源不可用/404，就按标题+集号换源重试。
  Future<List<DdpComment>> _fetchCommentsWithFallback(
    DdpClient client,
    DanmakuMediaInfo media,
    DanmakuMatch match,
    DanmakuSettingsModel settings,
    bool customServer,
  ) async {
    try {
      final raw = await client.getComments(
        match.episodeId,
        chConvert: settings.chConvert,
        url: match.url,
      );
      if (raw.isNotEmpty || !customServer) return raw;
    } on DanmakuException {
      if (!customServer) rethrow;
    }

    if (media.searchTitle.trim().isEmpty) return const [];
    final candidates = await client.searchEpisodes(
      media.searchTitle,
      media.episodeNumber,
    );
    final ordered = candidates
        .where((candidate) =>
            candidate.url.trim().startsWith('http') &&
            candidate.episodeId != match.episodeId)
        .toList()
      ..sort((a, b) => _sourceRank(b.url).compareTo(_sourceRank(a.url)));

    for (final candidate in ordered.take(5)) {
      try {
        final raw = await client.getComments(
          candidate.episodeId,
          chConvert: settings.chConvert,
          url: candidate.url,
        );
        if (raw.isNotEmpty) return raw;
      } on DanmakuException {
        continue;
      }
    }
    return const [];
  }

  int _sourceRank(String url) {
    final value = url.toLowerCase();
    if (value.contains('bilibili.com')) return 3;
    if (value.contains('gamer.com.tw')) return 2;
    return 1;
  }

  Future<void> reload() async {
    final media = _media;
    if (media == null) return;
    state = const DanmakuState();
    await load(media, force: true);
  }

  /// 手动匹配第一步：搜索番剧。调用方负责错误提示。
  Future<List<DanmakuAnime>> searchAnime(String keyword) async {
    final client = _requireClient();
    try {
      return await client.searchAnime(keyword.trim());
    } finally {
      client.dispose();
    }
  }

  /// 手动匹配第二步：拉取某个番剧的分集列表。
  Future<List<DanmakuEpisodeRef>> episodesForAnime(int animeId) async {
    final client = _requireClient();
    try {
      return await client.getEpisodes(animeId);
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
      'updatedAt': DateTime.now().toIso8601String(),
    });
    state = const DanmakuState();
    await load(media, force: true);
  }

  /// 删除当前条目的手动映射，回退到自动匹配。
  Future<void> clearManualMatch() async {
    final media = _media;
    if (media == null) return;
    final cache = await _cache();
    await cache.removeMapping(media.itemId);
    state = const DanmakuState();
    await load(media, force: true);
  }

  DdpClient _requireClient() {
    final settings = ref.read(danmakuSettingsProvider);
    if (!settings.hasCredentials && !_isCustomServer(settings)) {
      throw const DanmakuException(
          '请展开“高级”填写弹弹play AppId，或填写自建服务器地址/使用本地导入');
    }
    return DdpClient(
      baseUrl: settings.apiBase,
      appId: settings.appId,
      appSecret: settings.appSecret,
    );
  }

  bool _isCustomServer(DanmakuSettingsModel settings) {
    final base = settings.apiBase.trim().replaceAll(RegExp(r'/+$'), '');
    return base.isNotEmpty && base != _officialApiBase;
  }

  void stop() {
    _generation++;
    _media = null;
    state = const DanmakuState();
  }

  String _localFileName(String path) =>
      path.split(RegExp(r'[\\/]')).last;

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
