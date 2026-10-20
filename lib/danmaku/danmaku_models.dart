import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/items/episode_model.dart';
import 'package:fladder/models/items/movie_model.dart';
import 'package:fladder/models/playback/playback_model.dart';

/// 默认 danmu_api 实例；可通过设置覆盖为自建服务。
const String kDefaultDanmuApiBase = 'https://danmu.api.tangbai.cc';

enum DanmakuMode {
  scroll,
  top,
  bottom,
}

final _providerInTitle = RegExp(r'[【\[]([^】\]]+)[】\]]');

/// 从分集标题里提取来源标签，如 `【renren】 第01集` → `renren`。
String danmakuProviderFromTitle(String title) =>
    _providerInTitle.firstMatch(title)?.group(1)?.trim() ?? '';

/// 搜索用的标题变体：去掉尾部年份/季集/副标题，解决 `标题 (2026)` 搜不到的问题。
List<String> danmakuSearchQueries(String raw) {
  final base = raw.trim();
  if (base.isEmpty) return const [];
  final variants = <String>{base};
  final suffixes = [
    RegExp(r'[\s\-_]*[\(（]\d{4}[\)）]\s*$'),
    RegExp(r'\s*[Ss]\d{1,2}(?:[Ee]\d{1,4})?\s*$'),
    RegExp(r'\s*第\s*\d+\s*[集话季期]\s*$'),
  ];

  var value = base;
  // 反复剥后缀，覆盖“标题 (2026) S01E01”这类组合。
  for (var i = 0; i < 4; i++) {
    var next = value;
    for (final pattern in suffixes) {
      next = next.replaceAll(pattern, '').trim();
    }
    if (next == value || next.isEmpty) break;
    value = next;
    variants.add(value);
  }

  final colon = base.indexOf(RegExp(r'[：:]'));
  if (colon > 0) {
    final head = base.substring(0, colon).trim();
    if (head.isNotEmpty) variants.add(head);
  }

  return variants.toList(growable: false);
}

/// 弹幕来源。
///
/// danmu_api 会把多个站点（BiliBili/巴哈/爱优腾等）的弹幕聚合进同一列表，
/// 并用 `p[3]` 的 `[来源]` 标签标记；客户端不需要按站分别请求。
/// 这里只区分“在线聚合”与“本地导入”。
enum DanmakuSource {
  online,
  local,
}

class DanmakuComment {
  final double time;
  final DanmakuMode mode;
  final int color;
  final String uid;
  final String text;
  final DanmakuSource source;

  /// 在线来源标签（如 `bilibili1`）；本地导入为空。
  final String provider;

  const DanmakuComment({
    required this.time,
    required this.mode,
    required this.color,
    required this.uid,
    required this.text,
    this.source = DanmakuSource.online,
    this.provider = '',
  });
}

/// 手动匹配用的搜索结果：danmu_api 的番剧条目。
class DanmakuAnime {
  final int animeId;
  final String animeTitle;
  final String typeDescription;

  /// danmu_api 的 search/episodes 会把分集直接放在搜索结果里；
  /// 它没有可用的 `/bangumi/{animeId}`（实测 404）。
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

  /// danmu_api 的分集带原始页面 URL；部分源（如 renren）给的是复合 ID，不是 URL。
  final String url;

  /// 来源标签（如 `renren`），用于非 URL 源的 segmentcomment。
  final String provider;

  const DanmakuEpisodeRef({
    required this.episodeId,
    required this.episodeTitle,
    this.url = '',
    this.provider = '',
  });
}

class DanmakuCandidate {
  final int episodeId;
  final String animeTitle;
  final String episodeTitle;
  final double shift;
  final String url;
  final String provider;

  const DanmakuCandidate({
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    this.shift = 0,
    this.url = '',
    this.provider = '',
  });
}

class DanmakuMatch {
  final int episodeId;
  final String animeTitle;
  final String episodeTitle;
  final double shift;
  final String source;
  final String url;
  final String provider;

  const DanmakuMatch({
    required this.episodeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.shift,
    required this.source,
    this.url = '',
    this.provider = '',
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

  /// danmu_api `/match` 使用的文件名：剧集 `标题 S01E02`，电影直接用片名。
  String get matchFileName {
    final title = searchTitle;
    if (title.isEmpty || isMovie) return title;
    final seasonText = (season ?? 1).toString().padLeft(2, '0');
    final episodeText = episodeNumber.toString().padLeft(2, '0');
    return '$title S${seasonText}E$episodeText';
  }

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
