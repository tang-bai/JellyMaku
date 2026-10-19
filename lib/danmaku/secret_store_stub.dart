import 'package:shared_preferences/shared_preferences.dart';

const _secretKey = 'jellymaku.danmaku.secret.v1';

class DanmakuSecretStore {
  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_secretKey) ?? '';
  }

  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(_secretKey);
    } else {
      await prefs.setString(_secretKey, value);
    }
  }
}
