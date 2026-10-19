import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fladder/danmaku/secret_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round-trips a secret through the platform store', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DanmakuSecretStore();
    await store.write('jellymaku-test-secret');
    expect(await store.read(), 'jellymaku-test-secret');
    await store.write('');
    expect(await store.read(), '');
  });
}
