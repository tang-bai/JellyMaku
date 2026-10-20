import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/danmaku/danmaku_api_client.dart';

void main() {
  test('talks to a danmu_api server without legacy credentials', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <HttpRequest>[];
    final bodies = <String>[];
    server.listen((request) async {
      requests.add(request);
      bodies.add(await utf8.decoder.bind(request).join());
      request.response.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');

      switch (request.uri.path) {
        case '/api/v2/search/episodes':
          request.response.write(jsonEncode({
            'animes': [
              {
                'animeId': 4780191,
                'animeTitle': '孤独摇滚！',
                'typeDescription': '日番',
                'episodes': [
                  {
                    'episodeId': 10004,
                    'episodeTitle': '第1话',
                    'url': 'https://www.bilibili.com/bangumi/play/ep693247',
                  },
                ],
              },
            ],
          }));
        case '/api/v2/match':
          request.response.write(jsonEncode({
            'isMatched': true,
            'matches': [
              {
                'episodeId': 10004,
                'animeTitle': '孤独摇滚！',
                'episodeTitle': '第1话',
                'url': 'https://www.bilibili.com/bangumi/play/ep693247',
              },
            ],
          }));
        case '/api/v2/comment':
          request.response.write(jsonEncode({
            'count': 1,
            'comments': [
              {'cid': 1, 'p': '1.0,1,16777215,[bilibili1]', 'm': '你好'},
            ],
          }));
        default:
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'errorMessage': 'not found'}));
      }
      await request.response.close();
    });

    final client = DanmakuApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}/',
    );

    try {
      final animes = await client.searchAnime('孤独摇滚');
      expect(animes.single.episodes.single.episodeTitle, '第1话');

      final matches = await client.matchFile('孤独摇滚！ S01E01');
      expect(matches.single.episodeId, 10004);

      final comments = await client.getComments(
        url: 'https://www.bilibili.com/bangumi/play/ep693247',
      );
      expect(comments.single.m, '你好');

      expect(requests.first.uri.path, '/api/v2/search/episodes');
      expect(requests[1].method, 'POST');
      expect(
        jsonDecode(bodies[1])['fileName'],
        '孤独摇滚！ S01E01',
      );
      expect(requests.last.uri.path, '/api/v2/comment');
      expect(requests.last.uri.queryParameters['format'], 'json');
      for (final request in requests) {
        expect(request.headers.value('x-appid'), isNull);
        expect(request.headers.value('authorization'), isNull);
      }
    } finally {
      client.dispose();
      await server.close(force: true);
    }
  });
}
