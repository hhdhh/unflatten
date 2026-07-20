import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/custom_recipes_storage.dart';


/// 异步获取 SharedPreferences 实例
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// 异步 repo（web/desktop 自动 lazy init）
final customRecipesRepositoryProvider =
    FutureProvider<CustomRecipesRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SharedPrefsCustomRecipesRepository(prefs);
});

/// 同步 repo：永远可用（loading/error 时回退内存版）
final syncCustomRecipesRepositoryProvider =
    Provider<CustomRecipesRepository>((ref) {
  final asyncRepo = ref.watch(customRecipesRepositoryProvider);
  return asyncRepo.maybeWhen(
    data: (r) => r,
    orElse: () => InMemoryCustomRecipesRepository(),
  );
});

class MyRecipesNotifier extends StateNotifier<List<CustomRecipe>> {
  MyRecipesNotifier(this._repo) : super(_repo.readAll());

  final CustomRecipesRepository _repo;

  Future<void> add(CustomRecipe r) async {
    final next = [r, ...state];
    state = next;
    await _repo.add(r);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _repo.remove(id);
  }

  Future<void> clear() async {
    state = [];
    await _repo.clear();
  }
}

final myRecipesProvider =
    StateNotifierProvider<MyRecipesNotifier, List<CustomRecipe>>((ref) {
  final repo = ref.watch(syncCustomRecipesRepositoryProvider);
  return MyRecipesNotifier(repo);
});
