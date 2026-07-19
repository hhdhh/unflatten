import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unflatten_studio/app/unflatten_app.dart';

void main() {
  testWidgets('窄屏展示移动端 Camera Lab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('camera-lab-mobile')), findsOneWidget);
    expect(find.text('Warm 35'), findsWidgets);
    expect(find.text('试拍表'), findsOneWidget);
    expect(find.text('调校'), findsOneWidget);
  });

  testWidgets('宽屏展示三栏 Camera Lab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('camera-lab-desktop')), findsOneWidget);
    expect(find.text('CAMERA PACKS'), findsOneWidget);
    expect(find.text('CAMERA DNA'), findsOneWidget);
    expect(find.text('复制配方'), findsOneWidget);
  });
}
