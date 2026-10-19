import 'garment.dart';
import 'outfit_state.dart';

/// 已收藏的完整穿搭快照。
///
/// 收藏只保存服装 ID 引用，不复制服装数据；衣服被删除后恢复时对应槽位保持为空。
class SavedOutfit {
  SavedOutfit({
    required this.id,
    required this.name,
    required this.styleId,
    required Map<GarmentSlot, String?> garmentIds,
    required this.createdAt,
  }) : garmentIds =
            Map<GarmentSlot, String?>.unmodifiable(<GarmentSlot, String?>{
          for (final slot in GarmentSlot.values) slot: garmentIds[slot],
        });

  factory SavedOutfit.fromOutfit(
    CurrentOutfit outfit, {
    required String id,
    required String name,
    DateTime? createdAt,
  }) {
    return SavedOutfit(
      id: id,
      name: name,
      styleId: outfit.styleId,
      garmentIds: outfit.garmentIds,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String styleId;
  final Map<GarmentSlot, String?> garmentIds;
  final DateTime createdAt;

  int get itemCount => garmentIds.values.whereType<String>().length;

  /// 恢复收藏时使用的状态；不沿用收藏时的锁定状态。
  CurrentOutfit toOutfit() => CurrentOutfit(
        styleId: styleId,
        garmentIds: garmentIds,
      );

  /// 内容指纹：同一服装组合 + 风格视为同一套穿搭，用于幂等收藏。
  String get signature => <String>[
        styleId,
        for (final slot in GarmentSlot.values)
          '${slot.name}:${garmentIds[slot] ?? '-'}',
      ].join('|');

  /// 引用了但已不在衣柜中的槽位。仅用于展示提示，恢复逻辑仍由控制器负责。
  List<GarmentSlot> missingSlots(Map<String, Garment> closet) {
    return <GarmentSlot>[
      for (final slot in GarmentSlot.values)
        if (garmentIds[slot] != null && closet[garmentIds[slot]] == null) slot,
    ];
  }
}
