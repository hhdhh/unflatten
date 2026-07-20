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
    expect(find.byKey(const Key('seed-input')), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });

  testWidgets('响应式断点附近不发生布局溢出', (tester) async {
    for (final size in const [
      Size(1100, 760),
      Size(1099, 760),
      Size(700, 760),
      Size(360, 780),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '窗口尺寸：$size');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Seed 输入支持十六进制提交', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('seed-input')), '00ABCDEF');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('SEED 00ABCDEF'), findsOneWidget);
  });
}
