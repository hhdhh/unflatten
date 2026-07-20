import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unflatten_studio/app/unflatten_app.dart';
import 'package:unflatten_studio/features/camera_lab/data/camera_catalog.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/widgets/camera_preview.dart';

void main() {
  testWidgets('试拍表可打开并展示全部 24 台相机', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-contact-sheet')));
    await tester.pumpAndSettle();

    expect(find.text('Camera Contact Sheet'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(CameraPreview),
      ),
      findsNWidgets(cameraCatalog.length),
    );
  });

  testWidgets('试拍表 lite 模式仍然渲染 24 个 CameraPreview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-contact-sheet')));
    await tester.pumpAndSettle();

    final switchFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Switch),
    );
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(CameraPreview),
      ),
      findsNWidgets(cameraCatalog.length),
    );

    final fullPreviewFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! CameraPreview) return false;
        return widget.liteMode == false;
      }),
    );
    final litePreviewFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! CameraPreview) return false;
        return widget.liteMode == true;
      }),
    );
    expect(fullPreviewFinder, findsNothing);
    expect(litePreviewFinder, findsNWidgets(cameraCatalog.length));
  });
}
