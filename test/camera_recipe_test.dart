import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:unflatten_studio/features/camera_lab/data/camera_catalog.dart';
import 'package:unflatten_studio/features/camera_lab/domain/camera_recipe.dart';

void main() {
  test('首发目录包含四个风格包与 24 台虚拟相机', () {
    expect(cameraCatalog, hasLength(24));
    for (final pack in CameraPack.values) {
      expect(
        cameraCatalog.where((recipe) => recipe.pack == pack),
        hasLength(6),
      );
    }
  });

  test('所有内置配方都通过校验并拥有唯一 ID', () {
    final identifiers = <String>{};
    for (final recipe in cameraCatalog) {
      expect(recipe.validate(), isEmpty, reason: recipe.id);
      expect(identifiers.add(recipe.id), isTrue, reason: recipe.id);
    }
  });

  test('配方能够序列化为公开 JSON', () {
    final json = jsonEncode(cameraCatalog.first.toJson());
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['schema'], CameraRecipe.schemaV1);
    expect(decoded['id'], 'warm-35');
    expect(decoded['body'], isA<Map<String, dynamic>>());
    expect(decoded['protect'], contains('skin'));
  });

  test('相同配方与 Seed 产生完全一致的缺陷签名', () {
    final recipe = cameraCatalog.firstWhere(
      (candidate) => candidate.id == 'y2k-night-party',
    );
    expect(recipe.resolveSignature(), recipe.resolveSignature());
    expect(recipe.resolveSignature(2048), isNot(recipe.resolveSignature(2049)));
  });
}
