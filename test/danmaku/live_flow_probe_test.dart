import 'package:flutter_test/flutter_test.dart';
import 'package:fladder/danmaku/danmaku_api_client.dart';
import 'package:fladder/danmaku/matcher.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

void main() {
  test('live ep1/ep2 full flow', () async {
    final client = DanmakuApiClient(baseUrl: 'https://danmu.api.tangbai.cc');
    try {
      for (final ep in [1, 2]) {
        final media = DanmakuMediaInfo(
          itemId: 'fx$ep',
          name: 'FX战士久留美 (2026)',
          episode: ep,
          season: 1,
        );
        final match = await matchDanmaku(client, media,
            settings: const DanmakuSettingsModel());
        final raw = await client.getComments(
            url: match.url,
            episodeId: match.episodeId,
            provider: match.provider);
        print('ep$ep match=${match.episodeTitle} url=${match.url} '
            'provider=${match.provider} comments=${raw.length}');
        if (raw.isNotEmpty) print('  first: ${raw.first.m}');
      }
    } finally {
      client.dispose();
    }
  },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: '手动联网探针；需要可用的 danmu_api 实例，不参与常规测试');
}
