import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unflatten_studio/features/camera_lab/data/camera_catalog.dart';
import 'package:unflatten_studio/features/camera_lab/domain/camera_recipe.dart';

enum TuningParameter {
  exposure('曝光', -1.5, 1.5),
  contrast('对比', -1, 1),
  saturation('饱和', -1, 1),
  warmth('冷暖', -1, 1),
  grain('颗粒', 0, 1),
  vignette('暗角', 0, 1),
  bloom('光晕', 0, 1),
  flash('闪光', 0, 1);

  const TuningParameter(this.label, this.min, this.max);

  final String label;
  final double min;
  final double max;
}

class ImportedImage {
  const ImportedImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class CameraLabState {
  const CameraLabState({
    required this.selectedPack,
    required this.selectedRecipeId,
    required this.intensity,
    required this.seed,
    required this.tuning,
    required this.protectedRegions,
    this.image,
  });

  factory CameraLabState.initial() {
    final recipe = cameraCatalog.first;
    return CameraLabState(
      selectedPack: recipe.pack,
      selectedRecipeId: recipe.id,
      intensity: 0.86,
      seed: recipe.seed,
      tuning: CameraTuning.fromRecipe(recipe),
      protectedRegions: recipe.protect.toSet(),
    );
  }

  final CameraPack selectedPack;
  final String selectedRecipeId;
  final double intensity;
  final int seed;
  final CameraTuning tuning;
  final Set<SemanticRegion> protectedRegions;
  final ImportedImage? image;

  CameraRecipe get recipe => cameraCatalog.firstWhere(
    (candidate) => candidate.id == selectedRecipeId,
    orElse: () => cameraCatalog.first,
  );

  List<CameraRecipe> get visibleRecipes => cameraCatalog
      .where((candidate) => candidate.pack == selectedPack)
      .toList(growable: false);

  CameraLabState copyWith({
    CameraPack? selectedPack,
    String? selectedRecipeId,
    double? intensity,
    int? seed,
    CameraTuning? tuning,
    Set<SemanticRegion>? protectedRegions,
    ImportedImage? image,
    bool clearImage = false,
  }) => CameraLabState(
    selectedPack: selectedPack ?? this.selectedPack,
    selectedRecipeId: selectedRecipeId ?? this.selectedRecipeId,
    intensity: intensity ?? this.intensity,
    seed: seed ?? this.seed,
    tuning: tuning ?? this.tuning,
    protectedRegions: protectedRegions ?? this.protectedRegions,
    image: clearImage ? null : image ?? this.image,
  );
}

class CameraLabController extends Notifier<CameraLabState> {
  @override
  CameraLabState build() => CameraLabState.initial();

  void selectPack(CameraPack pack) {
    final recipe = cameraCatalog.firstWhere(
      (candidate) => candidate.pack == pack,
    );
    state = state.copyWith(
      selectedPack: pack,
      selectedRecipeId: recipe.id,
      seed: recipe.seed,
      tuning: CameraTuning.fromRecipe(recipe),
      protectedRegions: recipe.protect.toSet(),
    );
  }

  void selectRecipe(CameraRecipe recipe) {
    state = state.copyWith(
      selectedPack: recipe.pack,
      selectedRecipeId: recipe.id,
      seed: recipe.seed,
      tuning: CameraTuning.fromRecipe(recipe),
      protectedRegions: recipe.protect.toSet(),
    );
  }

  void setIntensity(double value) {
    state = state.copyWith(intensity: value.clamp(0, 1).toDouble());
  }

  void setSeed(int value) {
    state = state.copyWith(seed: value & 0x7fffffff);
  }

  void randomizeSeed() {
    final random = SplitMix64(
      state.seed ^ DateTime.now().microsecondsSinceEpoch,
    );
    state = state.copyWith(seed: random.nextUint64().toInt() & 0x7fffffff);
  }

  void setTuning(TuningParameter parameter, double value) {
    final clamped = value.clamp(parameter.min, parameter.max).toDouble();
    final tuning = switch (parameter) {
      TuningParameter.exposure => state.tuning.copyWith(exposure: clamped),
      TuningParameter.contrast => state.tuning.copyWith(contrast: clamped),
      TuningParameter.saturation => state.tuning.copyWith(saturation: clamped),
      TuningParameter.warmth => state.tuning.copyWith(warmth: clamped),
      TuningParameter.grain => state.tuning.copyWith(grain: clamped),
      TuningParameter.vignette => state.tuning.copyWith(vignette: clamped),
      TuningParameter.bloom => state.tuning.copyWith(bloom: clamped),
      TuningParameter.flash => state.tuning.copyWith(flash: clamped),
    };
    state = state.copyWith(tuning: tuning);
  }

  void resetTuning() {
    state = state.copyWith(
      seed: state.recipe.seed,
      tuning: CameraTuning.fromRecipe(state.recipe),
      protectedRegions: state.recipe.protect.toSet(),
    );
  }

  void toggleProtectedRegion(SemanticRegion region) {
    final updated = state.protectedRegions.toSet();
    if (!updated.add(region)) {
      updated.remove(region);
    }
    state = state.copyWith(protectedRegions: updated);
  }

  void setImage(ImportedImage image) {
    state = state.copyWith(image: image);
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }
}

final cameraLabProvider = NotifierProvider<CameraLabController, CameraLabState>(
  CameraLabController.new,
);
