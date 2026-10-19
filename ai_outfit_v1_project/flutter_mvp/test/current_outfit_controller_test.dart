import 'package:flutter_test/flutter_test.dart';
import 'package:ai_outfit_mvp/data/demo_catalog.dart';
import 'package:ai_outfit_mvp/data/demo_recommendation_engine.dart';
import 'package:ai_outfit_mvp/domain/current_outfit_controller.dart';
import 'package:ai_outfit_mvp/domain/garment.dart';
import 'package:ai_outfit_mvp/domain/outfit_recommendation.dart';

void main() {
  late CurrentOutfitController controller;

  setUp(() {
    controller = CurrentOutfitController(closet: demoGarments);
  });

  tearDown(() => controller.dispose());

  test('T01: 初始化所有槽位为空', () {
    expect(controller.state.isEmpty, isTrue);
    expect(controller.state.isComplete, isFalse);
    expect(controller.state.lockedSlots, isEmpty);
    expect(controller.state.garmentIds.length, GarmentSlot.values.length);
  });

  test('T02: 选择上衣自动锁定，notifyListeners 只触发一次', () {
    var eventCount = 0;
    controller.addListener(() => eventCount++);
    controller.selectGarment(GarmentSlot.top, 't1');
    expect(controller.state[GarmentSlot.top], 't1');
    expect(controller.state.isLocked(GarmentSlot.top), isTrue);
    expect(eventCount, 1);
  });

  test('T03: 不能把鞋子放在上衣位置', () {
    expect(
      () => controller.selectGarment(GarmentSlot.top, 's1'),
      throwsA(isA<OutfitRuleException>()),
    );
    expect(controller.state.isEmpty, isTrue);
  });

  test('T04: 不存在于个人衣柜的 ID 被拒绝', () {
    expect(
      () => controller.selectGarment(GarmentSlot.top, 'foreign-item'),
      throwsA(isA<OutfitRuleException>()),
    );
  });

  test('T05: 已锁定上衣不能静默替换；明确确认后可替换', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    final previousRevision = controller.state.revision;
    expect(
      () => controller.selectGarment(GarmentSlot.top, 't2'),
      throwsA(isA<OutfitRuleException>()),
    );
    expect(controller.state.revision, previousRevision);
    expect(controller.state[GarmentSlot.top], 't1');

    controller.selectGarment(
      GarmentSlot.top,
      't2',
      replaceLocked: true,
    );
    expect(controller.state[GarmentSlot.top], 't2');
  });

  test('T06: 锁定上衣与下装时不能静默换成连衣裙', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    controller.selectGarment(GarmentSlot.bottom, 'b1');
    expect(
      () => controller.selectGarment(GarmentSlot.dress, 'd1'),
      throwsA(isA<OutfitRuleException>()),
    );
    expect(controller.state[GarmentSlot.dress], isNull);

    controller.selectGarment(
      GarmentSlot.dress,
      'd1',
      clearConflictingLocks: true,
    );
    expect(controller.state[GarmentSlot.dress], 'd1');
    expect(controller.state[GarmentSlot.top], isNull);
    expect(controller.state[GarmentSlot.bottom], isNull);
    expect(controller.state.lockedSlots.contains(GarmentSlot.top), isFalse);
  });

  test('T07: 连衣裙与鞋子可组成基础完整套装', () {
    controller.selectGarment(GarmentSlot.dress, 'd1');
    expect(controller.state.isComplete, isFalse);
    controller.selectGarment(GarmentSlot.shoes, 's1');
    expect(controller.state.isComplete, isTrue);
  });

  test('T08: 普通上下装必须有鞋子才完整', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    controller.selectGarment(GarmentSlot.bottom, 'b1');
    expect(controller.state.isComplete, isFalse);
    controller.selectGarment(GarmentSlot.shoes, 's1');
    expect(controller.state.isComplete, isTrue);
  });

  test('T09: 切换风格不得修改当前服装', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    final selectedBefore = controller.state.garmentIds;
    controller.setStyle('korean');
    expect(controller.state.styleId, 'korean');
    expect(controller.state.garmentIds, selectedBefore);
    expect(controller.state.isLocked(GarmentSlot.top), isTrue);
  });

  test('T10: 非法推荐必须原子回滚', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    final before = controller.state;
    final invalid = OutfitRecommendation(
      id: 'bad-1',
      styleId: 'minimal',
      garmentIds: <GarmentSlot, String?>{
        GarmentSlot.top: 't2', // 想覆盖锁定上衣
        GarmentSlot.bottom: 'b1',
        GarmentSlot.shoes: 's1',
      },
    );
    expect(
      () => controller.applyRecommendation(invalid),
      throwsA(isA<OutfitRuleException>()),
    );
    expect(controller.state.revision, before.revision);
    expect(controller.state[GarmentSlot.top], 't1');

    final missing = OutfitRecommendation(
      id: 'bad-2',
      styleId: 'minimal',
      garmentIds: <GarmentSlot, String?>{
        GarmentSlot.top: 't1',
        GarmentSlot.bottom: 'not-owned',
        GarmentSlot.shoes: 's1',
      },
    );
    expect(
      () => controller.applyRecommendation(missing),
      throwsA(isA<OutfitRuleException>()),
    );
    expect(controller.state.revision, before.revision);
  });

  test('T11: 演示推荐只使用衣橱且尊重锁定', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    final recommendations = const DemoRecommendationEngine().generate(
      current: controller.state,
      closet: demoGarments,
    );
    expect(recommendations, isNotEmpty);
    expect(recommendations.length, lessThanOrEqualTo(3));
    for (final recommendation in recommendations) {
      expect(recommendation.garmentIds[GarmentSlot.top], 't1');
    }
    controller.applyRecommendation(recommendations.first);
    expect(controller.state[GarmentSlot.top], 't1');
    expect(controller.state.isLocked(GarmentSlot.top), isTrue);
    expect(controller.state.isComplete, isTrue);
  });

  test('T12: 删除服装后，恢复收藏仅保留有效单品', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    controller.selectGarment(GarmentSlot.bottom, 'b1');
    controller.selectGarment(GarmentSlot.shoes, 's1');
    final saved = controller.state.snapshot();

    controller.replaceCloset(demoGarments.where((g) => g.id != 'b1'));
    expect(controller.state[GarmentSlot.bottom], isNull);

    controller.restoreSaved(saved);
    expect(controller.state[GarmentSlot.top], 't1');
    expect(controller.state[GarmentSlot.bottom], isNull);
    expect(controller.state[GarmentSlot.shoes], 's1');
    expect(controller.state.lockedSlots, isEmpty);
    expect(controller.state.isComplete, isFalse);
  });

  test('T13: 空槽位不能锁定', () {
    expect(
      () => controller.toggleLock(GarmentSlot.hat),
      throwsA(isA<OutfitRuleException>()),
    );
  });

  test('T14: 已锁定槽位不能直接删除', () {
    controller.selectGarment(GarmentSlot.top, 't1');
    expect(
      () => controller.clearSlot(GarmentSlot.top),
      throwsA(isA<OutfitRuleException>()),
    );
    controller.clearSlot(GarmentSlot.top, force: true);
    expect(controller.state[GarmentSlot.top], isNull);
    expect(controller.state.isLocked(GarmentSlot.top), isFalse);
  });

  test('T15: 推荐对象不能把连衣裙与普通上衣叠穿', () {
    final bad = OutfitRecommendation(
      id: 'bad-3',
      styleId: 'korean',
      garmentIds: <GarmentSlot, String?>{
        GarmentSlot.dress: 'd1',
        GarmentSlot.top: 't1',
        GarmentSlot.shoes: 's1',
      },
    );
    expect(
      () => controller.applyRecommendation(bad),
      throwsA(isA<OutfitRuleException>()),
    );
    expect(controller.state.isEmpty, isTrue);
  });
}
