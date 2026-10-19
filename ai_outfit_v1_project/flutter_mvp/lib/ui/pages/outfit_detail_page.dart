import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../domain/garment.dart';
import '../../domain/saved_outfit.dart';
import '../../theme/app_theme.dart';
import '../avatar_canvas.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/formatters.dart';
import '../widgets/garment_visual.dart';

/// UI-13 穿搭详情。
class OutfitDetailPage extends StatelessWidget {
  const OutfitDetailPage({
    super.key,
    required this.appState,
    required this.savedId,
    required this.onOpenHome,
  });

  final AppState appState;
  final String savedId;
  final VoidCallback onOpenHome;

  void _wear(BuildContext context) {
    final saved = appState.savedOutfits.find(savedId);
    if (saved == null) return;
    final messenger = ScaffoldMessenger.of(context);
    appState.applySaved(saved);
    Navigator.of(context).popUntil((route) => route.isFirst);
    onOpenHome();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved.missingSlots(appState.wardrobe.asMap).isEmpty
              ? '已恢复「${saved.name}」'
              : '已恢复；缺失单品保持为空位',
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, SavedOutfit saved) async {
    final confirmed = await confirmAction(
      context,
      title: '删除这套收藏？',
      message: '只删除收藏记录，不会删除衣橱里的衣服。',
      confirmLabel: '删除',
    );
    if (!confirmed || !context.mounted) return;
    appState.savedOutfits.remove(saved.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        appState.savedOutfits,
        appState.wardrobe,
      ]),
      builder: (context, _) {
        final saved = appState.savedOutfits.find(savedId);
        if (saved == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('穿搭详情')),
            body: const Center(child: Text('这套穿搭已被删除')),
          );
        }
        final closet = appState.wardrobe.asMap;
        final missing = saved.missingSlots(closet);
        return Scaffold(
          appBar: AppBar(
            title: const Text('穿搭详情'),
            actions: <Widget>[
              IconButton(
                key: const Key('saved-delete'),
                tooltip: '删除收藏',
                onPressed: () => _delete(context, saved),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              4,
              AppSpacing.page,
              32,
            ),
            children: <Widget>[
              Container(
                height: 330,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.avatarStage,
                  borderRadius: BorderRadius.circular(AppRadius.avatar),
                ),
                child: AvatarCanvas(
                  outfit: saved.toOutfit(),
                  closet: closet,
                  onSlotTap: (_) {},
                  showHotspots: false,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                saved.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${styleNames[saved.styleId] ?? saved.styleId}'
                ' · ${formatSavedTime(saved.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '套装单品',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final slot in GarmentSlot.values)
                if (saved.garmentIds[slot] != null)
                  _PieceRow(
                    slot: slot,
                    garment: closet[saved.garmentIds[slot]],
                  ),
              if (missing.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '以下单品已从衣橱删除，恢复时保持为空位：'
                    '${missing.map((slot) => slot.label).join('、')}',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('wear-saved'),
                onPressed: () => _wear(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.checkroom),
                label: const Text('穿上这套'),
              ),
              const SizedBox(height: 12),
              const Text(
                '恢复时不会沿用收藏当天的锁定状态；缺失单品不会被其他衣服替代。',
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

class _PieceRow extends StatelessWidget {
  const _PieceRow({required this.slot, required this.garment});

  final GarmentSlot slot;
  final Garment? garment;

  @override
  Widget build(BuildContext context) {
    final item = garment;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          GarmentSwatch(garment: item, width: 32, height: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item?.name ?? '${slot.label}已缺失',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item == null
                      ? '恢复后该位置保持为空'
                      : '${slot.label} · ${item.subcategory}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (item == null)
            const Icon(
              Icons.report_gmailerrorred,
              size: 17,
              color: AppColors.warning,
            ),
        ],
      ),
    );
  }
}
