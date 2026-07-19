import 'dart:math' as math;

import 'package:unflatten_studio/features/camera_lab/domain/camera_recipe.dart';

class CameraEffectMath {
  const CameraEffectMath._();

  static List<double> colorMatrix(
    CameraRecipe recipe,
    CameraTuning tuning,
    double intensity,
  ) {
    var matrix = _identity5;
    final exposureScale = math.pow(2, tuning.exposure * 0.55).toDouble();
    matrix = _multiply(_exposure(exposureScale), matrix);
    matrix = _multiply(_contrast(1 + tuning.contrast * 0.72), matrix);
    matrix = _multiply(_saturation(1 + tuning.saturation * 0.86), matrix);
    matrix = _multiply(_warmth(tuning.warmth), matrix);
    matrix = _multiply(
      _tint(recipe.medium.shadowTint, recipe.medium.highlightTint),
      matrix,
    );
    return _interpolate(_toFlutterMatrix(matrix), _identity4x5, intensity);
  }

  static const _identity4x5 = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const _identity5 = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
  ];

  static List<double> _exposure(double scale) => [
    scale,
    0,
    0,
    0,
    0,
    0,
    scale,
    0,
    0,
    0,
    0,
    0,
    scale,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
  ];

  static List<double> _contrast(double value) {
    final offset = 128 * (1 - value);
    return [
      value,
      0,
      0,
      0,
      offset,
      0,
      value,
      0,
      0,
      offset,
      0,
      0,
      value,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
    ];
  }

  static List<double> _saturation(double value) {
    const red = 0.2126;
    const green = 0.7152;
    const blue = 0.0722;
    final inverse = 1 - value;
    return [
      inverse * red + value,
      inverse * green,
      inverse * blue,
      0,
      0,
      inverse * red,
      inverse * green + value,
      inverse * blue,
      0,
      0,
      inverse * red,
      inverse * green,
      inverse * blue + value,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
    ];
  }

  static List<double> _warmth(double value) {
    final red = 1 + value * 0.18;
    final green = 1 + value.abs() * 0.015;
    final blue = 1 - value * 0.2;
    return [
      red,
      0,
      0,
      0,
      value * 5,
      0,
      green,
      0,
      0,
      0,
      0,
      0,
      blue,
      0,
      -value * 5,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
    ];
  }

  static List<double> _tint(ColorVector shadows, ColorVector highlights) {
    final red = shadows.red * 6 + highlights.red * 4;
    final green = shadows.green * 6 + highlights.green * 4;
    final blue = shadows.blue * 6 + highlights.blue * 4;
    return [
      1,
      0,
      0,
      0,
      red,
      0,
      1,
      0,
      0,
      green,
      0,
      0,
      1,
      0,
      blue,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
    ];
  }

  static List<double> _multiply(List<double> left, List<double> right) {
    final result = List<double>.filled(25, 0);
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 5; column++) {
        var value = 0.0;
        for (var index = 0; index < 5; index++) {
          value += left[row * 5 + index] * right[index * 5 + column];
        }
        result[row * 5 + column] = value;
      }
    }
    return result;
  }

  static List<double> _toFlutterMatrix(List<double> matrix) => [
    ...matrix.sublist(0, 5),
    ...matrix.sublist(5, 10),
    ...matrix.sublist(10, 15),
    ...matrix.sublist(15, 20),
  ];

  static List<double> _interpolate(
    List<double> target,
    List<double> origin,
    double amount,
  ) => List.generate(
    target.length,
    (index) => origin[index] + (target[index] - origin[index]) * amount,
  );
}
