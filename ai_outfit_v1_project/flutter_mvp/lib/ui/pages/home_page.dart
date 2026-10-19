import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../data/demo_recommendation_engine.dart';
import '../../domain/current_outfit_controller.dart';
import '../../domain/garment.dart';
import '../../domain/outfit_recommendation.dart';
import '../../theme/app_theme.dart';
import '../avatar_canvas.dart';
import '../pages/import_method_page.dart';
import '../widgets/app_pill.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/garment_visual.dart';
import '../widgets/wardrobe_picker_sheet.dart';

/// UI-03 首页 / 2D 换装工作台。
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.appState,
    required this.onOpenSaved,
  });

  final AppState appState;
  final VoidCallback onOpenSaved;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _engine = DemoRecommendationEngine();

  List<OutfitRecommendation> _recommendations = const <OutfitRecommendation>[];
  int _recommendationIndex = 0;

  CurrentOutfitController get _outfit => widget.appState.outfit;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }

  void _resetRecommendations() {
    if (_recommendations.isEmpty) return;
    setState(() {
      _recommendations = const <OutfitRecommendation>[];
      _recommendationIndex = 0;
    });
  }

  Future<void> _pick(GarmentSlot slot) async {
    final outfit = _outfit.state;
    final candidates = widget.appState.wardrobe.bySlot(slot);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => WardrobePickerSheet(
        slot: slot,
        garments: candidates,
        selectedId: outfit[slot],
        locked: outfit.isLocked(slot),
        onSelect: (garment) {
          Navigator.pop(sheetContext);
          _select(slot, garment.id);
        },
        onRemove: outfit[slot] == null
            ? null
            : () {
                Navigator.pop(sheetContext);
                _clear(slot);
              },
        onAddNew: () {
          Navigator.pop(sheetContext);
          _importGarment(slot);
        },
      ),
    );
  }

  Future<void> _select(GarmentSlot slot, String garmentId) async {
    try {
      _outfit.selectGarment(slot, garmentId);
      _resetRecommendations();
    } on OutfitRuleException catch (error) {
      final confirmed = await confirmAction(
        context,
        title: '需要确认',
        message: error.message,
        confirmLabel: '确认替换',
      );
      if (!confirmed || !mounted) return;
      try {
        _outfit.selectGarment(
          slot,
          garmentId,
          replaceLocked: true,
          clearConflictingLocks: true,
        );
        _resetRecommendations();
      } on OutfitRuleException catch (retryError) {
        _message(retryError.message);
      }
    }
  }

  Future<void> _clear(GarmentSlot slot) async {
    try {
      _outfit.clearSlot(slot);
      _resetRecommendations();
    } on OutfitRuleException catch (error) {
      final confirmed = await confirmAction(
        context,
        title: '需要确认',
        message: error.message,
        confirmLabel: '仍然移除',
      );
      if (!confirmed || !mounted) return;
      _outfit.clearSlot(slot, force: true);
      _resetRecommendations();
    }
  }

  void _toggleLock(GarmentSlot slot) {
    try {
      _outfit.toggleLock(slot);
    } on OutfitRuleException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _importGarment(GarmentSlot slot) async {
    final garment = await Navigator.of(context).push<Garment>(
      MaterialPageRoute<Garment>(
        builder: (_) => ImportMethodPage(
          appState: widget.appState,
          initialSlot: slot,
        ),
      ),
    );
    if (garment != null && mounted) {
      await _select(slot, garment.id);
    }
  }

  void _recommend() {
    final results = _engine.generate(
      current: _outfit.state,
      closet: widget.appState.wardrobe.garments,
    );
    if (results.isEmpty) {
      _message('衣柜里还没有可用于搭配的单品，先去衣橱添加吧。');
      return;
    }
    try {
      _outfit.applyRecommendation(results.first);
      setState(() {
        _recommendations = results;
        _recommendationIndex = 0;
      });
      final first = results.first;
      _message(
        first.missingSlots.isEmpty
            ? '已生成 ${results.length} 套演示搭配'
            : '衣柜单品不足，已展示可用部分',
      );
    } on OutfitRuleException catch (error) {
      _message(error.message);
    }
  }

  void _nextRecommendation() {
    if (_recommendations.length < 2) {
      _message('当前没有其他推荐方案');
      return;
    }
    final next = (_recommendationIndex + 1) % _recommendations.length;
    try {
      _outfit.applyRecommendation(_recommendations[next]);
      setState(() => _recommendationIndex = next);
    } on OutfitRuleException catch (error) {
      _message(error.message);
    }
  }

  void _save() {
    if (!_outfit.state.isComplete) {
      _message('请先选齐上衣、下装和鞋子，或连衣裙与鞋子');
      return;
    }
    final result = widget.appState.saveCurrentOutfit();
    _message(result.created ? '已收藏这套穿搭' : '这套搭配已经收藏过了');
  }

  Future<void> _clearAll() async {
    if (_outfit.state.isEmpty) return;
    final confirmed = await confirmAction(
      context,
      title: '清空当前穿搭？',
      message: '会移除当前人物上的所有单品和锁定状态，收藏不受影响。',
      confirmLabel: '清空',
    );
    if (!confirmed || !mounted) return;
    _outfit.clearAll();
    _resetRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = widget.appState.wardrobe;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI 智能衣橱',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('saved-open'),
            onPressed: widget.onOpenSaved,
            tooltip: '我的穿搭',
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _outfit,
        builder: (context, _) {
          final outfit = _outfit.state;
          return ListView(
            key: const Key('home-scroll'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              2,
              AppSpacing.page,
              32,
            ),
            children: <Widget>[
              Text(
                '今天，穿点不一样的。',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                '点击人物旁的服装位置，从你自己的衣橱里挑选单品。',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              AvatarCanvas(
                key: const Key('avatar-canvas'),
                outfit: outfit,
                closet: wardrobe.asMap,
                onSlotTap: _pick,
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: '想要什么风格？', trailing: outfit.styleId),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final entry in styleNames.entries) ...<Widget>[
                      AppPill(
                        key: Key('style-${entry.key}'),
                        label: entry.value,
                        selected: outfit.styleId == entry.key,
                        onTap: () {
                          _outfit.setStyle(entry.key);
                          _resetRecommendations();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  const Expanded(child: _SectionTitle(title: '当前穿搭')),
                  TextButton(
                    key: const Key('clear-all'),
                    onPressed: outfit.isEmpty ? null : _clearAll,
                    child: const Text('清空'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final slot in GarmentSlot.values)
                _SlotRow(
                  slot: slot,
                  garment: _outfit.selected(slot),
                  locked: outfit.isLocked(slot),
                  onTap: () => _pick(slot),
                  onToggleLock: () => _toggleLock(slot),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('recommend-button'),
                onPressed: _recommend,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('一键智能搭配（演示规则）'),
              ),
              if (_recommendations.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _RecommendationCard(
                  recommendation: _recommendations[_recommendationIndex],
                  index: _recommendationIndex,
                  total: _recommendations.length,
                  wardrobe: wardrobe.asMap,
                  onNext: _nextRecommendation,
                  onSave: _save,
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('save-button'),
                onPressed: _save,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.favorite_outline),
                label: const Text('保存当前穿搭'),
              ),
              const SizedBox(height: 16),
              const Text(
                '2D 穿搭示意，不代表真实试穿效果。衣服与推荐为本地演示数据；衣橱与收藏保存在本机。',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final trailingStyle = trailing;
    return Row(
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (trailingStyle != null) ...<Widget>[
          const SizedBox(width: 6),
          Text(
            styleNames[trailingStyle] ?? trailingStyle,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.garment,
    required this.locked,
    required this.onTap,
    required this.onToggleLock,
  });

  final GarmentSlot slot;
  final Garment? garment;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('slot-row-${slot.name}'),
      margin: const EdgeInsets.only(bottom: 7),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: GarmentSwatch(garment: garment, width: 34, height: 46),
        title: Text(
          garment?.name ?? '添加${slot.label}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          garment == null
              ? '${slot.label} · 尚未选择'
              : '${slot.label} · ${garment!.subcategory}'
                  '${garment!.isDemo ? ' · 演示' : ''}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          key: Key('lock-${slot.name}'),
          tooltip: locked ? '解锁${slot.label}' : '锁定${slot.label}',
          onPressed: garment == null ? null : onToggleLock,
          icon: Icon(
            locked ? Icons.lock : Icons.lock_open,
            size: 19,
            color: locked ? AppColors.primary : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.index,
    required this.total,
    required this.wardrobe,
    required this.onNext,
    required this.onSave,
  });

  final OutfitRecommendation recommendation;
  final int index;
  final int total;
  final Map<String, Garment> wardrobe;
  final VoidCallback onNext;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final pieces = <Garment>[
      for (final slot in GarmentSlot.values)
        if (recommendation.garmentIds[slot] != null &&
            wardrobe[recommendation.garmentIds[slot]] != null)
          wardrobe[recommendation.garmentIds[slot]]!,
    ];
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome,
                    size: 17, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  '为你推荐',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '方案 ${index + 1} / $total',
                  key: const Key('recommendation-counter'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final garment in pieces)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GarmentSwatch(
                        garment: garment,
                        width: 26,
                        height: 34,
                        borderRadius: 7,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        garment.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              recommendation.reason,
              key: const Key('recommendation-reason'),
              style: const TextStyle(
                fontSize: 12,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
            if (recommendation.missingSlots.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '衣柜暂缺：'
                        '${recommendation.missingSlots.map((slot) => slot.label).join('、')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                OutlinedButton(
                  key: const Key('next-recommendation'),
                  onPressed: total > 1 ? onNext : null,
                  child: const Text('换一套'),
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('save-recommendation'),
                  onPressed: onSave,
                  child: const Text('保存这套'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
