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
/// 弹弹play 在 `withRelated=true` 时会把第三方站点的弹幕合并进同一个响应，
/// 并用 `p` 的第 4 段标记来源（BiliBili / Gamer）；没有标记的条目属于
/// 弹弹play 自有库。这里按 Kazumi 的口径归一为三类，其余一律算弹弹play。
enum DanmakuSource {
  biliBili,
  gamer,
  danDanPlay,
}

DanmakuSource parseDanmakuSource(String raw) {
  final value = raw.toLowerCase();
  if (value.contains('bilibili')) return DanmakuSource.biliBili;
  if (value.contains('gamer')) return DanmakuSource.gamer;
  return DanmakuSource.danDanPlay;
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

  const DanmakuAnime({
    required this.animeId,
    required this.animeTitle,
    this.typeDescription = '',
  });
}

/// 手动匹配用的分集条目。
class DanmakuEpisodeRef {
  final int episodeId;
  final String episodeTitle;

  const DanmakuEpisodeRef({
    required this.episodeId,
    required this.episodeTitle,
  });
}

class DanmakuCandidate {
  final int episodeId;
  final String animeTitle;
  final String episodeTitle;
  final double shift;

  const DanmakuCandidate({
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    this.shift = 0,
  });
}

class DanmakuMatch {
  final int episodeId;
  final String animeTitle;
  final String episodeTitle;
  final double shift;
  final String source;

  const DanmakuMatch({
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.shift,
    required this.source,
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
