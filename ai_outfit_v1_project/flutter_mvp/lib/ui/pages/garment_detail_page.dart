import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../domain/current_outfit_controller.dart';
import '../../domain/garment.dart';
import '../../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/garment_visual.dart';
import 'garment_editor_page.dart';

/// UI-11 服装详情。
class GarmentDetailPage extends StatelessWidget {
  const GarmentDetailPage({
    super.key,
    required this.appState,
    required this.garmentId,
    required this.onOpenHome,
  });

  final AppState appState;
  final String garmentId;
  final VoidCallback onOpenHome;

  Future<void> _edit(BuildContext context, Garment garment) async {
    await Navigator.of(context).push<Garment>(
      MaterialPageRoute<Garment>(
        builder: (_) => GarmentEditorPage(
          appState: appState,
          initial: garment,
        ),
      ),
    );
  }

  Future<void> _wear(BuildContext context, Garment garment) async {
    try {
      appState.outfit.selectGarment(garment.slot, garment.id);
    } on OutfitRuleException catch (error) {
      final confirmed = await confirmAction(
        context,
        title: '需要确认',
        message: error.message,
        confirmLabel: '确认替换',
      );
      if (!confirmed || !context.mounted) return;
      try {
        appState.outfit.selectGarment(
          garment.slot,
          garment.id,
          replaceLocked: true,
          clearConflictingLocks: true,
        );
      } on OutfitRuleException catch (retryError) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(retryError.message)),
        );
        return;
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    onOpenHome();
  }

  Future<void> _delete(BuildContext context, Garment garment) async {
    final confirmed = await confirmAction(
      context,
      title: '删除这件衣服？',
      message: '删除后，引用它的收藏会显示缺失单品；历史记录不会被篡改。',
      confirmLabel: '删除',
    );
    if (!confirmed || !context.mounted) return;
    appState.wardrobe.remove(garment.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState.wardrobe,
      builder: (context, _) {
        final garment = appState.wardrobe.find(garmentId);
        if (garment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('服装详情')),
            body: const _MissingGarment(),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('服装详情'),
            actions: <Widget>[
              IconButton(
                key: const Key('garment-edit'),
                tooltip: '编辑',
                onPressed: () => _edit(context, garment),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: const Key('garment-delete'),
                tooltip: '删除',
                onPressed: () => _delete(context, garment),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              8,
              AppSpacing.page,
              32,
            ),
            children: <Widget>[
              Center(
                child: GarmentSwatch(
                  garment: garment,
                  width: 150,
                  height: 196,
                  borderRadius: 18,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                garment.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _Tag(garment.slot.label),
                  _Tag(garment.subcategory),
                  _Tag(garment.sourceType.label),
                  if (garment.isDemo)
                    const _Tag('演示数据', color: AppColors.warning),
                ],
              ),
              const SizedBox(height: 20),
              _InfoCard(
                rows: <(String, String)>[
                  ('颜色', garment.colorHex.toUpperCase()),
                  ('风格', _styleLabel(garment.styleIds)),
                  ('季节', _seasonLabel(garment.seasons)),
                  if (garment.fit != null) ('版型', garment.fit!),
                  if (garment.pattern != null) ('图案', garment.pattern!),
                  if (garment.sourceUrl != null) ('来源链接', garment.sourceUrl!),
                ],
              ),
              if (garment.note != null && garment.note!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _InfoCard(rows: <(String, String)>[('备注', garment.note!)]),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('garment-wear'),
                onPressed: () => _wear(context, garment),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.checkroom),
                label: Text('穿上它去搭配（${garment.slot.label}）'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('garment-edit-secondary'),
                onPressed: () => _edit(context, garment),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑信息'),
              ),
              const SizedBox(height: 14),
              const Text(
                '人物只展示类别、主色与近似轮廓，真实商品图不会自动贴到人物身上。',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _styleLabel(Set<String> styles) {
  if (styles.isEmpty) return '未标注';
  return styles.map((id) => styleNames[id] ?? id).join('、');
}

String _seasonLabel(Set<String> seasons) {
  if (seasons.isEmpty) return '未标注';
  return seasons.map((id) => seasonNames[id] ?? id).join('、');
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          for (var index = 0; index < rows.length; index++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 62,
                    child: Text(
                      rows[index].$1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[index].$2,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            if (index != rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color ?? AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MissingGarment extends StatelessWidget {
  const _MissingGarment();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.inventory_2_outlined,
              size: 46, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('这件服装已被删除'),
          SizedBox(height: 4),
          Text(
            '收藏中的对应位置会显示为缺失，不会自动替换。',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
