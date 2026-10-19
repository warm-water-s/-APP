import '../domain/garment.dart';
import '../domain/outfit_recommendation.dart';
import '../domain/outfit_state.dart';

/// 用于证明前端状态与人物渲染能联动的确定性演示推荐。
///
/// **边界：** 这不是生产版 AI 算法，也没有学习用户偏好；只按“真实衣柜 + 风格标签 +
/// 颜色重复度”做可解释的排序。正式版由后端规则引擎 / 模型替换。
class DemoRecommendationEngine {
  const DemoRecommendationEngine();

  List<OutfitRecommendation> generate({
    required CurrentOutfit current,
    required Iterable<Garment> closet,
    int limit = 3,
  }) {
    if (limit <= 0) return const <OutfitRecommendation>[];
    final grouped = <GarmentSlot, List<Garment>>{
      for (final slot in GarmentSlot.values) slot: <Garment>[],
    };
    for (final garment in closet) {
      if (garment.owned) grouped[garment.slot]!.add(garment);
    }
    final byId = <String, Garment>{
      for (final category in grouped.values)
        for (final item in category) item.id: item,
    };

    final tops = grouped[GarmentSlot.top]!;
    final bottoms = grouped[GarmentSlot.bottom]!;
    final dresses = grouped[GarmentSlot.dress]!;
    final shoes = grouped[GarmentSlot.shoes]!;
    final shoeChoices = <Garment?>[...shoes];
    if (shoeChoices.isEmpty) {
      // 衣柜缺少鞋子时仍展示可用部分，并在缺失类别中说明，而不是虚构单品。
      shoeChoices.add(null);
    }

    Map<GarmentSlot, String?> base() => <GarmentSlot, String?>{
          for (final slot in GarmentSlot.values) slot: null,
          GarmentSlot.outer: current[GarmentSlot.outer],
          GarmentSlot.hat: current[GarmentSlot.hat],
        };

    bool preservesLocks(Map<GarmentSlot, String?> garmentIds) {
      for (final slot in current.lockedSlots) {
        if (garmentIds[slot] != current[slot]) return false;
      }
      return true;
    }

    double score(Map<GarmentSlot, String?> ids) {
      final used = ids.values
          .whereType<String>()
          .map((id) => byId[id])
          .whereType<Garment>()
          .toList(growable: false);
      final matchingStyles =
          used.where((item) => item.styleIds.contains(current.styleId)).length;
      final uniqueColors = used.map((item) => item.colorHex).toSet().length;
      return matchingStyles * 10 + (used.length - uniqueColors) * 0.5;
    }

    final proposed = <_ScoredOutfit>[];
    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final shoe in shoeChoices) {
          final ids = base()
            ..[GarmentSlot.top] = top.id
            ..[GarmentSlot.bottom] = bottom.id
            ..[GarmentSlot.shoes] = shoe?.id;
          if (preservesLocks(ids)) proposed.add(_ScoredOutfit(ids, score(ids)));
        }
      }
    }
    for (final dress in dresses) {
      for (final shoe in shoeChoices) {
        final ids = base()
          ..[GarmentSlot.dress] = dress.id
          ..[GarmentSlot.shoes] = shoe?.id;
        if (preservesLocks(ids)) proposed.add(_ScoredOutfit(ids, score(ids)));
      }
    }

    proposed.sort((a, b) {
      final points = b.score.compareTo(a.score);
      if (points != 0) return points;
      return a.signature.compareTo(b.signature);
    });

    final results = <OutfitRecommendation>[];
    final signatures = <String>{};
    for (final item in proposed) {
      if (!signatures.add(item.signature)) continue;
      results.add(_recommendation(
        ids: item.garmentIds,
        byId: byId,
        current: current,
        index: results.length + 1,
      ));
      if (results.length >= limit) break;
    }

    if (results.isEmpty) {
      // 衣柜不足以生成新组合时，保留当前穿搭并明确缺少的类别。
      final ids = Map<GarmentSlot, String?>.of(current.garmentIds);
      if (ids.values.any((value) => value != null)) {
        results.add(_recommendation(
          ids: ids,
          byId: byId,
          current: current,
          index: 1,
        ));
      }
    }
    return results;
  }

  OutfitRecommendation _recommendation({
    required Map<GarmentSlot, String?> ids,
    required Map<String, Garment> byId,
    required CurrentOutfit current,
    required int index,
  }) {
    final missing = _missingSlots(ids);
    final lockedNames = <String>[
      for (final slot in current.lockedSlots)
        if (ids[slot] != null && byId[ids[slot]] != null) byId[ids[slot]]!.name,
    ];
    final usedNames = <String>[
      for (final slot in <GarmentSlot>[
        GarmentSlot.dress,
        GarmentSlot.top,
        GarmentSlot.bottom,
        GarmentSlot.shoes,
        GarmentSlot.outer,
        GarmentSlot.hat,
      ])
        if (ids[slot] != null && byId[ids[slot]] != null) byId[ids[slot]]!.name,
    ];

    final buffer = StringBuffer();
    if (lockedNames.isNotEmpty) {
      buffer.write('保留已锁定的${lockedNames.join('、')}；');
    }
    if (usedNames.isEmpty) {
      buffer.write('当前没有可展示的单品。');
    } else {
      buffer.write('用你已有的${usedNames.join('、')}组合');
    }
    if (missing.isEmpty) {
      buffer.write('，全部单品均来自个人衣橱。');
    } else {
      buffer.write(
          '；衣柜暂缺${missing.map((slot) => slot.label).join('、')}，未虚构替代单品。');
    }

    return OutfitRecommendation(
      id: 'demo-$index',
      styleId: current.styleId,
      garmentIds: ids,
      reason: buffer.toString(),
      missingSlots: missing,
    );
  }

  List<GarmentSlot> _missingSlots(Map<GarmentSlot, String?> ids) {
    final missing = <GarmentSlot>[];
    if (ids[GarmentSlot.dress] != null) {
      if (ids[GarmentSlot.shoes] == null) missing.add(GarmentSlot.shoes);
    } else {
      if (ids[GarmentSlot.top] == null) missing.add(GarmentSlot.top);
      if (ids[GarmentSlot.bottom] == null) missing.add(GarmentSlot.bottom);
      if (ids[GarmentSlot.shoes] == null) missing.add(GarmentSlot.shoes);
    }
    return missing;
  }
}

class _ScoredOutfit {
  _ScoredOutfit(this.garmentIds, this.score);

  final Map<GarmentSlot, String?> garmentIds;
  final double score;

  String get signature =>
      GarmentSlot.values.map((slot) => garmentIds[slot] ?? '_').join('|');
}
