import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum VideoEnhancementProfile {
  off,
  anime4kFast,
  anime4kQuality,
  anime4kStrong,
  anime4k4x,
}

extension VideoEnhancementProfileDetails on VideoEnhancementProfile {
  String get label {
    return switch (this) {
      VideoEnhancementProfile.off => 'Off / 关闭',
      VideoEnhancementProfile.anime4kFast => 'Fast 2x / 快速',
      VideoEnhancementProfile.anime4kQuality => 'Balanced 2x / 均衡',
      VideoEnhancementProfile.anime4kStrong => 'Strong 2x / 强修复',
      VideoEnhancementProfile.anime4k4x => '4x / 极致',
    };
  }

  String get description {
    return switch (this) {
      VideoEnhancementProfile.off => '原始画面 · 不使用模型',
      VideoEnhancementProfile.anime4kFast => '2 倍放大 · Anime4K Upscale CNN x2 M',
      VideoEnhancementProfile.anime4kQuality =>
        '2 倍修复 · Anime4K Restore CNN M + Upscale CNN x2 M',
      VideoEnhancementProfile.anime4kStrong =>
        '2 倍强修复 · Anime4K Restore CNN L + Upscale CNN x2 M',
      VideoEnhancementProfile.anime4k4x =>
        '4 倍放大 · Anime4K Restore CNN M + Upscale CNN x2 M ×2',
    };
  }

  List<String> get assetPaths {
    return switch (this) {
      VideoEnhancementProfile.off => const [],
      VideoEnhancementProfile.anime4kFast => const [
          'assets/shaders/anime4k/Anime4K_Clamp_Highlights.glsl',
          'assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl',
        ],
      VideoEnhancementProfile.anime4kQuality => const [
          'assets/shaders/anime4k/Anime4K_Clamp_Highlights.glsl',
          'assets/shaders/anime4k/Anime4K_Restore_CNN_M.glsl',
          'assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl',
        ],
      VideoEnhancementProfile.anime4kStrong => const [
          'assets/shaders/anime4k/Anime4K_Clamp_Highlights.glsl',
          'assets/shaders/anime4k/Anime4K_Restore_CNN_L.glsl',
          'assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl',
        ],
      VideoEnhancementProfile.anime4k4x => const [
          'assets/shaders/anime4k/Anime4K_Clamp_Highlights.glsl',
          'assets/shaders/anime4k/Anime4K_Restore_CNN_M.glsl',
          'assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M.glsl',
          'assets/shaders/anime4k/Anime4K_Upscale_CNN_x2_M_2.glsl',
        ],
    };
  }
}

class VideoEnhancementSettings {
  static VideoEnhancementProfile profile = VideoEnhancementProfile.off;
}

Future<List<String>> prepareVideoEnhancementShaders(
  VideoEnhancementProfile profile,
) async {
  if (profile == VideoEnhancementProfile.off) return const [];

  final support = await getApplicationSupportDirectory();
  final directory = Directory(
    '${support.path}${Platform.pathSeparator}shaders${Platform.pathSeparator}${profile.name}',
  );
  await directory.create(recursive: true);

  final paths = <String>[];
  for (final asset in profile.assetPaths) {
    final name = asset.split('/').last;
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    if (!await file.exists() || await file.length() == 0) {
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    paths.add(file.path.replaceAll('\\', '/'));
  }
  return paths;
}

String glslShaderList(List<String> paths) {
  if (paths.isEmpty) return '';
  return paths.join(Platform.isWindows ? ';' : ':');
}
