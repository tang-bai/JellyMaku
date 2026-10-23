import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  test('zh and zh_Hant cover every English ARB message', () {
    final template = _readArb('en');
    final required = template.keys.where((key) => !key.startsWith('@')).toSet();

    for (final locale in ['zh', 'zh_Hant']) {
      final messages = _readArb(locale);
      final missing =
          required.where((key) => !messages.containsKey(key)).toList();
      final empty = required.where((key) {
        final value = messages[key];
        return value is String && value.trim().isEmpty;
      }).toList();

      expect(missing, isEmpty,
          reason: '$locale is missing: ${missing.join(', ')}');
      expect(empty, isEmpty,
          reason: '$locale has empty messages: ${empty.join(', ')}');
    }
  });
}
