import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 统一的胶囊按钮。
///
/// 用于风格选择、类别筛选和人物热点。相比 Material Chip，它提供稳定的
/// 内边距与点击区域，避免小字号中文标签在窄屏 / Web 字体回退时被裁切。
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.dense = false,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final bool dense;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? AppColors.primaryActive : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 9 : 14,
              vertical: dense ? 6 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  IconTheme(
                    data: IconThemeData(
                      size: dense ? 13 : 15,
                      color: selected ? AppColors.primary : foreground,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: dense ? 11 : 13,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
