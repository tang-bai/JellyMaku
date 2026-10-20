import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fladder/danmaku/cache.dart';
import 'package:fladder/danmaku/comment_parser.dart';
import 'package:fladder/danmaku/danmaku_api_client.dart';
import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/matcher.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

http.Response _json(Object body, [int status = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

DanmakuApiClient _client(MockClient mock) {
  return DanmakuApiClient(baseUrl: 'https://danmu.example', httpClient: mock);
}

const _media = DanmakuMediaInfo(
  itemId: 'item1',
  name: '第1话',
  seriesName: '孤独摇滚！',
  episode: 1,
  season: 1,
);

void main() {
  group('DanmakuApiClient', () {
    test('posts match fileName without legacy auth headers', () async {
      late http.Request captured;
      final client = _client(MockClient((request) async {
        captured = request;
        return _json({
          'errorCode': 0,
          'success': true,
          'isMatched': true,
          'matches': [
            {
              'episodeId': 10004,
              'animeId': 1,
              'animeTitle': '孤独摇滚！',
              'episodeTitle': '第1话',
              'shift': 1.5,
              'url': 'https://www.bilibili.com/bangumi/play/ep693247',
            },
          ],
        });
      }));

      final matches = await client.matchFile('孤独摇滚！ S01E01');

      expect(matches.single.episodeId, 10004);
      expect(matches.single.episodeTitle, '第1话');
      expect(matches.single.shift, 1.5);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v2/match');
      expect(jsonDecode(captured.body)['fileName'], '孤独摇滚！ S01E01');
      expect(captured.headers.containsKey('Authorization'), isFalse);
      client.dispose();
    });

    test('returns empty when match says isMatched=false', () async {
      final client = _client(MockClient((request) async {
        return _json({'errorCode': 0, 'success': true, 'isMatched': false});
      }));

      expect(await client.matchFile('不存在'), isEmpty);
      client.dispose();
    });

    test('searches episodes with anime/episode query', () async {
      late http.Request captured;
      final client = _client(MockClient((request) async {
        captured = request;
        return _json({
          'errorCode': 0,
          'success': true,
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
                {'episodeId': 0, 'episodeTitle': 'invalid'},
              ],
            },
          ],
        });
      }));

      final candidates = await client.searchEpisodes('孤独摇滚！', 1);

      expect(candidates.single.episodeId, 10004);
      expect(captured.url.path, '/api/v2/search/episodes');
      expect(captured.url.queryParameters['anime'], '孤独摇滚！');
      expect(captured.url.queryParameters['episode'], '1');
      expect(captured.url.queryParameters.containsKey('v2'), isFalse);
      client.dispose();
    });

    test('searchAnime keeps embedded episodes and type', () async {
      final client = _client(MockClient((request) async {
        return _json({
          'animes': [
            {
              'animeId': 1,
              'animeTitle': 'A',
              'typeDescription': 'TV',
              'episodes': [
                {
                  'episodeId': 2,
                  'episodeTitle': 'E1',
                  'url': 'https://example.com/ep1',
                },
              ],
            },
          ],
        });
      }));

      final animes = await client.searchAnime('A');

      expect(animes.single.animeId, 1);
      expect(animes.single.typeDescription, 'TV');
      expect(animes.single.episodes.single.url, 'https://example.com/ep1');
      client.dispose();
    });

    test('gets comments by url with format=json and decodes UTF-8', () async {
      late http.Request captured;
      final client = _client(MockClient((request) async {
        captured = request;
        return _json({
          'errorCode': 0,
          'success': true,
          'count': 1,
          'comments': [
            {'cid': 1, 'p': '1.0,1,16777215,[bilibili1]', 'm': '你好'},
          ],
        });
      }));

      final comments = await client.getComments(
        url: 'https://www.bilibili.com/bangumi/play/ep1?season_id=1',
      );

      expect(comments.single.m, '你好');
      expect(comments.single.p, '1.0,1,16777215,[bilibili1]');
      expect(captured.url.path, '/api/v2/comment');
      expect(captured.url.queryParameters['format'], 'json');
      expect(
        captured.url.queryParameters['url'],
        'https://www.bilibili.com/bangumi/play/ep1?season_id=1',
      );
      client.dispose();
    });

    test('normalizes protocol-relative and bare urls', () async {
      final urls = <String>[];
      final client = _client(MockClient((request) async {
        urls.add(request.url.queryParameters['url'] ?? '');
        return _json({'comments': []});
      }));

      await client.getComments(url: '//example.com/ep1');
      await client.getComments(url: 'example.com/ep1');

      expect(urls, ['https://example.com/ep1', 'https://example.com/ep1']);
      client.dispose();
    });

    test('falls back to the id route when url is rejected', () async {
      final paths = <String>[];
      final client = _client(MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/v2/comment') {
          return _json({
            'errorCode': 400,
            'errorMessage': 'Invalid url format, must start with http or https',
            'comments': [],
          }, 400);
        }
        return _json({
          'comments': [
            {'cid': 1, 'p': '1.0,1,16777215,[bilibili1]', 'm': 'fallback'},
          ],
        });
      }));

      final comments = await client.getComments(
        url: 'https://example.com/ep1',
        episodeId: 2,
      );

      expect(paths, ['/api/v2/comment', '/api/v2/comment/2']);
      expect(comments.single.m, 'fallback');
      client.dispose();
    });

    test('treats 404 on both routes as an empty result', () async {
      final client = _client(MockClient((request) async {
        return _json({'count': 0, 'comments': []}, 404);
      }));

      expect(
        await client.getComments(url: 'https://example.com/ep1', episodeId: 2),
        isEmpty,
      );
      client.dispose();
    });

    test('uses segmentcomment for opaque source ids with provider', () async {
      late http.Request captured;
      final client = _client(MockClient((request) async {
        captured = request;
        return _json({
          'count': 1,
          'comments': [
            {'cid': 1, 'p': '17.0,1,16777215,[renren]', 'm': 'renren comment'},
          ],
        });
      }));

      final comments = await client.getComments(
        url: '59377-431223',
        provider: 'renren',
      );

      expect(comments.single.m, 'renren comment');
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v2/segmentcomment');
      expect(captured.url.queryParameters['format'], 'json');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['type'], 'renren');
      expect(body['url'], '59377-431223');
      expect(body['segment_end'], 86400000);
      client.dispose();
    });

    test('reports 401 with a self-hosted TOKEN hint', () async {
      final client = _client(MockClient((request) async {
        return _json({
          'errorCode': 401,
          'success': false,
          'errorMessage': 'Unauthorized',
        }, 401);
      }));

      await expectLater(
        client.testConnection(),
        throwsA(
          isA<DanmakuException>().having(
            (error) => error.message,
            'message',
            contains('TOKEN'),
          ),
        ),
      );
      client.dispose();
    });
  });

  group('parseDanmakuComments', () {
    test('extracts the provider from episode titles', () {
      expect(danmakuProviderFromTitle('【renren】 第01集'), 'renren');
      expect(danmakuProviderFromTitle('[bilibili1] 第1话'), 'bilibili1');
      expect(danmakuProviderFromTitle('第1话'), '');
    });

    test('treats bracketed p[3] as a provider tag, not a uid', () {
      // blockUsers 里放来源名；如果误当 uid，就会把整站弹幕屏蔽掉。
      final comments = parseDanmakuComments(
        const [
          DanmakuApiComment(
            cid: 1,
            p: '1.0,1,16777215,[bilibili1]',
            m: 'hello',
          ),
        ],
        const DanmakuSettingsModel(blockUsers: ['bilibili1']),
      );

      expect(comments.single.provider, 'bilibili1');
      expect(comments.single.uid, '');
      expect(comments.single.source, DanmakuSource.online);
    });

    test('still blocks legacy uid-style p[3]', () {
      final comments = parseDanmakuComments(
        const [
          DanmakuApiComment(cid: 1, p: '1.0,1,16777215,user1', m: 'blocked'),
          DanmakuApiComment(cid: 2, p: '2.0,1,16777215,user2', m: 'kept'),
        ],
        const DanmakuSettingsModel(blockUsers: ['user1']),
      );

      expect(comments.single.text, 'kept');
      expect(comments.single.uid, 'user2');
    });

    test('maps modes, applies offset and blocks words', () {
      final settings = const DanmakuSettingsModel(
        offsetSeconds: 1,
        showTop: false,
        blockWords: ['spoiler'],
      );
      final comments = parseDanmakuComments(
        const [
          DanmakuApiComment(
              cid: 1, p: '1.0,1,16777215,[bilibili1]', m: 'Hello'),
          DanmakuApiComment(cid: 2, p: '2.0,5,16711680,[bilibili1]', m: 'Top'),
          DanmakuApiComment(cid: 3, p: '3.0,4,255,[bilibili1]', m: 'Bottom'),
          DanmakuApiComment(
            cid: 4,
            p: '4.0,1,0,[bilibili1]',
            m: 'spoiler here',
          ),
        ],
        settings,
      );

      expect(comments.length, 3);
      expect(comments.first.time, 2.0);
      expect(comments[1].mode, DanmakuMode.top);
      expect(comments[1].color, 16711680);
      expect(comments[2].mode, DanmakuMode.bottom);
      expect(comments[2].color, 255);
      expect(isDanmakuVisible(comments[1], settings), isFalse);
    });

    test('deduplicates same tag, time and text', () {
      final comments = parseDanmakuComments(
        const [
          DanmakuApiComment(
            cid: 1,
            p: '1.0,1,16777215,[bilibili1]',
            m: 'same',
          ),
          DanmakuApiComment(
            cid: 2,
            p: '1.0,1,16777215,[bilibili1]',
            m: 'same',
          ),
        ],
        const DanmakuSettingsModel(),
      );

      expect(comments.length, 1);
    });

    test('local import visibility follows showLocalSource', () {
      const local = DanmakuComment(
        time: 1,
        mode: DanmakuMode.scroll,
        color: 0xFFFFFF,
        uid: 'local',
        text: 'echo',
        source: DanmakuSource.local,
      );
      const online = DanmakuComment(
        time: 1,
        mode: DanmakuMode.scroll,
        color: 0xFFFFFF,
        uid: '',
        text: 'online',
        provider: 'bilibili1',
      );

      expect(isDanmakuVisible(local, const DanmakuSettingsModel()), isTrue);
      expect(
        isDanmakuVisible(
          local,
          const DanmakuSettingsModel(showLocalSource: false),
        ),
        isFalse,
      );
      expect(
        isDanmakuVisible(
          online,
          const DanmakuSettingsModel(showLocalSource: false),
        ),
        isTrue,
      );
    });

    test('merges duplicated text within the five second window', () {
      final comments = parseDanmakuComments(
        const [
          DanmakuApiComment(
            cid: 1,
            p: '1.0,1,16777215,[bilibili1]',
            m: 'ＡＢＣ',
          ),
          DanmakuApiComment(cid: 2, p: '3.0,1,255,[bilibili1]', m: 'ABC'),
          DanmakuApiComment(cid: 3, p: '10.0,1,255,[bilibili1]', m: 'ABC'),
        ],
        const DanmakuSettingsModel(mergeDuplicates: true),
      );

      expect(comments.length, 2);
      expect(comments.first.text, 'ＡＢＣ x2');
      expect(comments.first.mode, DanmakuMode.top);
      expect(comments.first.color, 0xFFFFFF);
      expect(comments.last.time, 10.0);
    });
  });

  group('matchDanmaku', () {
    test('uses a stored mapping and preserves its source', () async {
      final client = _client(MockClient((request) async {
        fail('mapping should short-circuit network requests');
      }));

      final match = await matchDanmaku(
        client,
        _media,
        mapping: {
          'episodeId': 42,
          'animeTitle': 'X',
          'episodeTitle': 'E1',
          'shift': 2.0,
          'source': 'search',
          'url': 'https://example.com/ep1',
        },
      );

      expect(match.episodeId, 42);
      expect(match.source, 'search');
      expect(match.url, 'https://example.com/ep1');
      expect(match.shift, 2.0);
      client.dispose();
    });

    test('uses matchFile first with SxxExx fileName', () async {
      late http.Request captured;
      final client = _client(MockClient((request) async {
        captured = request;
        return _json({
          'isMatched': true,
          'matches': [
            {
              'episodeId': 10004,
              'animeTitle': '孤独摇滚！',
              'episodeTitle': '第1话',
              'url': 'https://www.bilibili.com/bangumi/play/ep1',
            },
          ],
        });
      }));

      final match = await matchDanmaku(client, _media);

      expect(match.source, 'match');
      expect(match.episodeId, 10004);
      expect(jsonDecode(captured.body)['fileName'], '孤独摇滚！ S01E01');
      client.dispose();
    });

    test('falls back to search/episodes when match returns empty', () async {
      final paths = <String>[];
      final client = _client(MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/v2/match') {
          return _json({'isMatched': false, 'matches': []});
        }
        return _json({
          'animes': [
            {
              'animeTitle': '孤独摇滚！',
              'episodes': [
                {
                  'episodeId': 1,
                  'episodeTitle': '第1话',
                  'url': 'http://v.youku.com/v_show/id_1.html',
                },
                {
                  'episodeId': 2,
                  'episodeTitle': '第1话',
                  'url': 'https://www.bilibili.com/bangumi/play/ep1',
                },
              ],
            },
          ],
        });
      }));

      final match = await matchDanmaku(client, _media);

      expect(paths, ['/api/v2/match', '/api/v2/search/episodes']);
      expect(match.source, 'search');
      expect(match.url, 'https://www.bilibili.com/bangumi/play/ep1');
      client.dispose();
    });

    test('falls back to search when match fails', () async {
      final client = _client(MockClient((request) async {
        if (request.url.path == '/api/v2/match') {
          return _json({'errorMessage': 'not found'}, 404);
        }
        return _json({
          'animes': [
            {
              'animeTitle': '孤独摇滚！',
              'episodes': [
                {
                  'episodeId': 2,
                  'episodeTitle': '第1话',
                  'url': 'https://www.bilibili.com/bangumi/play/ep1',
                },
              ],
            },
          ],
        });
      }));

      final match = await matchDanmaku(client, _media);

      expect(match.source, 'search');
      expect(match.episodeId, 2);
      client.dispose();
    });

    test('surfaces the match error when search also returns nothing', () async {
      final client = _client(MockClient((request) async {
        if (request.url.path == '/api/v2/match') {
          return _json({'errorMessage': 'offline'}, 500);
        }
        return _json({'animes': []});
      }));

      await expectLater(
        matchDanmaku(client, _media),
        throwsA(isA<DanmakuException>()),
      );
      client.dispose();
    });

    test('respects autoMatch=false without a mapping', () async {
      final client = _client(MockClient((request) async {
        fail('autoMatch=false should not request');
      }));

      await expectLater(
        matchDanmaku(
          client,
          _media,
          settings: const DanmakuSettingsModel(autoMatch: false),
        ),
        throwsA(isA<DanmakuNoMatch>()),
      );
      client.dispose();
    });

    test('uses the plain title for movies', () {
      const movie = DanmakuMediaInfo(
        itemId: 'm1',
        name: '孤独摇滚（上）',
        isMovie: true,
      );
      expect(movie.matchFileName, '孤独摇滚（上）');
    });

    test('retries search with a title variant when the year suffix fails',
        () async {
      final queries = <String>[];
      final client = _client(MockClient((request) async {
        if (request.url.path == '/api/v2/match') {
          return _json({'isMatched': false, 'matches': []});
        }
        final query = request.url.queryParameters['anime'] ?? '';
        queries.add(query);
        if (query == 'FX战士久留美') {
          return _json({
            'animes': [
              {
                'animeTitle': 'FX战士久留美',
                'episodes': [
                  {
                    'episodeId': 2,
                    'episodeTitle': '【renren】 第01集',
                    'url': '59377-431223',
                  },
                ],
              },
            ],
          });
        }
        return _json({'animes': []});
      }));

      final match = await matchDanmaku(
        client,
        const DanmakuMediaInfo(
          itemId: 'fx',
          name: 'FX战士久留美 (2026)',
          episode: 1,
          season: 1,
        ),
      );

      expect(match.source, 'search');
      expect(match.provider, 'renren');
      expect(queries, ['FX战士久留美 (2026)', 'FX战士久留美']);
      client.dispose();
    });

    test('movie search fallback omits the episode filter', () async {
      late http.Request captured;
      final client = _client(MockClient((request) async {
        if (request.url.path == '/api/v2/match') {
          return _json({'isMatched': false, 'matches': []});
        }
        captured = request;
        return _json({
          'animes': [
            {
              'animeTitle': '孤独摇滚（上）',
              'episodes': [
                {
                  'episodeId': 2,
                  'episodeTitle': '正片',
                  'url': 'https://www.bilibili.com/bangumi/play/ep1',
                },
              ],
            },
          ],
        });
      }));

      final match = await matchDanmaku(
        client,
        const DanmakuMediaInfo(
          itemId: 'm1',
          name: '孤独摇滚（上）',
          isMovie: true,
        ),
      );

      expect(match.source, 'search');
      expect(captured.url.queryParameters.containsKey('episode'), isFalse);
      client.dispose();
    });
  });

  group('search title variants', () {
    test('strips trailing year, season/episode and subtitle', () {
      expect(
        danmakuSearchQueries('FX战士久留美 (2026)'),
        contains('FX战士久留美'),
      );
      expect(
        danmakuSearchQueries('FX战士久留美 S01E01'),
        contains('FX战士久留美'),
      );
      expect(
        danmakuSearchQueries('FX战士久留美 (2026) S01E01'),
        contains('FX战士久留美'),
      );
      expect(
        danmakuSearchQueries('FX战士久留美 第1集'),
        contains('FX战士久留美'),
      );
      expect(
        danmakuSearchQueries('FX战士久留美：特别篇'),
        contains('FX战士久留美'),
      );
    });
  });

  group('settings migration', () {
    test('defaults to the public danmu_api instance', () {
      expect(DanmakuSettingsModel.defaults.apiBase, kDefaultDanmuApiBase);
      expect(
        const DanmakuSettingsModel(apiBase: '  ').effectiveApiBase,
        kDefaultDanmuApiBase,
      );
    });

    test('migrates the legacy API base and ignores removed keys', () {
      final restored = DanmakuSettingsModel.fromJson({
        'apiBase': 'http://danmu.api.tangbai.cc',
        'appId': 'old-id',
        'appSecret': 'old-secret',
        'chConvert': 2,
        'hashMatch': true,
        'enabled': false,
      });

      expect(restored.apiBase, kDefaultDanmuApiBase);
      expect(restored.enabled, isFalse);
      final json = restored.toJson();
      expect(json.containsKey('appId'), isFalse);
      expect(json.containsKey('appSecret'), isFalse);
      expect(json.containsKey('chConvert'), isFalse);
      expect(json.containsKey('hashMatch'), isFalse);
    });

    test('keeps a custom self-hosted token path', () {
      final restored = DanmakuSettingsModel.fromJson({
        'apiBase': 'http://192.168.1.10:9321/87654321/',
      });

      expect(restored.apiBase, 'http://192.168.1.10:9321/87654321/');
      expect(
        restored.effectiveApiBase,
        'http://192.168.1.10:9321/87654321/',
      );
    });
  });

  group('comment cache key', () {
    test('is stable for the same server and source url', () {
      final a = danmakuCommentCacheKey(
        baseUrl: 'https://danmu.example',
        url: 'https://www.bilibili.com/bangumi/play/ep1',
      );
      final b = danmakuCommentCacheKey(
        baseUrl: 'https://danmu.example',
        url: 'https://www.bilibili.com/bangumi/play/ep1',
      );

      expect(a, b);
      expect(a.length, 40);
    });

    test('separates different servers, urls and ids', () {
      final base = danmakuCommentCacheKey(
        baseUrl: 'https://danmu.example',
        url: 'https://example.com/ep1',
      );

      expect(
        base,
        isNot(danmakuCommentCacheKey(
          baseUrl: 'https://other.example',
          url: 'https://example.com/ep1',
        )),
      );
      expect(
        base,
        isNot(danmakuCommentCacheKey(
          baseUrl: 'https://danmu.example',
          url: 'https://example.com/ep2',
        )),
      );
      expect(
        danmakuCommentCacheKey(baseUrl: 'https://danmu.example', episodeId: 1),
        isNot(danmakuCommentCacheKey(
          baseUrl: 'https://danmu.example',
          episodeId: 2,
        )),
      );
    });
  });
}
