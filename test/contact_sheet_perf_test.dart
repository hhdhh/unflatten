import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unflatten_studio/app/unflatten_app.dart';
import 'package:unflatten_studio/features/camera_lab/presentation/widgets/camera_preview.dart';

/// 量度试拍表全实时 vs lite 模式的首帧渲染耗时。
///
/// Flutter widget test 不模拟真实 GPU 渲染，但仍可作为相对参考。
/// 全实时模式每格跑 4 种程序化效果（grain / halation / lightLeak / chromatic），
/// lite 模式跳过这些重操作，只保留色彩矩阵 + 暗角 + Bloom + 闪光。
Duration? _fullDuration;
Duration? _liteDuration;

Future<Duration> _measureContactSheetFirstFrame(
  WidgetTester tester, {
  required bool liteMode,
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 820));
  await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
  await tester.pumpAndSettle();

  final stopwatch = Stopwatch()..start();
  await tester.tap(find.text('试拍表'));
  await tester.pumpAndSettle();

  if (liteMode) {
    final switchFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Switch),
    );
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }
  stopwatch.stop();
  return stopwatch.elapsed;
}

void main() {
  testWidgets('量度全实时模式首帧耗时', (tester) async {
    _fullDuration = await _measureContactSheetFirstFrame(
      tester,
      liteMode: false,
    );
    expect(_fullDuration, isNotNull);
    debugPrint('[ContactSheet perf] full = ${_fullDuration!.inMilliseconds}ms');
  });

  testWidgets('量度 lite 模式首帧耗时', (tester) async {
    _liteDuration = await _measureContactSheetFirstFrame(
      tester,
      liteMode: true,
    );
    expect(_liteDuration, isNotNull);
    debugPrint('[ContactSheet perf] lite = ${_liteDuration!.inMilliseconds}ms');
  });

  test('lite 模式首帧渲染应明显快于全实时模式', () {
    expect(_fullDuration, isNotNull);
    expect(_liteDuration, isNotNull);
    expect(
      _liteDuration!,
      lessThan(_fullDuration!),
      reason:
          'lite 模式跳过 grain/halation/lightLeak/chromaticAberration，'
          '首帧渲染应该更快。当前 full=$_fullDuration, lite=$_liteDuration。',
    );
  });

  testWidgets('lite 模式下 24 个 CameraPreview 都开启 lite 标志',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 820));
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

    final previews = tester.widgetList<CameraPreview>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(CameraPreview),
      ),
    );
    expect(previews, isNotEmpty);
    expect(previews.every((preview) => preview.liteMode), isTrue);
  });
}
