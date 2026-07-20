import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/unflatten_theme.dart';
import '../../application/camera_lab_controller.dart';
import '../../domain/camera_recipe.dart';
import 'camera_lab_brand.dart';
import 'camera_preview.dart';

/// 横向滑动的 Recipe 卡片集合。
class CameraLabRecipeStrip extends ConsumerWidget {
  const CameraLabRecipeStrip({
    super.key,
    required this.recipes,
    required this.selectedId,
    required this.imageBytes,
    this.compact = false,
  });

  final List<CameraRecipe> recipes;
  final String selectedId;
  final Uint8List? imageBytes;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : UnflattenTokens.pageHorizontal,
        vertical: compact ? 8 : 14,
      ),
      scrollDirection: Axis.horizontal,
      itemCount: recipes.length,
      separatorBuilder: (_, _) => SizedBox(width: compact ? 10 : 14),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _RecipeCard(
          recipe: recipe,
          selected: recipe.id == selectedId,
          imageBytes: imageBytes,
          compact: compact,
        );
      },
    );
  }
}

class _RecipeCard extends ConsumerStatefulWidget {
  const _RecipeCard({
    required this.recipe,
    required this.selected,
    required this.imageBytes,
    required this.compact,
  });

  final CameraRecipe recipe;
  final bool selected;
  final Uint8List? imageBytes;
  final bool compact;

  @override
  ConsumerState<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends ConsumerState<_RecipeCard> {
  bool _hover = false;

  void _onTap() {
    HapticFeedback.selectionClick();
    ref.read(cameraLabProvider.notifier).selectRecipe(widget.recipe);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 168.0 : 220.0;
    final accent = packAccentColor(widget.recipe.pack);
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover && !selected ? 1.02 : 1.0,
        duration: UnflattenMotion.fast,
        child: AnimatedContainer(
          duration: UnflattenMotion.normal,
          curve: Curves.easeOutCubic,
          width: width,
          decoration: BoxDecoration(
            color: UnflattenColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : UnflattenColors.hairline,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? UnflattenEffects.recipeShadowSelected
                : (_hover
                    ? UnflattenEffects.recipeShadow
                    : const <BoxShadow>[]),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CameraPreview(
                        recipe: widget.recipe,
                        tuning: CameraTuning.fromRecipe(widget.recipe),
                        intensity: 0.88,
                        seed: widget.recipe.seed,
                        imageBytes: widget.imageBytes,
                        borderRadius: 12,
                        showOverlay: false,
                        liteMode: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.recipe.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: widget.compact ? 12 : 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: selected
                                      ? UnflattenColors.fg
                                      : UnflattenColors.fg,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.recipe.pack.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '#${widget.recipe.seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            color: selected
                                ? UnflattenColors.acid
                                : UnflattenColors.fgSubtle,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
