import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _secretKey = 'jellymaku.danmaku.secret.v1';
const _prefix = 'dpapi:';
const _cryptProtectUiForbidden = 0x1;

final class _DataBlob extends Struct {
  @Uint32()
  external int cbData;

  external Pointer<Uint8> pbData;
}

typedef _CryptProtectDataNative = Int32 Function(
  Pointer<_DataBlob> pDataIn,
  Pointer<Utf16> szDataDescr,
  Pointer<_DataBlob> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  Uint32 dwFlags,
  Pointer<_DataBlob> pDataOut,
);

typedef _CryptProtectDataDart = int Function(
  Pointer<_DataBlob> pDataIn,
  Pointer<Utf16> szDataDescr,
  Pointer<_DataBlob> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  int dwFlags,
  Pointer<_DataBlob> pDataOut,
);

typedef _CryptUnprotectDataNative = Int32 Function(
  Pointer<_DataBlob> pDataIn,
  Pointer<Pointer<Utf16>> ppszDataDescr,
  Pointer<_DataBlob> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  Uint32 dwFlags,
  Pointer<_DataBlob> pDataOut,
);

typedef _CryptUnprotectDataDart = int Function(
  Pointer<_DataBlob> pDataIn,
  Pointer<Pointer<Utf16>> ppszDataDescr,
  Pointer<_DataBlob> pOptionalEntropy,
  Pointer<Void> pvReserved,
  Pointer<Void> pPromptStruct,
  int dwFlags,
  Pointer<_DataBlob> pDataOut,
);

class DanmakuSecretStore {
  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_secretKey) ?? '';
    if (raw.isEmpty) return '';
    if (!Platform.isWindows || !raw.startsWith(_prefix)) {
      return raw;
    }
    try {
      final encrypted = base64Decode(raw.substring(_prefix.length));
      return utf8.decode(_unprotect(encrypted));
    } catch (_) {
      return '';
    }
  }

  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(_secretKey);
      return;
    }
    if (Platform.isWindows) {
      try {
        final encrypted = _protect(utf8.encode(value));
        await prefs.setString(_secretKey, '$_prefix${base64Encode(encrypted)}');
        return;
      } catch (_) {
        // Fall through to plain text only if DPAPI is unavailable; read()
        // still returns the legacy value so the user does not lose it.
      }
    }
    await prefs.setString(_secretKey, value);
  }
}

List<int> _protect(List<int> plain) {
  final input = calloc<Uint8>(plain.length);
  input.asTypedList(plain.length).setAll(0, plain);
  final blobIn = calloc<_DataBlob>();
  blobIn.ref.cbData = plain.length;
  blobIn.ref.pbData = input;
  final blobOut = calloc<_DataBlob>();
  try {
    final result = _cryptProtect(
      blobIn,
      nullptr,
      nullptr,
      nullptr,
      nullptr,
      _cryptProtectUiForbidden,
      blobOut,
    );
    if (result == 0) throw StateError('CryptProtectData failed');
    return blobOut.ref.pbData.asTypedList(blobOut.ref.cbData).toList();
  } finally {
    if (blobOut.ref.pbData != nullptr) _localFree(blobOut.ref.pbData.cast());
    calloc.free(blobOut);
    calloc.free(blobIn);
    calloc.free(input);
  }
}

List<int> _unprotect(List<int> encrypted) {
  final input = calloc<Uint8>(encrypted.length);
  input.asTypedList(encrypted.length).setAll(0, encrypted);
  final blobIn = calloc<_DataBlob>();
  blobIn.ref.cbData = encrypted.length;
  blobIn.ref.pbData = input;
  final blobOut = calloc<_DataBlob>();
  try {
    final result = _cryptUnprotect(
      blobIn,
      nullptr,
      nullptr,
      nullptr,
      nullptr,
      _cryptProtectUiForbidden,
      blobOut,
    );
    if (result == 0) throw StateError('CryptUnprotectData failed');
    return blobOut.ref.pbData.asTypedList(blobOut.ref.cbData).toList();
  } finally {
    if (blobOut.ref.pbData != nullptr) _localFree(blobOut.ref.pbData.cast());
    calloc.free(blobOut);
    calloc.free(blobIn);
    calloc.free(input);
  }
}

final _CryptProtectDataDart _cryptProtect = DynamicLibrary.open('crypt32.dll')
    .lookupFunction<_CryptProtectDataNative, _CryptProtectDataDart>(
        'CryptProtectData');

final _CryptUnprotectDataDart _cryptUnprotect =
    DynamicLibrary.open('crypt32.dll')
        .lookupFunction<_CryptUnprotectDataNative, _CryptUnprotectDataDart>(
            'CryptUnprotectData');

final Pointer<Void> Function(Pointer<Void>) _localFree =
    DynamicLibrary.open('kernel32.dll').lookupFunction<
        Pointer<Void> Function(Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>)>('LocalFree');
