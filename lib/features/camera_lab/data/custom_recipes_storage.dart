import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/camera_recipe.dart';

/// 用户自定义 recipe（5 轴 + seed + tuning + 名字 + pack）
class CustomRecipe {
  const CustomRecipe({
    required this.id,
    required this.name,
    required this.packName,
    required this.seed,
    required this.intensity,
    required this.tuning,
    required this.dna,
    required this.createdAt,
    this.forkedFromId,
  });

  final String id;
  final String name;
  final String packName;
  final int seed;
  final double intensity;
  final CameraTuning tuning;
  final List<double> dna;
  final DateTime createdAt;
  final String? forkedFromId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pack': packName,
        'seed': seed,
        'intensity': intensity,
        'tuning': {
          'exposure': tuning.exposure,
          'contrast': tuning.contrast,
          'saturation': tuning.saturation,
          'warmth': tuning.warmth,
          'grain': tuning.grain,
          'vignette': tuning.vignette,
          'bloom': tuning.bloom,
          'flash': tuning.flash,
        },
        'dna': dna,
        'createdAt': createdAt.toIso8601String(),
        if (forkedFromId != null) 'forked': forkedFromId,
      };

  static CustomRecipe fromJson(Map<String, dynamic> j) => CustomRecipe(
        id: j['id'] as String,
        name: j['name'] as String,
        packName: j['pack'] as String,
        seed: (j['seed'] as num).toInt(),
        intensity: (j['intensity'] as num).toDouble(),
        tuning: CameraTuning(
          exposure: (j['tuning']['exposure'] as num).toDouble(),
          contrast: (j['tuning']['contrast'] as num).toDouble(),
          saturation: (j['tuning']['saturation'] as num).toDouble(),
          warmth: (j['tuning']['warmth'] as num).toDouble(),
          grain: (j['tuning']['grain'] as num).toDouble(),
          vignette: (j['tuning']['vignette'] as num).toDouble(),
          bloom: (j['tuning']['bloom'] as num).toDouble(),
          flash: (j['tuning']['flash'] as num).toDouble(),
        ),
        dna: (j['dna'] as List).map((e) => (e as num).toDouble()).toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        forkedFromId: j['forked'] as String?,
      );
}

/// Custom recipe 仓库接口
abstract class CustomRecipesRepository {
  List<CustomRecipe> readAll();
  Future<void> add(CustomRecipe r);
  Future<void> remove(String id);
  Future<void> clear();
}

/// 内存版（用于 loading/error 状态）
class InMemoryCustomRecipesRepository implements CustomRecipesRepository {
  final List<CustomRecipe> _list = [];
  @override
  List<CustomRecipe> readAll() => List.unmodifiable(_list);
  @override
  Future<void> add(CustomRecipe r) async => _list.insert(0, r);
  @override
  Future<void> remove(String id) async =>
      _list.removeWhere((r) => r.id == id);
  @override
  Future<void> clear() async => _list.clear();
}

/// SharedPreferences 版（web/desktop/mobile 真持久化）
class SharedPrefsCustomRecipesRepository implements CustomRecipesRepository {
  SharedPrefsCustomRecipesRepository(this._prefs);

  static const _key = 'unflatten.customRecipes.v1';
  final SharedPreferences _prefs;

  static Future<SharedPrefsCustomRecipesRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsCustomRecipesRepository(prefs);
  }

  @override
  List<CustomRecipe> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CustomRecipe.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> add(CustomRecipe r) async {
    final list = readAll();
    list.insert(0, r);
    await _write(list);
  }

  @override
  Future<void> remove(String id) async {
    final list = readAll()..removeWhere((r) => r.id == id);
    await _write(list);
  }

  @override
  Future<void> clear() async => _prefs.remove(_key);

  Future<void> _write(List<CustomRecipe> list) async {
    final raw =
        jsonEncode(list.map((r) => r.toJson()).toList(growable: false));
    await _prefs.setString(_key, raw);
  }
}
