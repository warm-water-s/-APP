import 'package:flutter/material.dart';

import '../../domain/garment.dart';
import '../../theme/app_theme.dart';
import 'garment_visual.dart';

/// UI-04 服装选择 BottomSheet。只负责展示和回调，不直接修改业务状态。
class WardrobePickerSheet extends StatelessWidget {
  const WardrobePickerSheet({
    super.key,
    required this.slot,
    required this.garments,
    required this.selectedId,
    required this.onSelect,
    required this.onRemove,
    required this.onAddNew,
    this.locked = false,
  });

  final GarmentSlot slot;
  final List<Garment> garments;
  final String? selectedId;
  final ValueChanged<Garment> onSelect;
  final VoidCallback? onRemove;
  final VoidCallback onAddNew;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  4,
                  AppSpacing.page,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '选择${slot.label}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${garments.length} 件',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  6,
                  AppSpacing.page,
                  10,
                ),
                child: Text(
                  locked
                      ? '当前${slot.label}已锁定；替换前会再次确认。'
                      : '只显示你衣橱里的${slot.label}。',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: garments.isEmpty
                    ? _EmptyCategory(slot: slot, onAddNew: onAddNew)
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.page,
                        ),
                        itemCount: garments.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.55,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final garment = garments[index];
                          final selected = garment.id == selectedId;
                          return _GarmentTile(
                            garment: garment,
                            selected: selected,
                            onTap: () => onSelect(garment),
                          );
                        },
                      ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  8,
                  AppSpacing.page,
                  12,
                ),
                child: Row(
                  children: <Widget>[
                    if (selectedId != null)
                      TextButton.icon(
                        key: const Key('picker-remove'),
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 18,
                        ),
                        label: Text('移除${slot.label}'),
                      ),
                    const Spacer(),
                    OutlinedButton.icon(
                      key: const Key('picker-add-new'),
                      onPressed: onAddNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加新衣服'),
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

class _GarmentTile extends StatelessWidget {
  const _GarmentTile({
    required this.garment,
    required this.selected,
    required this.onTap,
  });

  final Garment garment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        key: Key('picker-${garment.id}'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              GarmentSwatch(
                garment: garment,
                width: 40,
                height: 54,
                borderRadius: 9,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      garment.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      garment.subcategory,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle,
                    size: 17, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.slot, required this.onAddNew});

  final GarmentSlot slot;
  final VoidCallback onAddNew;

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
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text('衣橱里还没有${slot.label}'),
            const SizedBox(height: 4),
            const Text(
              '先添加一件，才能参与搭配。',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.add),
              label: Text('添加${slot.label}'),
            ),
          ],
        ),
      ),
    );
  }
}
