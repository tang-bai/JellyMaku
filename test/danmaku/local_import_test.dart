import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/danmaku/danmaku_models.dart';
import 'package:fladder/danmaku/local_import.dart';

void main() {
  group('parseLocalDanmakuFile XML', () {
    test('parses Bilibili XML modes, colors, entities and dedupes', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<i>
  <d p="1.5,1,25,16777215,0,0,user1">Hello &amp; world</d>
  <d p="2.0,5,25,16711680,0,0,user2">Top &#39;quote&#39;</d>
  <d p="3.0,4,25,255,0,0,user3">Bottom</d>
  <d p="3.0,4,25,255,0,0,user3">Bottom</d>
</i>
''';
      final comments = parseLocalDanmakuFile(xml, fileName: 'ep1.xml');

      expect(comments.length, 3);
      expect(comments.first.time, 1.5);
      expect(comments.first.mode, DanmakuMode.scroll);
      expect(comments.first.color, 0xFFFFFF);
      expect(comments.first.text, 'Hello & world');
      expect(comments.first.source, DanmakuSource.local);
      expect(comments[1].mode, DanmakuMode.top);
      expect(comments[1].text, "Top 'quote'");
      expect(comments[2].mode, DanmakuMode.bottom);
      expect(comments[2].color, 255);
    });

    test('rejects XML without danmaku nodes', () {
      expect(
        () => parseLocalDanmakuFile('<i><d>no attributes</d></i>'),
        throwsA(isA<LocalDanmakuFormatException>()),
      );
    });
  });

  group('parseLocalDanmakuFile JSON', () {
    test('parses danmu_api comments array', () {
      const json = '''
{
  "comments": [
    {"cid": 1, "p": "1.0,1,16777215,user1", "m": "hello"},
    {"cid": 2, "p": "2.0,5,16711680,user2", "m": "top"}
  ]
}
''';
      final comments = parseLocalDanmakuFile(json);
      expect(comments.length, 2);
      expect(comments.first.text, 'hello');
      expect(comments.last.mode, DanmakuMode.top);
      expect(comments.last.source, DanmakuSource.local);
    });

    test('accepts bare arrays and cached danmakus wrappers', () {
      final bare = parseLocalDanmakuFile(
        '[{"p":"1.0,1,255,u","m":"bare"}]',
      );
      expect(bare.single.text, 'bare');

      final wrapped = parseLocalDanmakuFile(
        '{"danDanBangumiID":1,"danmakus":[{"p":"2.0,4,255,u","m":"wrapped"}]}',
      );
      expect(wrapped.single.mode, DanmakuMode.bottom);
    });

    test('rejects broken JSON and empty results', () {
      expect(
        () => parseLocalDanmakuFile('{oops'),
        throwsA(isA<LocalDanmakuFormatException>()),
      );
      expect(
        () => parseLocalDanmakuFile('{"comments":[]}'),
        throwsA(isA<LocalDanmakuFormatException>()),
      );
      expect(
        () => parseLocalDanmakuFile('   '),
        throwsA(isA<LocalDanmakuFormatException>()),
      );
    });
  });
}
