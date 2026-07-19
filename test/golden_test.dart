import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unflatten_studio/app/unflatten_app.dart';

void main() {
  testWidgets('移动端工作区视觉基线', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('camera-lab-mobile')),
      matchesGoldenFile('goldens/camera_lab_mobile.png'),
    );
  });

  testWidgets('桌面端工作区视觉基线', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('camera-lab-desktop')),
      matchesGoldenFile('goldens/camera_lab_desktop.png'),
    );
  });
}

