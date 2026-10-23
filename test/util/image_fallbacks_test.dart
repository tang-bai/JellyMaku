import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/models/items/images_models.dart';
import 'package:fladder/screens/shared/detail_scaffold.dart';
import 'package:fladder/util/fladder_image.dart';

class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FailingImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(_FailingImageProvider key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future<ImageInfo>.error(Exception('404')));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getDominantColor ignores artwork that fails to load', () async {
    expect(await getDominantColor(_FailingImageProvider()), isNull);
  });

  testWidgets('FladderImage shows its placeholder instead of reporting the error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: FladderImage(
            image: ImageData(path: 'C:/__fladder_missing_artwork__/missing.png', key: 'missing'),
            placeHolder: const SizedBox(key: Key('image-fallback')),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('image-fallback')), findsOneWidget);
  });
}
