import 'dart:math' as math;

enum CameraPack {
  analog('Analog', '胶片与冲洗', 'analog'),
  y2kDigicam('Y2K', '千禧数码', 'y2k-digicam'),
  optical('Optical', '光学实验', 'optical'),
  mobileEras('Mobile', '手机年代', 'mobile-eras');

  const CameraPack(this.label, this.description, this.serialName);

  final String label;
  final String description;
  final String serialName;
}

enum SemanticRegion {
  person('人物', 'person'),
  skin('肤色', 'skin'),
  sky('天空', 'sky'),
  text('文字', 'text'),
  logo('品牌色', 'logo'),
  product('产品', 'product'),
  background('背景', 'background');

  const SemanticRegion(this.label, this.serialName);

  final String label;
  final String serialName;
}

class CameraRecipe {
  const CameraRecipe({
    required this.schema,
    required this.id,
    required this.name,
    required this.description,
    required this.pack,
    required this.seed,
    required this.tags,
    required this.body,
    required this.lens,
    required this.medium,
    required this.capture,
    required this.condition,
    required this.protect,
  });

  static const schemaV1 = 'unflatten-camera/v1';

  final String schema;
  final String id;
  final String name;
  final String description;
  final CameraPack pack;
  final int seed;
  final List<String> tags;
  final BodyProfile body;
  final LensProfile lens;
  final MediumProfile medium;
  final CaptureProfile capture;
  final ConditionProfile condition;
  final List<SemanticRegion> protect;

  List<String> validate() {
    final errors = <String>[];
    if (schema != schemaV1) {
      errors.add('不支持的相机配方 Schema：$schema');
    }
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
      errors.add('相机配方 ID 必须使用小写字母、数字和连字符：$id');
    }
    if (name.trim().isEmpty) {
      errors.add('相机配方名称不能为空');
    }

    _checkRange(errors, 'body.dynamicRange', body.dynamicRange, 0, 1);
    _checkRange(errors, 'body.highlightRolloff', body.highlightRolloff, 0, 1);
    _checkRange(errors, 'body.baseNoise', body.baseNoise, 0, 1);
    _checkRange(errors, 'body.saturationBias', body.saturationBias, -1, 1);
    _checkRange(errors, 'lens.focalLengthMm', lens.focalLengthMm, 1, 500);
    _checkRange(errors, 'lens.distortion', lens.distortion, -1, 1);
    _checkRange(errors, 'lens.edgeSoftness', lens.edgeSoftness, 0, 1);
    _checkRange(
      errors,
      'lens.chromaticAberration',
      lens.chromaticAberration,
      0,
      1,
    );
    _checkRange(errors, 'lens.vignette', lens.vignette, 0, 1);
    _checkRange(errors, 'lens.bloom', lens.bloom, 0, 1);
    _checkRange(errors, 'lens.halation', lens.halation, 0, 1);
    _checkRange(errors, 'medium.grain', medium.grain, 0, 1);
    _checkRange(errors, 'medium.colorNoise', medium.colorNoise, 0, 1);
    _checkRange(errors, 'medium.contrast', medium.contrast, -1, 1);
    _checkRange(errors, 'medium.saturation', medium.saturation, -1, 1);
    _checkRange(errors, 'medium.warmth', medium.warmth, -1, 1);
    _checkRange(errors, 'capture.exposureBias', capture.exposureBias, -3, 3);
    _checkRange(errors, 'capture.whiteBalance', capture.whiteBalance, -1, 1);
    _checkRange(errors, 'capture.flashStrength', capture.flashStrength, 0, 1);
    _checkRange(errors, 'capture.flashFalloff', capture.flashFalloff, 0, 1);
    _checkRange(errors, 'capture.underexposure', capture.underexposure, 0, 1);
    _checkRange(errors, 'condition.dust', condition.dust, 0, 1);
    _checkRange(errors, 'condition.scratches', condition.scratches, 0, 1);
    _checkRange(errors, 'condition.lightLeak', condition.lightLeak, 0, 1);
    _checkRange(errors, 'condition.compression', condition.compression, 0, 1);
    _checkRange(errors, 'condition.wear', condition.wear, 0, 1);
    if (condition.deadPixels < 0 || condition.deadPixels > 4096) {
      errors.add('参数 condition.deadPixels 超出允许范围 0..=4096');
    }
    return errors;
  }

  Map<String, Object?> toJson() => {
    'schema': schema,
    'id': id,
    'name': name,
    'description': description,
    'pack': pack.serialName,
    'seed': seed,
    'tags': tags,
    'body': body.toJson(),
    'lens': lens.toJson(),
    'medium': medium.toJson(),
    'capture': capture.toJson(),
    'condition': condition.toJson(),
    'protect': protect.map((region) => region.serialName).toList(),
  };

  DefectSignature resolveSignature([int? overrideSeed]) {
    final random = SplitMix64((overrideSeed ?? seed) ^ stableHash(id));
    return DefectSignature(
      grainSeed: random.nextUint64(),
      dustSeed: random.nextUint64(),
      deadPixelSeed: random.nextUint64(),
      lightLeakAngle: random.nextUnitDouble() * 360,
      lightLeakOriginX: random.nextUnitDouble(),
      lightLeakOriginY: random.nextUnitDouble(),
      chromaOffsetX: random.nextSignedDouble(),
      chromaOffsetY: random.nextSignedDouble(),
    );
  }

  static void _checkRange(
    List<String> errors,
    String field,
    double value,
    double min,
    double max,
  ) {
    if (!value.isFinite || value < min || value > max) {
      errors.add('参数 $field 超出允许范围 $min..=$max，当前值为 $value');
    }
  }
}

class BodyProfile {
  const BodyProfile({
    required this.profile,
    required this.dynamicRange,
    required this.highlightRolloff,
    required this.baseNoise,
    required this.saturationBias,
  });

  final String profile;
  final double dynamicRange;
  final double highlightRolloff;
  final double baseNoise;
  final double saturationBias;

  Map<String, Object?> toJson() => {
    'profile': profile,
    'dynamicRange': dynamicRange,
    'highlightRolloff': highlightRolloff,
    'baseNoise': baseNoise,
    'saturationBias': saturationBias,
  };
}

class LensProfile {
  const LensProfile({
    required this.profile,
    required this.focalLengthMm,
    required this.distortion,
    required this.edgeSoftness,
    required this.chromaticAberration,
    required this.vignette,
    required this.bloom,
    required this.halation,
  });

  final String profile;
  final double focalLengthMm;
  final double distortion;
  final double edgeSoftness;
  final double chromaticAberration;
  final double vignette;
  final double bloom;
  final double halation;

  Map<String, Object?> toJson() => {
    'profile': profile,
    'focalLengthMm': focalLengthMm,
    'distortion': distortion,
    'edgeSoftness': edgeSoftness,
    'chromaticAberration': chromaticAberration,
    'vignette': vignette,
    'bloom': bloom,
    'halation': halation,
  };
}

class MediumProfile {
  const MediumProfile({
    required this.profile,
    required this.grain,
    required this.colorNoise,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.shadowTint,
    required this.highlightTint,
  });

  final String profile;
  final double grain;
  final double colorNoise;
  final double contrast;
  final double saturation;
  final double warmth;
  final ColorVector shadowTint;
  final ColorVector highlightTint;

  Map<String, Object?> toJson() => {
    'profile': profile,
    'grain': grain,
    'colorNoise': colorNoise,
    'contrast': contrast,
    'saturation': saturation,
    'warmth': warmth,
    'shadowTint': shadowTint.toJson(),
    'highlightTint': highlightTint.toJson(),
  };
}

class CaptureProfile {
  const CaptureProfile({
    required this.exposureBias,
    required this.whiteBalance,
    required this.flashStrength,
    required this.flashFalloff,
    required this.underexposure,
    required this.timestamp,
  });

  final double exposureBias;
  final double whiteBalance;
  final double flashStrength;
  final double flashFalloff;
  final double underexposure;
  final bool timestamp;

  Map<String, Object?> toJson() => {
    'exposureBias': exposureBias,
    'whiteBalance': whiteBalance,
    'flashStrength': flashStrength,
    'flashFalloff': flashFalloff,
    'underexposure': underexposure,
    'timestamp': timestamp,
  };
}

class ConditionProfile {
  const ConditionProfile({
    required this.dust,
    required this.scratches,
    required this.lightLeak,
    required this.deadPixels,
    required this.compression,
    required this.wear,
  });

  final double dust;
  final double scratches;
  final double lightLeak;
  final int deadPixels;
  final double compression;
  final double wear;

  Map<String, Object?> toJson() => {
    'dust': dust,
    'scratches': scratches,
    'lightLeak': lightLeak,
    'deadPixels': deadPixels,
    'compression': compression,
    'wear': wear,
  };
}

class ColorVector {
  const ColorVector(this.red, this.green, this.blue);

  static const neutral = ColorVector(0, 0, 0);

  final double red;
  final double green;
  final double blue;

  Map<String, Object?> toJson() => {'red': red, 'green': green, 'blue': blue};
}

class DefectSignature {
  const DefectSignature({
    required this.grainSeed,
    required this.dustSeed,
    required this.deadPixelSeed,
    required this.lightLeakAngle,
    required this.lightLeakOriginX,
    required this.lightLeakOriginY,
    required this.chromaOffsetX,
    required this.chromaOffsetY,
  });

  final int grainSeed;
  final int dustSeed;
  final int deadPixelSeed;
  final double lightLeakAngle;
  final double lightLeakOriginX;
  final double lightLeakOriginY;
  final double chromaOffsetX;
  final double chromaOffsetY;

  @override
  bool operator ==(Object other) =>
      other is DefectSignature &&
      other.grainSeed == grainSeed &&
      other.dustSeed == dustSeed &&
      other.deadPixelSeed == deadPixelSeed &&
      other.lightLeakAngle == lightLeakAngle &&
      other.lightLeakOriginX == lightLeakOriginX &&
      other.lightLeakOriginY == lightLeakOriginY &&
      other.chromaOffsetX == chromaOffsetX &&
      other.chromaOffsetY == chromaOffsetY;

  @override
  int get hashCode => Object.hash(
    grainSeed,
    dustSeed,
    deadPixelSeed,
    lightLeakAngle,
    lightLeakOriginX,
    lightLeakOriginY,
    chromaOffsetX,
    chromaOffsetY,
  );
}

class CameraTuning {
  const CameraTuning({
    required this.exposure,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.grain,
    required this.vignette,
    required this.bloom,
    required this.flash,
  });

  factory CameraTuning.fromRecipe(CameraRecipe recipe) => CameraTuning(
    exposure: recipe.capture.exposureBias,
    contrast: recipe.medium.contrast,
    saturation: recipe.medium.saturation + recipe.body.saturationBias,
    warmth: recipe.medium.warmth + recipe.capture.whiteBalance,
    grain: math.max(recipe.medium.grain, recipe.body.baseNoise),
    vignette: recipe.lens.vignette,
    bloom: math.max(recipe.lens.bloom, recipe.lens.halation),
    flash: recipe.capture.flashStrength,
  );

  final double exposure;
  final double contrast;
  final double saturation;
  final double warmth;
  final double grain;
  final double vignette;
  final double bloom;
  final double flash;

  CameraTuning copyWith({
    double? exposure,
    double? contrast,
    double? saturation,
    double? warmth,
    double? grain,
    double? vignette,
    double? bloom,
    double? flash,
  }) => CameraTuning(
    exposure: exposure ?? this.exposure,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    warmth: warmth ?? this.warmth,
    grain: grain ?? this.grain,
    vignette: vignette ?? this.vignette,
    bloom: bloom ?? this.bloom,
    flash: flash ?? this.flash,
  );
}

int stableHash(String value) {
  var hash = 0xcbf29ce484222325;
  for (final byte in value.codeUnits) {
    hash = ((hash ^ byte) * 0x100000001b3) & SplitMix64.mask;
  }
  return hash;
}

class SplitMix64 {
  SplitMix64(int seed) : _state = seed & mask;

  static const mask = 0xffffffffffffffff;
  var _state = 0;

  int nextUint64() {
    _state = (_state + 0x9e3779b97f4a7c15) & mask;
    var value = _state;
    value = ((value ^ (value >> 30)) * 0xbf58476d1ce4e5b9) & mask;
    value = ((value ^ (value >> 27)) * 0x94d049bb133111eb) & mask;
    return (value ^ (value >> 31)) & mask;
  }

  double nextUnitDouble() => (nextUint64() >> 40) / 16777215;

  double nextSignedDouble() => nextUnitDouble() * 2 - 1;
}
