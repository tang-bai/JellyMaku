import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fladder/danmaku/secret_store.dart';
import 'package:fladder/models/settings/danmaku_settings_model.dart';

const _settingsKey = 'jellymaku.danmaku.settings.v1';

final danmakuSettingsProvider =
    StateNotifierProvider<DanmakuSettingsNotifier, DanmakuSettingsModel>((ref) {
  return DanmakuSettingsNotifier();
});

class DanmakuSettingsNotifier extends StateNotifier<DanmakuSettingsModel> {
  DanmakuSettingsNotifier() : super(DanmakuSettingsModel.defaults) {
    _load();
  }

  SharedPreferences? _prefs;
  final _secretStore = DanmakuSecretStore();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final secret = await _secretStore.read();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      if (secret.isNotEmpty) {
        state = state.copyWith(appSecret: secret);
      }
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        state = DanmakuSettingsModel.fromJson(decoded, appSecret: secret);
      }
    } catch (_) {
      // Keep defaults on malformed settings.
    }
  }

  void _apply(DanmakuSettingsModel next) {
    state = next;
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(_settingsKey, jsonEncode(next.toJson()));
    unawaited(_secretStore.write(next.appSecret));
  }

  void setEnabled(bool value) => _apply(state.copyWith(enabled: value));

  void setCredentials({String? appId, String? appSecret}) {
    _apply(state.copyWith(
      appId: appId?.trim(),
      appSecret: appSecret?.trim(),
    ));
  }

  void setApiBase(String value) =>
      _apply(state.copyWith(apiBase: value.trim()));

  void setFontFamily(String value) => _apply(state.copyWith(fontFamily: value));

  void setFontSize(double value) =>
      _apply(state.copyWith(fontSize: value.clamp(12, 96)));

  void setOpacity(double value) =>
      _apply(state.copyWith(opacity: value.clamp(0.1, 1.0)));

  void setSpeed(double value) =>
      _apply(state.copyWith(speedSeconds: value.clamp(2, 30)));

  void setDisplayArea(double value) =>
      _apply(state.copyWith(displayArea: value.clamp(0.2, 1.0)));

  void setOffset(double value) =>
      _apply(state.copyWith(offsetSeconds: value.clamp(-30, 30)));

  void setChConvert(int value) =>
      _apply(state.copyWith(chConvert: value.clamp(0, 2)));

  void setMaxComments(int value) =>
      _apply(state.copyWith(maxComments: value.clamp(100, 100000)));

  void setCacheDays(int value) =>
      _apply(state.copyWith(cacheDays: value.clamp(0, 90)));

  void setBlockWords(List<String> value) =>
      _apply(state.copyWith(blockWords: value));

  void setBlockUsers(List<String> value) =>
      _apply(state.copyWith(blockUsers: value));

  void setAutoMatch(bool value) => _apply(state.copyWith(autoMatch: value));

  void setHashMatch(bool value) => _apply(state.copyWith(hashMatch: value));

  void setShowScroll(bool value) => _apply(state.copyWith(showScroll: value));

  void setShowTop(bool value) => _apply(state.copyWith(showTop: value));

  void setShowBottom(bool value) => _apply(state.copyWith(showBottom: value));

  void setLocalFile(String? value) {
    _apply(state.copyWith(localFile: value));
  }
}
