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

  final chosen = candidates.first;
  return DanmakuMatch(
    episodeId: chosen.episodeId,
    animeTitle: chosen.animeTitle,
    episodeTitle: chosen.episodeTitle,
    shift: chosen.shift,
    source: 'search',
  );
}
