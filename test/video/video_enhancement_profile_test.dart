import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/video/video_enhancement.dart';

void main() {
  group('Anime4K profiles', () {
    test('strong profile uses the large restore model', () {
      final paths = VideoEnhancementProfile.anime4kStrong.assetPaths;
      expect(paths.length, 3);
      expect(
        paths,
        contains('assets/shaders/anime4k/Anime4K_Restore_CNN_L.glsl'),
      );
      expect(
        paths,
        contains('assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl'),
      );
    });

    test('4x profile chains two distinct x2 upscalers', () {
      final paths = VideoEnhancementProfile.anime4k4x.assetPaths;
      expect(paths.length, 4);
      expect(
        paths,
        contains('assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl'),
      );
      expect(
        paths,
        contains('assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M_2.glsl'),
      );
      expect(VideoEnhancementProfile.anime4k4x.label, contains('4x'));
      expect(VideoEnhancementProfile.anime4k4x.description, contains('4 倍'));
    });

    test('user-facing labels and descriptions are present', () {
      for (final profile in VideoEnhancementProfile.values) {
        expect(profile.label, isNotEmpty);
        expect(profile.description, isNotEmpty);
      }
      expect(VideoEnhancementProfile.anime4kQuality.label, contains('均衡'));
      expect(VideoEnhancementProfile.anime4kStrong.label, contains('强修复'));
    });
  });
}
