import 'package:fladder/danmaku/danmaku_models.dart';

class DanmakuSettingsModel {
  final bool enabled;
  final String apiBase;
  final String fontFamily;
  final double fontSize;
  final double opacity;
  final double speedSeconds;
  final double displayArea;
  final double offsetSeconds;
  final int maxComments;
  final int cacheDays;
  final List<String> blockWords;
  final List<String> blockUsers;
  final bool autoMatch;
  final bool showScroll;
  final bool showTop;
  final bool showBottom;
  final bool showLocalSource;
  final bool mergeDuplicates;
  final bool showColor;
  final double strokeWidth;
  final String? localFile;

  const DanmakuSettingsModel({
    this.enabled = true,
    this.apiBase = kDefaultDanmuApiBase,
    this.fontFamily = 'Microsoft YaHei UI',
    this.fontSize = 36,
    this.opacity = 0.9,
    this.speedSeconds = 8,
    this.displayArea = 0.7,
    this.offsetSeconds = 0,
    this.maxComments = 20000,
    this.cacheDays = 7,
    this.blockWords = const [],
    this.blockUsers = const [],
    this.autoMatch = true,
    this.showScroll = true,
    this.showTop = true,
    this.showBottom = true,
    this.showLocalSource = true,
    this.mergeDuplicates = false,
    this.showColor = true,
    this.strokeWidth = 1.5,
    this.localFile,
  });

  static const defaults = DanmakuSettingsModel();

  /// 空地址回退公共实例，避免设置被清空后请求到相对 URI。
  String get effectiveApiBase {
    final value = apiBase.trim();
    return value.isEmpty ? kDefaultDanmuApiBase : value;
  }

  DanmakuSettingsModel copyWith({
    bool? enabled,
    String? apiBase,
    String? fontFamily,
    double? fontSize,
    double? opacity,
    double? speedSeconds,
    double? displayArea,
    double? offsetSeconds,
    int? maxComments,
    int? cacheDays,
    List<String>? blockWords,
    List<String>? blockUsers,
    bool? autoMatch,
    bool? showScroll,
    bool? showTop,
    bool? showBottom,
    bool? showLocalSource,
    bool? mergeDuplicates,
    bool? showColor,
    double? strokeWidth,
    String? localFile,
    bool clearLocalFile = false,
  }) {
    return DanmakuSettingsModel(
      enabled: enabled ?? this.enabled,
      apiBase: apiBase ?? this.apiBase,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      speedSeconds: speedSeconds ?? this.speedSeconds,
      displayArea: displayArea ?? this.displayArea,
      offsetSeconds: offsetSeconds ?? this.offsetSeconds,
      maxComments: maxComments ?? this.maxComments,
      cacheDays: cacheDays ?? this.cacheDays,
      blockWords: blockWords ?? this.blockWords,
      blockUsers: blockUsers ?? this.blockUsers,
      autoMatch: autoMatch ?? this.autoMatch,
      showScroll: showScroll ?? this.showScroll,
      showTop: showTop ?? this.showTop,
      showBottom: showBottom ?? this.showBottom,
      showLocalSource: showLocalSource ?? this.showLocalSource,
      mergeDuplicates: mergeDuplicates ?? this.mergeDuplicates,
      showColor: showColor ?? this.showColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      localFile: clearLocalFile ? null : (localFile ?? this.localFile),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'apiBase': apiBase,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'opacity': opacity,
      'speedSeconds': speedSeconds,
      'displayArea': displayArea,
      'offsetSeconds': offsetSeconds,
      'maxComments': maxComments,
      'cacheDays': cacheDays,
      'blockWords': blockWords,
      'blockUsers': blockUsers,
      'autoMatch': autoMatch,
      'showScroll': showScroll,
      'showTop': showTop,
      'showBottom': showBottom,
      'showLocalSource': showLocalSource,
      'mergeDuplicates': mergeDuplicates,
      'showColor': showColor,
      'strokeWidth': strokeWidth,
      'localFile': localFile,
    };
  }

  factory DanmakuSettingsModel.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList(growable: false);
      }
      return const [];
    }

    double number(Object? value, double fallback) {
      if (value is num) return value.toDouble();
      return fallback;
    }

    int integer(Object? value, int fallback) {
      if (value is num) return value.toInt();
      return fallback;
    }

    return DanmakuSettingsModel(
      enabled: json['enabled'] as bool? ?? true,
      apiBase: _migrateApiBase(json['apiBase']),
      fontFamily: json['fontFamily']?.toString() ?? 'Microsoft YaHei UI',
      fontSize: number(json['fontSize'], 36),
      opacity: number(json['opacity'], 0.9),
      speedSeconds: number(json['speedSeconds'], 8),
      displayArea: number(json['displayArea'], 0.7),
      offsetSeconds: number(json['offsetSeconds'], 0),
      maxComments: integer(json['maxComments'], 20000),
      cacheDays: integer(json['cacheDays'], 7),
      blockWords: strings(json['blockWords']),
      blockUsers: strings(json['blockUsers']),
      autoMatch: json['autoMatch'] as bool? ?? true,
      showScroll: json['showScroll'] as bool? ?? true,
      showTop: json['showTop'] as bool? ?? true,
      showBottom: json['showBottom'] as bool? ?? true,
      showLocalSource: json['showLocalSource'] as bool? ?? true,
      mergeDuplicates: json['mergeDuplicates'] as bool? ?? false,
      showColor: json['showColor'] as bool? ?? true,
      strokeWidth: number(json['strokeWidth'], 1.5),
      localFile: json['localFile']?.toString(),
    );
  }

  /// 旧版本的默认地址（或旧文档里的 http 地址）；统一迁到 https 公共实例。
  static String _migrateApiBase(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return kDefaultDanmuApiBase;
    final normalized = value.replaceAll(RegExp(r'/+$'), '').toLowerCase();
    if (normalized == 'http://api.dandanplay.net' ||
        normalized == 'https://api.dandanplay.net' ||
        normalized == 'http://danmu.api.tangbai.cc' ||
        normalized == 'https://danmu.api.tangbai.cc') {
      return kDefaultDanmuApiBase;
    }
    return value;
  }
}
