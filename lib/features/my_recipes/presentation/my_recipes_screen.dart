import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/unflatten_theme.dart';
import '../../camera_lab/application/my_recipes_provider.dart';
import '../../camera_lab/data/custom_recipes_storage.dart';
import '../../camera_lab/presentation/widgets/camera_lab_brand.dart';

const _repoUrl = 'https://github.com/hhdhh/unflatten';

/// My Recipes —— 用户自己调出来的胶片配方
class MyRecipesScreen extends ConsumerWidget {
  const MyRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(myRecipesProvider);
    return Scaffold(
      backgroundColor: UnflattenColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _TopNav(
              onCameraLab: () => context.go('/camera-lab'),
              onMixLab: () => context.go('/mix-lab'),
              onHome: () => context.go('/'),
            ),
            Expanded(
              child: recipes.isEmpty
                  ? const _EmptyState()
                  : LayoutBuilder(builder: (context, c) {
                      final columns = switch (c.maxWidth) {
                        >= 1280 => 4,
                        >= 960 => 3,
                        >= 640 => 2,
                        _ => 1,
                      };
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 64),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '我的配方',
                              style: const TextStyle(
                                color: UnflattenColors.fg,
                                fontFamily: 'Source Serif Pro',
                                fontFamilyFallback: <String>[
                                  'Times New Roman',
                                  'serif'
                                ],
                                fontSize: 48,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -1.5,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${recipes.length} 个由你亲手 5 维调音合成的胶片配方',
                              style: TextStyle(
                                color: UnflattenColors.fgMuted
                                    .withValues(alpha: 0.85),
                                fontSize: 14,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 32),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recipes.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.78,
                              ),
                              itemBuilder: (context, i) {
                                return _RecipeCard(recipe: recipes[i]);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.onCameraLab,
    required this.onMixLab,
    required this.onHome,
  });

  final VoidCallback onCameraLab;
  final VoidCallback onMixLab;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const CameraLabBrandMark(),
          const SizedBox(width: 16),
          _NavPill(label: '主页', onTap: onHome),
          const SizedBox(width: 8),
          _NavPill(label: 'Camera Lab', onTap: onCameraLab),
          const SizedBox(width: 8),
          _NavPill(label: 'Mix Lab', onTap: onMixLab, accent: true),
          const Spacer(),
          _NavPill(label: 'GitHub', icon: Icons.link_rounded, onTap: () {
            Clipboard.setData(const ClipboardData(text: _repoUrl));
          }),
        ],
      ),
    );
  }
}

class _NavPill extends StatefulWidget {
  const _NavPill({
    required this.label,
    required this.onTap,
    this.icon,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool accent;

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: UnflattenMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.accent
                ? UnflattenTokens.accentDim
                : (_hover ? UnflattenTokens.surfaceElevated : Colors.transparent),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.accent
                  ? UnflattenTokens.acid
                  : (_hover
                      ? UnflattenTokens.accentLine
                      : UnflattenTokens.hairline),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 13, color: UnflattenColors.fg),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.accent ? UnflattenTokens.acid : UnflattenColors.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: UnflattenTokens.accentDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: UnflattenTokens.accentLine),
              ),
              child: Icon(
                Icons.bookmarks_rounded,
                size: 36,
                color: UnflattenTokens.acid,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '还没有配方',
              style: TextStyle(
                color: UnflattenColors.fg,
                fontFamily: 'Source Serif Pro',
                fontFamilyFallback: <String>['Times New Roman', 'serif'],
                fontSize: 36,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 400,
              child: Text(
                '打开 Mix Lab，拖 5 个 slider 调出你自己的胶片指纹，把第一个配方存下来。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: UnflattenColors.fgMuted.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => context.go('/mix-lab'),
              style: OutlinedButton.styleFrom(
                foregroundColor: UnflattenTokens.acid,
                side: const BorderSide(color: UnflattenTokens.acid),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('前往 Mix Lab'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  const _RecipeCard({required this.recipe});

  final CustomRecipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff08080a),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: UnflattenTokens.hairlineStrong),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.92,
                        child: CustomPaint(
                          painter: _RecipeTileBg(seed: recipe.id.hashCode),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _TileBadge(
                        text: recipe.packName.toUpperCase(),
                        accent: true,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _TileBadge(
                        text: '#${recipe.seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: UnflattenTokens.surface.withValues(alpha: 0.66),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: UnflattenTokens.hairline),
                        ),
                        child: Text(
                          recipe.createdAt
                              .toIso8601String()
                              .substring(0, 10),
                          style: TextStyle(
                            color: UnflattenColors.fgMuted.withValues(alpha: 0.85),
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: UnflattenTokens.surface,
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: UnflattenColors.fg,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(recipe.dna[0] * 100).round()}% 饱 · ${(recipe.dna[1] * 100).round()}% 颗 · ${(recipe.dna[2] * 100).round()}% 暗',
                            style: TextStyle(
                              color: UnflattenColors.fgMuted.withValues(alpha: 0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: UnflattenColors.fgMuted.withValues(alpha: 0.8),
                      ),
                      color: UnflattenTokens.canvas,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: UnflattenTokens.hairline),
                      ),
                      onSelected: (v) async {
                        if (v == 'delete') {
                          await ref
                              .read(myRecipesProvider.notifier)
                              .remove(recipe.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已删除「${recipe.name}」'),
                              ),
                            );
                          }
                        } else if (v == 'copy') {
                          await Clipboard.setData(
                            ClipboardData(
                              text: 'unflatten://recipe/${recipe.id}',
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('配方 ID 已复制')),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'copy',
                          child: Text('复制 ID',
                              style: TextStyle(color: UnflattenColors.fg)),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('删除',
                              style: TextStyle(color: UnflattenColors.danger)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _TileBadge extends StatelessWidget {
  const _TileBadge({required this.text, this.accent = false});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent
            ? UnflattenTokens.accentDim
            : UnflattenTokens.surface.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accent
              ? UnflattenTokens.accentLine
              : UnflattenTokens.hairline,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent ? UnflattenTokens.acid : UnflattenColors.fg,
          fontFamily: 'JetBrains Mono',
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _RecipeTileBg extends CustomPainter {
  _RecipeTileBg({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xff161618),
            Color(0xff0a0a0c),
            Color(0xff0e0c14),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, -0.2),
          radius: 0.85,
          colors: [
            Color(0x552cc69d),
            Color(0x002cc69d),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RecipeTileBg old) => old.seed != seed;
}
