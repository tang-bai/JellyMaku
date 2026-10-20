import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fladder/l10n/generated/app_localizations.dart';
import 'package:fladder/screens/video_player/components/danmaku_match_dialog.dart';
import 'package:fladder/screens/video_player/components/danmaku_settings_sheet.dart';

Widget _host(void Function(BuildContext context) open) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('danmaku settings dialog renders the API address section',
      (tester) async {
    await tester.pumpWidget(_host(showDanmakuSettings));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('弹幕设置'), findsOneWidget);
    expect(find.text('启用弹幕'), findsOneWidget);
    // 地址折叠在“高级”里，普通用户无需配置。
    expect(find.text('danmu_api 地址'), findsNothing);
    await tester.tap(find.text('高级：弹幕 API 地址'));
    await tester.pumpAndSettle();
    expect(find.text('danmu_api 地址'), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
    expect(find.text('简繁转换'), findsNothing);
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
