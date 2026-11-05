import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/widgets/rich_html.dart';

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  Canvas(rec).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = Colors.red,
  );
  final img = await rec.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('the full-screen viewer gives a small picture the whole screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bytes = await tester.runAsync(() => _png(160, 100));
    late BuildContext ctx;
    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );
    openImageProviderViewer(ctx, MemoryImage(bytes!));
    await tester.pumpAndSettle();
    final box = tester.renderObject<RenderBox>(find.byType(Image));
    // The picture gets the whole screen to fit in (and is centred), not just the corner under the close button.
    expect(box.size, const Size(400, 800));
    expect(box.localToGlobal(Offset.zero), Offset.zero);
  });
}
