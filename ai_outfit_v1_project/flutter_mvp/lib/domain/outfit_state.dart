import 'garment.dart';

/// 不可变的当前穿搭快照。
///
/// 约束：
/// - 六个槽位始终存在（允许 null）。
/// - locked 只能包含当前有衣服的槽位。
/// - dress 与 top/bottom 互斥。
class CurrentOutfit {
  CurrentOutfit._({
    required this.styleId,
    required this.garmentIds,
    required this.lockedSlots,
    required this.revision,
  });

  factory CurrentOutfit({
    String styleId = 'minimal',
    Map<GarmentSlot, String?> garmentIds = const <GarmentSlot, String?>{},
    Set<GarmentSlot> lockedSlots = const <GarmentSlot>{},
    int revision = 0,
  }) {
    final normalized = <GarmentSlot, String?>{
      for (final slot in GarmentSlot.values) slot: garmentIds[slot],
    };
    for (final slot in lockedSlots) {
      if (normalized[slot] == null) {
        throw ArgumentError('空槽位无法锁定: ${slot.name}');
      }
    }
    if (normalized[GarmentSlot.dress] != null &&
        (normalized[GarmentSlot.top] != null ||
            normalized[GarmentSlot.bottom] != null)) {
      throw ArgumentError('连衣裙与普通上衣/下装互斥');
    }
    if (styleId.isEmpty) throw ArgumentError('styleId 不能为空');

    return CurrentOutfit._(
      styleId: styleId,
      garmentIds: Map<GarmentSlot, String?>.unmodifiable(normalized),
      lockedSlots: Set<GarmentSlot>.unmodifiable(lockedSlots),
      revision: revision,
    );
  }

  final String styleId;
  final Map<GarmentSlot, String?> garmentIds;
  final Set<GarmentSlot> lockedSlots;
  final int revision;

  String? operator [](GarmentSlot slot) => garmentIds[slot];

  bool isLocked(GarmentSlot slot) => lockedSlots.contains(slot);

  bool get isComplete =>
      garmentIds[GarmentSlot.shoes] != null &&
      (garmentIds[GarmentSlot.dress] != null ||
          (garmentIds[GarmentSlot.top] != null &&
              garmentIds[GarmentSlot.bottom] != null));

  bool get isEmpty => garmentIds.values.every((value) => value == null);

  /// 创建安全快照；适用于收藏和切换方案时防止隐式修改。
  CurrentOutfit snapshot() => CurrentOutfit(
        styleId: styleId,
        garmentIds: garmentIds,
        lockedSlots: lockedSlots,
        revision: revision,
      );

  @override
  String toString() => 'CurrentOutfit(styleId: $styleId, revision: $revision, '
      'items: $garmentIds, locked: $lockedSlots)';
}
