import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fladder/danmaku/comment_parser.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/ddp_client.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

DdpClient _mockClient(MockClient mock, {String appId = 'app123'}) {
  return DdpClient(
    baseUrl: 'https://api.dandanplay.net',
    appId: appId,
    appSecret: 'secret456',
    httpClient: mock,
  );
}

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

  group('DdpClient manual matching', () {
    test('searchAnime parses animeId/title/type and signs the request', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'animes': [
              {
                'animeId': 12345,
                'animeTitle': '孤独摇滚！',
                'typeDescription': 'TV',
              },
              {'animeId': 0, 'animeTitle': 'invalid'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final client = _mockClient(mock);

      final animes = await client.searchAnime('孤独摇滚');

      expect(animes.length, 1);
      expect(animes.single.animeId, 12345);
      expect(animes.single.animeTitle, '孤独摇滚！');
      expect(animes.single.typeDescription, 'TV');
      expect(captured.url.path, '/api/v2/search/episodes');
      expect(captured.url.queryParameters['anime'], '孤独摇滚');
      expect(captured.url.queryParameters['v2'], 'true');
      expect(captured.headers.containsKey('X-Signature'), isTrue);
      expect(captured.headers['X-AppId'], 'app123');
      client.dispose();
    });

    test('searchAnime keeps episodes/url and omits auth without credentials',
        () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'animes': [
              {
                'animeId': 1,
                'animeTitle': 'A',
                'episodes': [
                  {
                    'episodeId': 2,
                    'episodeTitle': 'E1',
                    'url': 'https://example.com/ep1',
                  },
                ],
              },
            ],
          }),
          200,
        );
      });
      final client = DdpClient(
        baseUrl: 'http://danmu.example',
        appId: '',
        appSecret: '',
        httpClient: mock,
      );

      final animes = await client.searchAnime('A');

      expect(animes.single.episodes.single.episodeId, 2);
      expect(animes.single.episodes.single.url, 'https://example.com/ep1');
      expect(captured.headers.containsKey('X-Signature'), isFalse);
      expect(captured.headers.containsKey('X-AppId'), isFalse);
      client.dispose();
    });

    test('getComments uses the url query for custom servers', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'comments': [
              {'cid': 1, 'p': '1.0,1,16777215,[bilibili1]', 'm': 'hi'},
            ],
          }),
          200,
        );
      });
      final client = DdpClient(
        baseUrl: 'http://danmu.example',
        appId: '',
        appSecret: '',
        httpClient: mock,
      );

      final comments = await client.getComments(
        2,
        url: 'https://example.com/ep1',
      );

      expect(comments.single.m, 'hi');
      expect(captured.url.path, '/api/v2/comment');
      expect(captured.url.queryParameters['url'], 'https://example.com/ep1');
      client.dispose();
    });

    test('getEpisodes reads bangumi.episodes', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/v2/bangumi/12345');
        return http.Response(
          jsonEncode({
            'bangumi': {
              'animeId': 12345,
              'episodes': [
                {'episodeId': 123450001, 'episodeTitle': '第1话'},
                {'episodeId': 123450002, 'episodeTitle': '第2话'},
                {'episodeId': 0, 'episodeTitle': 'invalid'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final client = _mockClient(mock);

      final episodes = await client.getEpisodes(12345);

      expect(episodes.length, 2);
      expect(episodes.first.episodeId, 123450001);
      expect(episodes.last.episodeTitle, '第2话');
      client.dispose();
    });
  });

  group('parseDanmakuComments', () {
    test('maps modes, applies offset, blocks words and keeps hidden types',
        () {
      final settings = const DanmakuSettingsModel(
        offsetSeconds: 1,
        showTop: false,
        blockWords: ['spoiler'],
      );
      final comments = parseDanmakuComments(
        const [
          DdpComment(cid: 1, p: '1.0,1,16777215,user1', m: 'Hello'),
          DdpComment(cid: 2, p: '2.0,5,16711680,user2', m: 'Top'),
          DdpComment(cid: 3, p: '3.0,4,255,user3', m: 'Bottom'),
          DdpComment(cid: 4, p: '4.0,1,0,user4', m: 'spoiler here'),
          DdpComment(cid: 5, p: '5.0,1,0,user1', m: 'Hello'),
        ],
        settings,
      );

      expect(comments.length, 4);
      expect(comments.first.time, 2.0);
      expect(comments.first.text, 'Hello');
      expect(comments[1].mode, DanmakuMode.top);
      expect(comments[2].mode, DanmakuMode.bottom);
      expect(comments[2].color, 255);
      expect(comments.last.time, 6.0);

      // 顶部弹幕仍保留在列表里，由绘制层实时过滤，切换开关无需重载。
      expect(isDanmakuVisible(comments[1], settings), isFalse);
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

    test('treats DDP comments as one aggregated source', () {
      // 实测 DDP 的 p[3] 是十六进制用户 id，不是 BiliBili/Gamer 标签；
      // 因此不能在客户端按站过滤，只保留 uid 给屏蔽使用。
      final comments = parseDanmakuComments(
        const [
          DdpComment(cid: 1, p: '1.0,1,16777215,8c93d287', m: 'a'),
          DdpComment(cid: 2, p: '2.0,1,16777215,7eb092f1', m: 'b'),
          DdpComment(cid: 3, p: '3.0,1,16777215,3bfc25ea', m: 'c'),
        ],
        const DanmakuSettingsModel(),
      );

      expect(comments.map((c) => c.source).toSet(), {DanmakuSource.danDanPlay});
      expect(comments.first.uid, '8c93d287');

      // 关掉本地导入不会影响在线聚合弹幕。
      const localHidden = DanmakuSettingsModel(showLocalSource: false);
      expect(isDanmakuVisible(comments.first, localHidden), isTrue);
    });

    test('local import comments follow showLocalSource', () {
      const local = DanmakuComment(
        time: 1,
        mode: DanmakuMode.scroll,
        color: 0xFFFFFF,
        uid: 'local',
        text: 'echo',
        source: DanmakuSource.local,
      );
      expect(isDanmakuVisible(local, const DanmakuSettingsModel()), isTrue);
      expect(
        isDanmakuVisible(
          local,
          const DanmakuSettingsModel(showLocalSource: false),
        ),
        isFalse,
      );
    });

    test('merges duplicated text within the five second window', () {
      final comments = parseDanmakuComments(
        const [
          DdpComment(cid: 1, p: '1.0,1,16777215,u1', m: 'ＡＢＣ'),
          DdpComment(cid: 2, p: '3.0,1,255,u2', m: 'ABC'),
          DdpComment(cid: 3, p: '10.0,1,255,u3', m: 'ABC'),
        ],
        const DanmakuSettingsModel(mergeDuplicates: true),
      );

      expect(comments.length, 2);
      final first = comments.first;
      expect(first.text, 'ＡＢＣ x2');
      expect(first.mode, DanmakuMode.top);
      expect(first.color, 0xFFFFFF);
      expect(comments.last.text, 'ABC');
      expect(comments.last.time, 10.0);

      final repeat = parseDanmakuComments(
        const [
          DdpComment(cid: 1, p: '1.0,1,255,u1', m: '啊啊啊啊'),
          DdpComment(cid: 2, p: '2.0,1,255,u2', m: '啊啊啊'),
        ],
        const DanmakuSettingsModel(mergeDuplicates: true),
      );
      expect(repeat.single.text, '啊啊啊啊 x2');
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

    test('round-trips source/style options', () {
      const settings = DanmakuSettingsModel(
        showLocalSource: false,
        mergeDuplicates: true,
        showColor: false,
        strokeWidth: 3.5,
        localFile: r'C:\danmaku\ep1.xml',
      );
      final restored = DanmakuSettingsModel.fromJson(settings.toJson());

      expect(restored.mergeDuplicates, isTrue);
      expect(restored.showColor, isFalse);
      expect(restored.showLocalSource, isFalse);
      expect(restored.strokeWidth, 3.5);
      expect(restored.localFile, r'C:\danmaku\ep1.xml');
    });

    test('clearLocalFile removes the selected file', () {
      const settings = DanmakuSettingsModel(localFile: 'ep1.xml');
      expect(settings.copyWith(clearLocalFile: true).localFile, isNull);
      expect(settings.copyWith(localFile: 'ep2.xml').localFile, 'ep2.xml');
    });
  });
}
