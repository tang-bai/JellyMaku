import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/models/seerr_credentials_model.dart';
import 'package:fladder/providers/seerr_api_provider.dart';
import 'package:fladder/providers/seerr_service_provider.dart';
import 'package:fladder/providers/seerr_user_provider.dart';
import 'package:fladder/util/fladder_config.dart';

class _ExplodingSeerrApi extends SeerrApi {
  static int buildCount = 0;

  @override
  SeerrService build() {
    buildCount++;
    throw StateError('seerrApiProvider must not be built when Seerr is not configured');
  }
}

void main() {
  tearDown(() => FladderConfig.seerrBaseUrl = null);

  group('isSeerrConfigured', () {
    test('is false without credentials or a config url', () {
      expect(isSeerrConfigured(null), isFalse);
      expect(isSeerrConfigured(const SeerrCredentialsModel()), isFalse);
    });

    test('is false when only a server url is stored', () {
      expect(isSeerrConfigured(const SeerrCredentialsModel(serverUrl: 'http://seerr.local')), isFalse);
    });

    test('is true when an api key or session cookie is stored', () {
      expect(
        isSeerrConfigured(const SeerrCredentialsModel(serverUrl: 'http://seerr.local', apiKey: 'key')),
        isTrue,
      );
      expect(
        isSeerrConfigured(const SeerrCredentialsModel(serverUrl: 'http://seerr.local', sessionCookie: 'sid=1')),
        isTrue,
      );
    });

    test('is true when a config base url is provided', () {
      FladderConfig.seerrBaseUrl = ' http://seerr.local ';
      expect(isSeerrConfigured(null), isTrue);
    });

    test('ignores a blank config base url', () {
      FladderConfig.seerrBaseUrl = '   ';
      expect(isSeerrConfigured(null), isFalse);
    });
  });

  group('seerrUserProvider', () {
    test('does not touch the Seerr API while unconfigured', () {
      _ExplodingSeerrApi.buildCount = 0;
      final container = ProviderContainer(
        overrides: [seerrApiProvider.overrideWith(() => _ExplodingSeerrApi())],
      );
      addTearDown(container.dispose);

      expect(container.read(seerrUserProvider), isNull);
      expect(_ExplodingSeerrApi.buildCount, 0);
    });
  });
}
