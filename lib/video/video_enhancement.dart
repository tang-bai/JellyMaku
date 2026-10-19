import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum VideoEnhancementProfile {
  off,
  anime4kFast,
  anime4kQuality,
}

extension VideoEnhancementProfileDetails on VideoEnhancementProfile {
  String get label {
    return switch (this) {
      VideoEnhancementProfile.off => 'Off',
      VideoEnhancementProfile.anime4kFast => 'Anime4K Fast (2x)',
      VideoEnhancementProfile.anime4kQuality => 'Anime4K Quality (2x)',
    };
  }

  String get description {
    return switch (this) {
      VideoEnhancementProfile.off => 'Native video output',
      VideoEnhancementProfile.anime4kFast =>
        'Clamp + CNN upscale; low GPU cost',
      VideoEnhancementProfile.anime4kQuality =>
        'Clamp + restore + CNN upscale; higher GPU cost',
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
