import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unflatten_studio/features/camera_lab/application/camera_lab_controller.dart';

void main() {
  late ProviderContainer container;
  late CameraLabController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(cameraLabProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('普通编辑支持撤销与重做', () {
    final initial = container.read(cameraLabProvider);

    controller.setIntensity(0.42);
    expect(container.read(cameraLabProvider).intensity, 0.42);
    expect(container.read(cameraLabProvider).canUndo, isTrue);

    controller.undo();
    expect(container.read(cameraLabProvider).intensity, initial.intensity);
    expect(container.read(cameraLabProvider).canRedo, isTrue);

    controller.redo();
    expect(container.read(cameraLabProvider).intensity, 0.42);
    expect(container.read(cameraLabProvider).canUndo, isTrue);
  });

  test('一次滑块拖动只生成一个历史步骤', () {
    final initial = container.read(cameraLabProvider).intensity;

    controller.beginHistoryTransaction();
    controller.setIntensity(0.75);
    controller.setIntensity(0.61);
    controller.setIntensity(0.38);
    controller.endHistoryTransaction();

    expect(container.read(cameraLabProvider).intensity, 0.38);
    controller.undo();
    expect(container.read(cameraLabProvider).intensity, initial);
    expect(container.read(cameraLabProvider).canUndo, isFalse);

    controller.redo();
    expect(container.read(cameraLabProvider).intensity, 0.38);
  });

  test('新编辑会清空重做分支', () {
    controller.setSeed(0x12345678);
    controller.undo();
    expect(container.read(cameraLabProvider).canRedo, isTrue);

    controller.setSeed(0x0abcdef0);
    expect(container.read(cameraLabProvider).canRedo, isFalse);
    expect(container.read(cameraLabProvider).seed, 0x0abcdef0);
  });

  test('历史记录限制为 32 步', () {
    for (var index = 1; index <= 40; index++) {
      controller.setSeed(index);
    }

    var undoCount = 0;
    while (container.read(cameraLabProvider).canUndo) {
      controller.undo();
      undoCount++;
    }

    expect(undoCount, CameraLabController.maxHistoryEntries);
    expect(container.read(cameraLabProvider).seed, 8);
  });

  test('历史快照复用同一份图片字节', () {
    final image = ImportedImage(name: 'test.png', bytes: Uint8List(2048));
    controller.setImage(image);
    controller.setIntensity(0.5);
    controller.undo();

    expect(container.read(cameraLabProvider).image, same(image));
    expect(container.read(cameraLabProvider).image?.bytes, same(image.bytes));
  });
}
