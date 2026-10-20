import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

class DanmakuNoMatch implements Exception {
  final List<DanmakuCandidate> candidates;

  const DanmakuNoMatch([this.candidates = const []]);

  @override
  String toString() => 'No DanDanPlay episode matched';
}

Future<DanmakuMatch> matchDanmaku(
  DdpClient client,
  DanmakuMediaInfo media, {
  Map<String, dynamic>? manual,
  DanmakuSettingsModel? settings,
}) async {
  if (manual != null) {
    final episodeId = (manual['episodeId'] as num?)?.toInt();
    if (episodeId != null && episodeId > 0) {
      return DanmakuMatch(
        episodeId: episodeId,
        animeTitle: manual['animeTitle']?.toString() ?? media.searchTitle,
        episodeTitle: manual['episodeTitle']?.toString() ?? '',
        shift: (manual['shift'] as num?)?.toDouble() ?? 0,
        source: 'manual',
        url: manual['url']?.toString() ?? '',
      );
    }
  }

  if (settings != null && !settings.autoMatch) {
    throw const DanmakuNoMatch();
  }

  final candidates = await client.searchEpisodes(
    media.searchTitle,
    media.isMovie ? 1 : media.episodeNumber,
  );
  if (candidates.isEmpty) {
    throw const DanmakuNoMatch();
  }

  final chosen = candidates.reduce(
    (a, b) => _candidateScore(b, media) > _candidateScore(a, media) ? b : a,
  );
  return DanmakuMatch(
    episodeId: chosen.episodeId,
    animeTitle: chosen.animeTitle,
    episodeTitle: chosen.episodeTitle,
    shift: chosen.shift,
    source: 'search',
    url: chosen.url,
  );
}

/// 自动匹配的轻量打分：优先 B 站/巴哈，避开电影/剧场版和非目标来源。
int _candidateScore(DanmakuCandidate candidate, DanmakuMediaInfo media) {
  var score = 0;
  final url = candidate.url.toLowerCase();
  final title = candidate.animeTitle.toLowerCase();
  if (url.contains('bilibili.com')) score += 4;
  if (url.contains('gamer.com.tw')) score += 4;
  if (url.contains('youku.com') ||
      url.contains('iqiyi.com') ||
      url.contains('le.com') ||
      url.contains('mgtv.com')) {
    score -= 2;
  }
  if (title.contains('电影') || title.contains('剧场版')) score -= 3;
  final wanted = media.searchTitle.toLowerCase();
  if (wanted.isNotEmpty && title.contains(wanted)) score += 2;
  if (!media.isMovie &&
      RegExp('第\\s*${media.episodeNumber}\\s*[话集]')
          .hasMatch(candidate.episodeTitle)) {
    score += 2;
  }
  return score;
}
