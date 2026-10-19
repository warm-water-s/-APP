import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../domain/garment.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_pill.dart';
import '../widgets/garment_visual.dart';
import 'garment_detail_page.dart';
import 'import_method_page.dart';

/// UI-06 衣橱列表。
class WardrobePage extends StatefulWidget {
  const WardrobePage({
    super.key,
    required this.appState,
    required this.onOpenHome,
  });

  final AppState appState;
  final VoidCallback onOpenHome;

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final TextEditingController _searchController = TextEditingController();
  GarmentSlot? _slot;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push<Garment>(
      MaterialPageRoute<Garment>(
        builder: (_) => ImportMethodPage(appState: widget.appState),
      ),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存「${result.name}」到衣橱')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState.wardrobe,
      builder: (context, _) {
        final all = widget.appState.wardrobe.garments;
        final filtered =
            widget.appState.wardrobe.search(slot: _slot, query: _query);
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '我的衣橱',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${all.length} 件',
                    key: const Key('wardrobe-count'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('wardrobe-add'),
            onPressed: _add,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('添加衣服'),
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  2,
                  AppSpacing.page,
                  8,
                ),
                child: TextField(
                  key: const Key('wardrobe-search'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: '搜索名称或子类别',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  children: <Widget>[
                    _FilterChip(
                      key: const Key('wardrobe-filter-all'),
                      label: '全部',
                      selected: _slot == null,
                      onTap: () => setState(() => _slot = null),
                    ),
                    for (final slot in GarmentSlot.values)
                      _FilterChip(
                        key: Key('wardrobe-filter-${slot.name}'),
                        label: slot.label,
                        selected: _slot == slot,
                        onTap: () => setState(() => _slot = slot),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyWardrobe(
                        hasAny: all.isNotEmpty,
                        slot: _slot,
                        onAdd: _add,
                        onReset: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _slot = null;
                          });
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          8,
                          AppSpacing.page,
                          110,
                        ),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final garment = filtered[index];
                          return _GarmentCard(
                            garment: garment,
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => GarmentDetailPage(
                                    appState: widget.appState,
                                    garmentId: garment.id,
                                    onOpenHome: widget.onOpenHome,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 2, bottom: 6),
      child: AppPill(
        label: label,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard({required this.garment, required this.onTap});

  final Garment garment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        key: Key('wardrobe-item-${garment.id}'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: GarmentSwatch(
                  garment: garment,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                garment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${garment.slot.label} · ${garment.subcategory}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWardrobe extends StatelessWidget {
  const _EmptyWardrobe({
    required this.hasAny,
    required this.slot,
    required this.onAdd,
    required this.onReset,
  });

  final bool hasAny;
  final GarmentSlot? slot;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.checkroom,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              hasAny ? (slot == null ? '没有匹配的服装' : '这个类别还没有衣服') : '衣橱还是空的',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasAny ? '试试其他关键词或类别。' : '先添加一件你真实拥有的衣服，推荐只使用你的衣橱。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (hasAny)
              OutlinedButton(onPressed: onReset, child: const Text('清除筛选'))
            else
              FilledButton.icon(
                key: const Key('empty-add'),
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('添加第一件衣服'),
              ),
          ],
        ),
      ),
    );
  }
}
