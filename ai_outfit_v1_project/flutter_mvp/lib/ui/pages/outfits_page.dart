import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../domain/garment.dart';
import '../../domain/saved_outfit.dart';
import '../../theme/app_theme.dart';
import '../avatar_canvas.dart';
import '../widgets/formatters.dart';
import 'outfit_detail_page.dart';

/// UI-12 我的穿搭列表。
class OutfitsPage extends StatelessWidget {
  const OutfitsPage({
    super.key,
    required this.appState,
    required this.onOpenHome,
  });

  final AppState appState;
  final VoidCallback onOpenHome;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        appState.savedOutfits,
        appState.wardrobe,
      ]),
      builder: (context, _) {
        final items = appState.savedOutfits.items;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '我的穿搭',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${items.length} 套',
                    key: const Key('saved-count'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: items.isEmpty
              ? _EmptySaved(onOpenHome: onOpenHome)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    4,
                    AppSpacing.page,
                    32,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final saved = items[index];
                    return _SavedCard(
                      saved: saved,
                      closet: appState.wardrobe.asMap,
                      missing: saved.missingSlots(appState.wardrobe.asMap),
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => OutfitDetailPage(
                              appState: appState,
                              savedId: saved.id,
                              onOpenHome: onOpenHome,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.saved,
    required this.closet,
    required this.missing,
    required this.onTap,
  });

  final SavedOutfit saved;
  final Map<String, Garment> closet;
  final List<GarmentSlot> missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        key: Key('saved-item-${saved.id}'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 76,
                height: 92,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AvatarCanvas(
                    outfit: saved.toOutfit(),
                    closet: closet,
                    onSlotTap: (_) {},
                    showHotspots: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            saved.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${styleNames[saved.styleId] ?? saved.styleId}'
                      ' · ${formatSavedTime(saved.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${saved.itemCount} 件单品',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (missing.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.report_gmailerrorred,
                            size: 13,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '缺失：${missing.map((slot) => slot.label).join('、')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _EmptySaved extends StatelessWidget {
  const _EmptySaved({required this.onOpenHome});

  final VoidCallback onOpenHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.favorite_border,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              '还没有收藏的穿搭',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '在首页完成一套搭配后点击保存，就能在这里一键恢复。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('saved-empty-home'),
              onPressed: onOpenHome,
              child: const Text('去首页搭配'),
            ),
          ],
        ),
      ),
    );
  }
}
