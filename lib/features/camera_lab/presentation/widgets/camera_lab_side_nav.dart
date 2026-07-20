import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/unflatten_theme.dart';
import 'camera_lab_brand.dart';

/// v5: 顶部 sidebar nav —— 品牌 + "返回主页" + "我的配方" + "GitHub"
class CameraLabSideNav extends StatelessWidget {
  const CameraLabSideNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CameraLabBrandMark(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SideNavPill(
              icon: Icons.arrow_back_rounded,
              label: '主页',
              onTap: () => context.go('/'),
            ),
            _SideNavPill(
              icon: Icons.bookmarks_rounded,
              label: '收藏',
              onTap: () => _showSavedRecipesSoon(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showSavedRecipesSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('配方收藏即将上线（v5）'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _SideNavPill extends StatefulWidget {
  const _SideNavPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SideNavPill> createState() => _SideNavPillState();
}

class _SideNavPillState extends State<_SideNavPill> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hover
                ? UnflattenTokens.surfaceElevated
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hover
                  ? UnflattenTokens.accentLine
                  : UnflattenTokens.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 12, color: UnflattenColors.fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: UnflattenColors.fg,
                  fontSize: 11,
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
