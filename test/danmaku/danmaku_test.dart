import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/danmaku/comment_parser.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

void main() {
  group('DdpClient signature', () {
    test('matches the documented SHA-256/base64 construction', () {
      final signature = DdpClient.signature(
        appId: 'app123',
        appSecret: 'secret456',
        timestamp: 1700000000,
        path: '/api/v2/search/episodes',
      );
      expect(signature, 'qy2NQAEb3Y9zTgUGrjlFTdip3BZ8wRI1p2fHYG7oJTo=');
    });
  });

  group('parseDanmakuComments', () {
    test('maps modes, applies offset, hides disabled modes and blocks words',
        () {
      final comments = parseDanmakuComments(
        const [
          DdpComment(cid: 1, p: '1.0,1,16777215,user1', m: 'Hello'),
          DdpComment(cid: 2, p: '2.0,5,16711680,user2', m: 'Top'),
          DdpComment(cid: 3, p: '3.0,4,255,user3', m: 'Bottom'),
          DdpComment(cid: 4, p: '4.0,1,0,user4', m: 'spoiler here'),
          DdpComment(cid: 5, p: '5.0,1,0,user1', m: 'Hello'),
        ],
        const DanmakuSettingsModel(
          offsetSeconds: 1,
          showTop: false,
          blockWords: ['spoiler'],
        ),
      );

      expect(comments.length, 3);
      expect(comments.first.time, 2.0);
      expect(comments.first.text, 'Hello');
      expect(comments[1].mode, DanmakuMode.bottom);
      expect(comments[1].color, 255);
      expect(comments.last.time, 6.0);
    });

    test('deduplicates same user, time and text', () {
      final comments = parseDanmakuComments(
        const [
          DdpComment(cid: 1, p: '1.0,1,16777215,user1', m: 'same'),
          DdpComment(cid: 2, p: '1.0,1,16777215,user1', m: 'same'),
        ],
        const DanmakuSettingsModel(),
      );
      expect(comments.length, 1);
    });
  });

  group('DanmakuSettingsModel', () {
    test('does not serialize the AppSecret', () {
      const settings = DanmakuSettingsModel(appId: 'id', appSecret: 'secret');
      final json = settings.toJson();
      expect(json.containsKey('appSecret'), isFalse);
      final restored = DanmakuSettingsModel.fromJson(json, appSecret: 'secret');
      expect(restored.appId, 'id');
      expect(restored.appSecret, 'secret');
    });
  });
}
