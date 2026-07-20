import 'package:flutter/foundation.dart';
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
    this.canUndo = false,
    this.canRedo = false,
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
  final bool canUndo;
  final bool canRedo;
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
    bool? canUndo,
    bool? canRedo,
    ImportedImage? image,
    bool clearImage = false,
  }) => CameraLabState(
    selectedPack: selectedPack ?? this.selectedPack,
    selectedRecipeId: selectedRecipeId ?? this.selectedRecipeId,
    intensity: intensity ?? this.intensity,
    seed: seed ?? this.seed,
    tuning: tuning ?? this.tuning,
    protectedRegions: protectedRegions ?? this.protectedRegions,
    canUndo: canUndo ?? this.canUndo,
    canRedo: canRedo ?? this.canRedo,
    image: clearImage ? null : image ?? this.image,
  );
}

class CameraLabController extends Notifier<CameraLabState> {
  static const maxHistoryEntries = 32;

  final List<CameraLabState> _undoStack = [];
  final List<CameraLabState> _redoStack = [];
  CameraLabState? _transactionStart;
  bool _transactionChanged = false;

  @override
  CameraLabState build() => CameraLabState.initial();

  void beginHistoryTransaction() {
    if (_transactionStart != null) return;
    _transactionStart = _snapshot(state);
    _transactionChanged = false;
  }

  void endHistoryTransaction() {
    final start = _transactionStart;
    _transactionStart = null;
    if (start != null && _transactionChanged && !_sameContent(start, state)) {
      _pushBounded(_undoStack, start);
    }
    _transactionChanged = false;
    state = _withHistoryFlags(state);
  }

  void undo() {
    _finishActiveTransaction();
    if (_undoStack.isEmpty) return;
    _pushBounded(_redoStack, _snapshot(state));
    state = _withHistoryFlags(_undoStack.removeLast());
  }

  void redo() {
    _finishActiveTransaction();
    if (_redoStack.isEmpty) return;
    _pushBounded(_undoStack, _snapshot(state));
    state = _withHistoryFlags(_redoStack.removeLast());
  }

  void selectPack(CameraPack pack) {
    final recipe = cameraCatalog.firstWhere(
      (candidate) => candidate.pack == pack,
    );
    _commit(
      state.copyWith(
        selectedPack: pack,
        selectedRecipeId: recipe.id,
        seed: recipe.seed,
        tuning: CameraTuning.fromRecipe(recipe),
        protectedRegions: recipe.protect.toSet(),
      ),
    );
  }

  void selectRecipe(CameraRecipe recipe) {
    _commit(
      state.copyWith(
        selectedPack: recipe.pack,
        selectedRecipeId: recipe.id,
        seed: recipe.seed,
        tuning: CameraTuning.fromRecipe(recipe),
        protectedRegions: recipe.protect.toSet(),
      ),
    );
  }

  void setIntensity(double value) {
    _commit(state.copyWith(intensity: value.clamp(0, 1).toDouble()));
  }

  void setSeed(int value) {
    _commit(state.copyWith(seed: value & 0x7fffffff));
  }

  void randomizeSeed() {
    final random = SplitMix64(
      state.seed ^ DateTime.now().microsecondsSinceEpoch,
    );
    _commit(state.copyWith(seed: random.nextUint64().toInt() & 0x7fffffff));
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
    _commit(state.copyWith(tuning: tuning));
  }

  void resetTuning() {
    _commit(
      state.copyWith(
        intensity: 0.86,
        seed: state.recipe.seed,
        tuning: CameraTuning.fromRecipe(state.recipe),
        protectedRegions: state.recipe.protect.toSet(),
      ),
    );
  }

  void toggleProtectedRegion(SemanticRegion region) {
    final updated = state.protectedRegions.toSet();
    if (!updated.add(region)) {
      updated.remove(region);
    }
    _commit(state.copyWith(protectedRegions: updated));
  }

  void setImage(ImportedImage image) {
    _commit(state.copyWith(image: image));
  }

  void clearImage() {
    _commit(state.copyWith(clearImage: true));
  }

  void _commit(CameraLabState next) {
    if (_sameContent(state, next)) return;
    if (_transactionStart != null) {
      _transactionChanged = true;
      _redoStack.clear();
      state = _withHistoryFlags(next);
      return;
    }
    _pushBounded(_undoStack, _snapshot(state));
    _redoStack.clear();
    state = _withHistoryFlags(next);
  }

  void _finishActiveTransaction() {
    if (_transactionStart != null) {
      endHistoryTransaction();
    }
  }

  CameraLabState _withHistoryFlags(CameraLabState value) => value.copyWith(
    canUndo: _undoStack.isNotEmpty,
    canRedo: _redoStack.isNotEmpty,
  );

  CameraLabState _snapshot(CameraLabState value) =>
      value.copyWith(canUndo: false, canRedo: false);

  void _pushBounded(List<CameraLabState> stack, CameraLabState value) {
    stack.add(value);
    if (stack.length > maxHistoryEntries) {
      stack.removeAt(0);
    }
  }

  bool _sameContent(CameraLabState first, CameraLabState second) {
    final firstTuning = first.tuning;
    final secondTuning = second.tuning;
    return first.selectedPack == second.selectedPack &&
        first.selectedRecipeId == second.selectedRecipeId &&
        first.intensity == second.intensity &&
        first.seed == second.seed &&
        firstTuning.exposure == secondTuning.exposure &&
        firstTuning.contrast == secondTuning.contrast &&
        firstTuning.saturation == secondTuning.saturation &&
        firstTuning.warmth == secondTuning.warmth &&
        firstTuning.grain == secondTuning.grain &&
        firstTuning.vignette == secondTuning.vignette &&
        firstTuning.bloom == secondTuning.bloom &&
        firstTuning.flash == secondTuning.flash &&
        setEquals(first.protectedRegions, second.protectedRegions) &&
        identical(first.image, second.image);
  }
}

final cameraLabProvider = NotifierProvider<CameraLabController, CameraLabState>(
  CameraLabController.new,
);
