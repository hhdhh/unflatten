import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unflatten_studio/app/unflatten_app.dart';

void main() {
  testWidgets('试拍表 lite 模式视觉基线', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('试拍表'));
    await tester.pumpAndSettle();

    final switchFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Switch),
    );
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Dialog),
      matchesGoldenFile('goldens/camera_lab_contact_sheet_lite.png'),
    );
  });

  testWidgets('试拍表 full 模式视觉基线', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('试拍表'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Dialog),
      matchesGoldenFile('goldens/camera_lab_contact_sheet_full.png'),
    );
  });
}
