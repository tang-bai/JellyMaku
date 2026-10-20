class DanmakuSettingsModel {
  final bool enabled;
  final String appId;
  final String appSecret;
  final String apiBase;
  final String fontFamily;
  final double fontSize;
  final double opacity;
  final double speedSeconds;
  final double displayArea;
  final double offsetSeconds;
  final int chConvert;
  final int maxComments;
  final int cacheDays;
  final List<String> blockWords;
  final List<String> blockUsers;
  final bool autoMatch;
  final bool hashMatch;
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
    this.appId = '',
    this.appSecret = '',
    this.apiBase = 'https://api.dandanplay.net',
    this.fontFamily = 'Microsoft YaHei UI',
    this.fontSize = 36,
    this.opacity = 0.9,
    this.speedSeconds = 8,
    this.displayArea = 0.7,
    this.offsetSeconds = 0,
    this.chConvert = 1,
    this.maxComments = 20000,
    this.cacheDays = 7,
    this.blockWords = const [],
    this.blockUsers = const [],
    this.autoMatch = true,
    this.hashMatch = false,
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

  bool get hasCredentials =>
      appId.trim().isNotEmpty && appSecret.trim().isNotEmpty;

  DanmakuSettingsModel copyWith({
    bool? enabled,
    String? appId,
    String? appSecret,
    String? apiBase,
    String? fontFamily,
    double? fontSize,
    double? opacity,
    double? speedSeconds,
    double? displayArea,
    double? offsetSeconds,
    int? chConvert,
    int? maxComments,
    int? cacheDays,
    List<String>? blockWords,
    List<String>? blockUsers,
    bool? autoMatch,
    bool? hashMatch,
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
      appId: appId ?? this.appId,
      appSecret: appSecret ?? this.appSecret,
      apiBase: apiBase ?? this.apiBase,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      speedSeconds: speedSeconds ?? this.speedSeconds,
      displayArea: displayArea ?? this.displayArea,
      offsetSeconds: offsetSeconds ?? this.offsetSeconds,
      chConvert: chConvert ?? this.chConvert,
      maxComments: maxComments ?? this.maxComments,
      cacheDays: cacheDays ?? this.cacheDays,
      blockWords: blockWords ?? this.blockWords,
      blockUsers: blockUsers ?? this.blockUsers,
      autoMatch: autoMatch ?? this.autoMatch,
      hashMatch: hashMatch ?? this.hashMatch,
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
      'appId': appId,
      'apiBase': apiBase,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'opacity': opacity,
      'speedSeconds': speedSeconds,
      'displayArea': displayArea,
      'offsetSeconds': offsetSeconds,
      'chConvert': chConvert,
      'maxComments': maxComments,
      'cacheDays': cacheDays,
      'blockWords': blockWords,
      'blockUsers': blockUsers,
      'autoMatch': autoMatch,
      'hashMatch': hashMatch,
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

  factory DanmakuSettingsModel.fromJson(Map<String, dynamic> json,
      {String appSecret = ''}) {
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
      appId: json['appId']?.toString() ?? '',
      appSecret: appSecret,
      apiBase: json['apiBase']?.toString() ?? 'https://api.dandanplay.net',
      fontFamily: json['fontFamily']?.toString() ?? 'Microsoft YaHei UI',
      fontSize: number(json['fontSize'], 36),
      opacity: number(json['opacity'], 0.9),
      speedSeconds: number(json['speedSeconds'], 8),
      displayArea: number(json['displayArea'], 0.7),
      offsetSeconds: number(json['offsetSeconds'], 0),
      chConvert: integer(json['chConvert'], 1),
      maxComments: integer(json['maxComments'], 20000),
      cacheDays: integer(json['cacheDays'], 7),
      blockWords: strings(json['blockWords']),
      blockUsers: strings(json['blockUsers']),
      autoMatch: json['autoMatch'] as bool? ?? true,
      hashMatch: json['hashMatch'] as bool? ?? false,
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
}
