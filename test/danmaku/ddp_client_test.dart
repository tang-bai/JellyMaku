import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/danmaku/ddp_client.dart';

void main() {
  test('DdpClient signs requests and parses search/comments', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <HttpRequest>[];
    server.listen((request) async {
      requests.add(request);
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path.endsWith('/search/episodes')) {
        request.response.write(jsonEncode({
          'animes': [
            {
              'animeTitle': 'Test Anime',
              'episodes': [
                {'episodeId': 42, 'episodeTitle': 'Episode 1', 'shift': 1.5},
              ],
            },
          ],
        }));
      } else if (request.uri.path.contains('/comment/')) {
        request.response.write(jsonEncode({
          'comments': [
            {'cid': 1, 'p': '1.0,1,16777215,user', 'm': 'hello'},
          ],
        }));
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    final client = DdpClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      appId: 'app123',
      appSecret: 'secret456',
    );

    try {
      final candidates = await client.searchEpisodes('Test Anime', 1);
      expect(candidates.single.episodeId, 42);
      expect(candidates.single.episodeTitle, 'Episode 1');
      expect(candidates.single.shift, 1.5);

      final searchRequest = requests.first;
      expect(searchRequest.headers.value('x-appid'), 'app123');
      final timestamp = int.parse(searchRequest.headers.value('x-timestamp')!);
      expect(
        searchRequest.headers.value('x-signature'),
        DdpClient.signature(
          appId: 'app123',
          appSecret: 'secret456',
          timestamp: timestamp,
          path: '/api/v2/search/episodes',
        ),
      );

      final comments = await client.getComments(42);
      expect(comments.single.cid, 1);
      expect(comments.single.m, 'hello');
    } finally {
      client.dispose();
      await server.close(force: true);
    }
  });
}
