import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/models/error_log_model.dart';
import 'package:fladder/util/log_time.dart';

void main() {
  group('formatLogTime', () {
    test('renders the device clock as MM.dd-HH:mm', () {
      expect(formatLogTime(DateTime(2026, 10, 22, 18, 28)), '10.22-18:28');
    });

    test('pads single digit fields', () {
      expect(formatLogTime(DateTime(2026, 1, 2, 3, 4)), '01.02-03:04');
    });

    test('converts stored instants to the device clock', () {
      final local = DateTime(2026, 10, 22, 18, 28);
      expect(formatLogTime(local.toUtc()), '10.22-18:28');
    });
  });

  group('ErrorLogModel', () {
    test('shows its timestamp with the device clock format', () {
      final log = ErrorLogModel(
        type: ErrorType.severe,
        message: 'boom',
        time: DateTime(2026, 10, 22, 18, 28),
        stackTrace: null,
      );

      expect(log.content, startsWith('10.22-18:28'));
    });

    test('persists the instant so reloads keep the same moment', () {
      final log = ErrorLogModel(
        type: ErrorType.warning,
        message: 'warn',
        time: DateTime(2026, 10, 22, 18, 28, 21),
        stackTrace: null,
      );

      final restored = ErrorLogModel.fromJson(log.toJson());

      expect(restored.time.toUtc(), log.time.toUtc());
      expect(restored.content, startsWith('10.22-18:28'));
    });
  });
}
