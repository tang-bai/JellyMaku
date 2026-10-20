import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fladder/screens/video_player/components/danmaku_match_dialog.dart';
import 'package:fladder/screens/video_player/components/danmaku_send_dialog.dart';
import 'package:fladder/screens/video_player/components/danmaku_settings_sheet.dart';

Widget _host(void Function(BuildContext context) open) {
  return ProviderScope(
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('danmaku settings dialog renders credentials and toggles',
      (tester) async {
    await tester.pumpWidget(_host(showDanmakuSettings));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('弹幕设置'), findsOneWidget);
    expect(find.text('启用弹幕'), findsOneWidget);
    expect(find.text('弹弹play AppId'), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
  });

  testWidgets('send dialog validates empty input', (tester) async {
    await tester.pumpWidget(_host(showDanmakuSendDialog));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('发送弹幕'), findsOneWidget);
    await tester.tap(find.text('发送'));
    await tester.pump();
    expect(find.text('请输入弹幕内容'), findsOneWidget);
  });

  testWidgets('manual match dialog starts at the search step', (tester) async {
    await tester.pumpWidget(_host(showDanmakuMatchDialog));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('手动匹配弹幕'), findsOneWidget);
    expect(find.text('番剧名称'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
  });
}
