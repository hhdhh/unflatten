import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unflatten_studio/app/unflatten_app.dart';
import 'package:unflatten_studio/app/unflatten_router.dart';
import 'package:unflatten_studio/features/camera_lab/application/my_recipes_provider.dart';
import 'package:unflatten_studio/features/camera_lab/data/custom_recipes_storage.dart';
import 'package:unflatten_studio/features/camera_lab/domain/camera_recipe.dart';

CustomRecipe _makeSample({
  String id = 'c-test-1',
  String name = 'Test Recipe',
  double saturation = 0.42,
  double grain = 0.18,
  double vignette = 0.31,
  double chromatic = 0.05,
  double warmth = 0.66,
}) =>
    CustomRecipe(
      id: id,
      name: name,
      packName: 'optical',
      seed: 0xDEADBEEF,
      intensity: 0.88,
      tuning: CameraTuning(
        exposure: 0,
        contrast: 0.1,
        saturation: saturation,
        warmth: warmth,
        grain: grain,
        vignette: vignette,
        bloom: 0.3,
        flash: 0,
      ),
      dna: [saturation, grain, vignette, chromatic, warmth],
      createdAt: DateTime(2026, 7, 20),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('CustomRecipe 往返 JSON 不丢字段', () {
    final sample = _makeSample();
    final json = sample.toJson();
    final back = CustomRecipe.fromJson(json);
    expect(back.id, sample.id);
    expect(back.name, sample.name);
    expect(back.packName, sample.packName);
    expect(back.seed, sample.seed);
    expect(back.intensity, sample.intensity);
    expect(back.dna, sample.dna);
    expect(back.tuning.saturation, sample.tuning.saturation);
    expect(back.tuning.grain, sample.tuning.grain);
    expect(back.tuning.vignette, sample.tuning.vignette);
    expect(back.tuning.warmth, sample.tuning.warmth);
  });

  test('InMemoryCustomRecipesRepository.add / remove / clear 行为正确', () async {
    final repo = InMemoryCustomRecipesRepository();
    expect(repo.readAll(), isEmpty);
    await repo.add(_makeSample(id: 'a'));
    await repo.add(_makeSample(id: 'b'));
    await repo.add(_makeSample(id: 'c'));
    final all = repo.readAll();
    expect(all, hasLength(3));
    // add 总是插到队首（latest first）
    expect(all.first.id, 'c');
    await repo.remove('b');
    expect(repo.readAll().map((r) => r.id), ['c', 'a']);
    await repo.clear();
    expect(repo.readAll(), isEmpty);
  });

  testWidgets('MyRecipesNotifier 接 SharedPrefs 后能持久化', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPrefsCustomRecipesRepository(prefs);

    final notifier = MyRecipesNotifier(repo);
    expect(notifier.state, isEmpty);

    await notifier.add(_makeSample(id: 'persisted-1'));
    await notifier.add(_makeSample(id: 'persisted-2'));

    // 再开一个 notifier 模拟重启
    final notifier2 = MyRecipesNotifier(repo);
    final restored = notifier2.state;
    expect(restored, hasLength(2));
    final ids = restored.map((r) => r.id).toSet();
    expect(ids, containsAll({'persisted-1', 'persisted-2'}));

    await notifier2.remove('persisted-1');
    final notifier3 = MyRecipesNotifier(repo);
    expect(notifier3.state.map((r) => r.id), ['persisted-2']);
  });

  testWidgets('Mix Lab 路由可独立渲染，5 个轴 slider 都出现',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();

    unflattenRouter.go('/mix-lab');
    await tester.pumpAndSettle();

    expect(find.text('5 维调音台'), findsOneWidget);
    expect(find.text('SATURATION'), findsOneWidget);
    expect(find.text('GRAIN'), findsOneWidget);
    expect(find.text('VIGNETTE'), findsOneWidget);
    expect(find.text('CHROMATIC'), findsOneWidget);
    expect(find.text('WARMTH'), findsOneWidget);
    expect(find.text('INTENSITY'), findsOneWidget);
    expect(find.text('配方名'), findsWidgets);
    expect(find.text('SEED · 16进制'), findsWidgets);
    expect(find.text('导入图像'), findsWidgets);
    expect(find.text('导出 PNG'), findsWidgets);
    expect(find.text('保存到 My Recipes'), findsWidgets);
  });

  testWidgets('Mix Lab 导出按钮点击不会抛异常（无图像时仍能完成渲染）',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: UnflattenApp()));
    await tester.pumpAndSettle();
    unflattenRouter.go('/mix-lab');
    await tester.pumpAndSettle();

    // 导出按钮可能在视口外 → ensureVisible + scrollUntilVisible
    final exportBtn = find.text('导出 PNG');
    expect(exportBtn, findsWidgets);
    await tester.scrollUntilVisible(exportBtn.first, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(exportBtn.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyRecipesNotifier add/remove 状态机正确', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPrefsCustomRecipesRepository(prefs);
    final notifier = MyRecipesNotifier(repo);
    await notifier.add(_makeSample(id: 'e2e-1', name: 'E2E Blend'));
    expect(notifier.state.first.name, 'E2E Blend');
    expect(notifier.state, hasLength(1));
    await notifier.remove('e2e-1');
    expect(notifier.state, isEmpty);
  });
}
