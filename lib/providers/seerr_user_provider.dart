import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fladder/providers/seerr_api_provider.dart';
import 'package:fladder/providers/user_provider.dart';
import 'package:fladder/seerr/seerr_models.dart';

part 'seerr_user_provider.g.dart';

@riverpod
class SeerrUser extends _$SeerrUser {
  bool _disposed = false;

  @override
  SeerrUserModel? build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final credentials = ref.watch(userProvider.select((user) => user?.seerrCredentials));
    // Seerr is optional: with no server configured every request throws inside
    // the interceptor, so don't ask for the current user at all.
    if (!isSeerrConfigured(credentials)) return null;

    _fetchUser();
    return null;
  }

  Future<void> _fetchUser() async {
    try {
      final api = ref.read(seerrApiProvider);
      final response = await api.me();
      if (_disposed) return;
      if (response.isSuccessful && response.body is SeerrUserModel) {
        state = response.body as SeerrUserModel;
      }
    } catch (error, stackTrace) {
      // A failed lookup only means "no Seerr user"; it must not surface as an
      // unhandled error in the crash log.
      log('Failed to load Seerr user', error: error, stackTrace: stackTrace);
    }
  }

  Future<SeerrUserModel?> refreshUser() async {
    if (!isSeerrConfigured(ref.read(userProvider)?.seerrCredentials)) return null;
    final api = ref.read(seerrApiProvider);
    final response = await api.me();
    if (response.isSuccessful && response.body is SeerrUserModel) {
      state = response.body as SeerrUserModel;
      return response.body as SeerrUserModel;
    }
    return null;
  }

  void clearUser() {
    state = null;
  }
}
