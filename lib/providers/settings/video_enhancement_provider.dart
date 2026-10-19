import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fladder/video/video_enhancement.dart';

const _enhancementKey = 'jellymaku.video.enhancement.v1';

final videoEnhancementProvider =
    StateNotifierProvider<VideoEnhancementNotifier, VideoEnhancementProfile>(
        (ref) {
  return VideoEnhancementNotifier();
});

class VideoEnhancementNotifier extends StateNotifier<VideoEnhancementProfile> {
  VideoEnhancementNotifier() : super(VideoEnhancementProfile.off) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final name = prefs.getString(_enhancementKey);
    if (name == null) return;
    for (final profile in VideoEnhancementProfile.values) {
      if (profile.name == name) {
        state = profile;
        VideoEnhancementSettings.profile = profile;
        break;
      }
    }
  }

  void setProfile(VideoEnhancementProfile profile) {
    state = profile;
    VideoEnhancementSettings.profile = profile;
    _prefs?.setString(_enhancementKey, profile.name);
  }
}
