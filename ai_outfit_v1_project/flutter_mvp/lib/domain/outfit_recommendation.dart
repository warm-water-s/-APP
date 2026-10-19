import 'garment.dart';

/// 推荐服务返回的数据。推荐仅提供候选，真正写入当前穿搭前还需校验。
class OutfitRecommendation {
  OutfitRecommendation({
    required this.id,
    required this.styleId,
    required Map<GarmentSlot, String?> garmentIds,
    this.reason = '',
    Iterable<GarmentSlot> missingSlots = const <GarmentSlot>[],
  })  : garmentIds =
            Map<GarmentSlot, String?>.unmodifiable(<GarmentSlot, String?>{
          for (final slot in GarmentSlot.values) slot: garmentIds[slot],
        }),
        missingSlots = List<GarmentSlot>.unmodifiable(missingSlots);

  final String id;
  final String styleId;
  final Map<GarmentSlot, String?> garmentIds;
  final String reason;

  /// 衣柜缺少的必要类别；完整套装为空列表。
  final List<GarmentSlot> missingSlots;

  bool get isComplete => missingSlots.isEmpty;
}
