import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/items/episode_model.dart';
import 'package:fladder/models/items/movie_model.dart';
import 'package:fladder/models/playback/playback_model.dart';

enum DanmakuMode {
  scroll,
  top,
  bottom,
}

/// 弹幕来源。
///
/// 实测弹弹play `withRelated=true` 的响应里，`p` 的第 4 段是用户 id（十六进制），
/// 不是 BiliBili/Gamer 标签；第三方弹幕已经被聚合进同一列表，客户端无法按站过滤。
/// 因此这里只区分“在线聚合”与“本地导入”。
enum DanmakuSource {
  danDanPlay,
  local,
}

class DanmakuComment {
  final double time;
  final DanmakuMode mode;
  final int color;
  final String uid;
  final String text;
  final DanmakuSource source;

  const DanmakuComment({
    required this.time,
    required this.mode,
    required this.color,
    required this.uid,
    required this.text,
    this.source = DanmakuSource.danDanPlay,
  });
}

/// 手动匹配用的搜索结果：弹弹play 的番剧条目。
class DanmakuAnime {
  final int animeId;
  final String animeTitle;
  final String typeDescription;

  /// 自建 DDP 兼容服务器（danmu_api）会把分集直接放在搜索结果里。
  /// 官方 DDP 的 animes[] 不含分集，需要在选中番剧后再请求 /bangumi/{id}。
  final List<DanmakuEpisodeRef> episodes;

  const DanmakuAnime({
    required this.animeId,
    required this.animeTitle,
    this.typeDescription = '',
    this.episodes = const [],
  });
}

/// 手动匹配用的分集条目。
class DanmakuEpisodeRef {
  final int episodeId;
  final String episodeTitle;

  /// danmu_api 的分集带原始页面 URL；官方 DDP 没有该字段。
  final String url;

  const DanmakuEpisodeRef({
    required this.episodeId,
    required this.episodeTitle,
    this.url = '',
  });
}

class DanmakuCandidate {
  final int episodeId;
  final String animeTitle;
  final String episodeTitle;
  final double shift;
  final String url;

  const DanmakuCandidate({
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    this.shift = 0,
    this.url = '',
  });
}

class DanmakuMatch {
  final int episodeId;
  final String animeTitle;
  final String episodeTitle;
  final double shift;
  final String source;
  final String url;

  const DanmakuMatch({
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.shift,
    required this.source,
    this.url = '',
  });
}

class DanmakuMediaInfo {
  final String itemId;
  final String name;
  final String? seriesName;
  final int? episode;
  final int? season;
  final bool isMovie;
  final int durationSeconds;
  final String? tmdbId;

  const DanmakuMediaInfo({
    required this.itemId,
    required this.name,
    this.seriesName,
    this.episode,
    this.season,
    this.isMovie = false,
    this.durationSeconds = 0,
    this.tmdbId,
  });

  String get searchTitle {
    final series = seriesName?.trim();
    if (series != null && series.isNotEmpty) return series;
    return name.trim();
  }

  int get episodeNumber => episode ?? 1;

  static DanmakuMediaInfo? fromPlayback(PlaybackModel? model) {
    final item = model?.item;
    if (item == null) return null;

    final episodeModel = item is EpisodeModel ? item : null;
    final movieModel = item is MovieModel ? item : null;
    final series = episodeModel?.seriesName?.trim();
    final isMovie = item is MovieModel || item.type == FladderItemType.movie;
    final providerIds = movieModel?.providerIds;

    return DanmakuMediaInfo(
      itemId: item.id,
      name: item.name,
      seriesName: series == null || series.isEmpty ? null : series,
      episode: episodeModel?.episode ?? 1,
      season: episodeModel?.season,
      isMovie: isMovie,
      durationSeconds: item.overview.runTime?.inSeconds ?? 0,
      tmdbId:
          providerIds?['Tmdb']?.toString() ?? providerIds?['tmdb']?.toString(),
    );
  }
}

class DanmakuException implements Exception {
  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  const DanmakuException(this.message,
      {this.statusCode, this.retryAfterSeconds});

  @override
  String toString() => message;
}
