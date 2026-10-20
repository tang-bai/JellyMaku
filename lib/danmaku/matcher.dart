import 'package:fladder/danmaku/danmaku_api_client.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

class DanmakuNoMatch implements Exception {
  final List<DanmakuCandidate> candidates;

  const DanmakuNoMatch([this.candidates = const []]);

  @override
  String toString() => '未匹配到弹幕（可尝试手动匹配）';
}

/// 匹配优先级：手动/缓存的 mapping → danmu_api 的 /match → search/episodes 打分。
///
/// /match 由服务端做标题、季集和平台优选，通常比客户端打分更准；只有它不可用
/// （旧自建版本 404、网络错误）或返回空时才退到搜索。
Future<DanmakuMatch> matchDanmaku(
  DanmakuApiClient client,
  DanmakuMediaInfo media, {
  Map<String, dynamic>? mapping,
  DanmakuSettingsModel? settings,
}) async {
  if (mapping != null) {
    final episodeId = (mapping['episodeId'] as num?)?.toInt();
    if (episodeId != null && episodeId > 0) {
      final episodeTitle = mapping['episodeTitle']?.toString() ?? '';
      return DanmakuMatch(
        episodeId: episodeId,
        animeTitle: mapping['animeTitle']?.toString() ?? media.searchTitle,
        episodeTitle: episodeTitle,
        shift: (mapping['shift'] as num?)?.toDouble() ?? 0,
        // 自动匹配写入的 mapping 也带自己的 source，UI 不应一律显示“手动”。
        source: mapping['source']?.toString() ?? 'manual',
        url: mapping['url']?.toString() ?? '',
        provider: mapping['provider']?.toString() ??
            danmakuProviderFromTitle(episodeTitle),
      );
    }
  }

  if (settings != null && !settings.autoMatch) {
    throw const DanmakuNoMatch();
  }

  final title = media.searchTitle;
  if (title.isEmpty) throw const DanmakuNoMatch();

  Object? matchError;
  try {
    final matches = await client.matchFile(media.matchFileName);
    if (matches.isNotEmpty) return _toMatch(matches.first, 'match');
  } catch (error) {
    matchError = error;
  }

  List<DanmakuCandidate> candidates = const [];
  try {
    for (final query in danmakuSearchQueries(title)) {
      candidates = await client.searchEpisodes(
        query,
        media.isMovie ? null : media.episodeNumber,
      );
      if (candidates.isNotEmpty) break;
    }
  } catch (error) {
    final failure = matchError;
    if (failure != null) throw failure;
    rethrow;
  }

  if (candidates.isEmpty) {
    final failure = matchError;
    if (failure != null) throw failure;
    throw const DanmakuNoMatch();
  }

  final chosen = candidates.reduce(
    (a, b) => _candidateScore(b, media) > _candidateScore(a, media) ? b : a,
  );
  return _toMatch(chosen, 'search');
}

DanmakuMatch _toMatch(DanmakuCandidate candidate, String source) {
  return DanmakuMatch(
    episodeId: candidate.episodeId,
    animeTitle: candidate.animeTitle,
    episodeTitle: candidate.episodeTitle,
    shift: candidate.shift,
    source: source,
    url: candidate.url,
    provider: candidate.provider.isEmpty
        ? danmakuProviderFromTitle(candidate.episodeTitle)
        : candidate.provider,
  );
}

/// 自动匹配的轻量打分：优先 B 站/巴哈，避开非目标来源。
int _candidateScore(DanmakuCandidate candidate, DanmakuMediaInfo media) {
  var score = 0;
  final url = candidate.url.toLowerCase();
  final title = candidate.animeTitle.toLowerCase();
  if (url.contains('bilibili.com')) score += 4;
  if (url.contains('gamer.com.tw') || url.contains('bahamut.com.tw')) {
    score += 4;
  }
  if (url.contains('youku.com') ||
      url.contains('iqiyi.com') ||
      url.contains('le.com') ||
      url.contains('mgtv.com')) {
    score -= 2;
  }
  // 只有剧集才应避开“电影/剧场版”；电影条目本身命中电影是正确结果。
  if (!media.isMovie && (title.contains('电影') || title.contains('剧场版'))) {
    score -= 3;
  }
  final wanted = media.searchTitle.toLowerCase();
  if (wanted.isNotEmpty && title.contains(wanted)) score += 2;
  if (!media.isMovie &&
      RegExp('第\\s*${media.episodeNumber}\\s*[话集]')
          .hasMatch(candidate.episodeTitle)) {
    score += 2;
  }
  if (url.startsWith('http')) score += 1;
  return score;
}
