import 'package:flutter_test/flutter_test.dart';

import 'package:ai_outfit_mvp/data/demo_catalog.dart';
import 'package:ai_outfit_mvp/data/demo_recommendation_engine.dart';
import 'package:ai_outfit_mvp/domain/current_outfit_controller.dart';
import 'package:ai_outfit_mvp/domain/garment.dart';

void main() {
  const engine = DemoRecommendationEngine();

  test('E01: 空衣橱不生成任何推荐', () {
    final controller = CurrentOutfitController(closet: const <Garment>[]);
    addTearDown(controller.dispose);

    final results = engine.generate(
      current: controller.state,
      closet: const <Garment>[],
    );
    expect(results, isEmpty);
  });

  test('E02: 推荐只使用衣橱内单品，并保留锁定上衣', () {
    final controller = CurrentOutfitController(closet: demoGarments);
    addTearDown(controller.dispose);
    controller.selectGarment(GarmentSlot.top, 't1');

    final results = engine.generate(
      current: controller.state,
      closet: demoGarments,
      limit: 3,
    );

    expect(results, isNotEmpty);
    expect(results.length, lessThanOrEqualTo(3));
    final wardrobeIds = demoGarments.map((garment) => garment.id).toSet();
    for (final recommendation in results) {
      expect(recommendation.garmentIds[GarmentSlot.top], 't1');
      for (final id in recommendation.garmentIds.values.whereType<String>()) {
        expect(wardrobeIds, contains(id));
      }
    }
  });

  test('E03: 衣柜缺鞋时返回部分搭配并标注缺失类别', () {
    final partialCloset = <Garment>[
      ...demoGarments.where(
        (garment) =>
            garment.slot == GarmentSlot.top ||
            garment.slot == GarmentSlot.bottom,
      ),
    ];
    final controller = CurrentOutfitController(closet: partialCloset);
    addTearDown(controller.dispose);
    controller.selectGarment(GarmentSlot.top, 't1');
    controller.selectGarment(GarmentSlot.bottom, 'b1');

    final results = engine.generate(
      current: controller.state,
      closet: partialCloset,
    );

    expect(results, isNotEmpty);
    expect(results.first.missingSlots, contains(GarmentSlot.shoes));
    expect(results.first.isComplete, isFalse);
    expect(results.first.garmentIds[GarmentSlot.shoes], isNull);
  });

  test('E04: 推荐理由引用真实单品名称，不虚构标签', () {
    final controller = CurrentOutfitController(closet: demoGarments);
    addTearDown(controller.dispose);
    controller.selectGarment(GarmentSlot.top, 't1');

    final results = engine.generate(
      current: controller.state,
      closet: demoGarments,
    );
    expect(results.first.reason, contains('米白色基础衬衫'));
    expect(results.first.reason, contains('个人衣橱'));
  });

  test('E05: owned=false 的服装不会参与推荐', () {
    const hidden = Garment(
      id: 't-hidden',
      name: '未拥有上衣',
      slot: GarmentSlot.top,
      colorHex: '#000000',
      subcategory: 'T恤',
      owned: false,
    );
    final closet = <Garment>[...demoGarments, hidden];
    final controller = CurrentOutfitController(closet: closet);
    addTearDown(controller.dispose);
    controller.selectGarment(GarmentSlot.top, 't1');

    final results = engine.generate(current: controller.state, closet: closet);
    for (final recommendation in results) {
      expect(recommendation.garmentIds[GarmentSlot.top], 't1');
      expect(recommendation.garmentIds.values, isNot(contains('t-hidden')));
    }
  });

  test('E06: 连衣裙方案不会同时包含上衣或下装', () {
    final controller = CurrentOutfitController(closet: demoGarments);
    addTearDown(controller.dispose);
    controller.selectGarment(GarmentSlot.dress, 'd1');

    final results = engine.generate(
      current: controller.state,
      closet: demoGarments,
    );
    expect(results, isNotEmpty);
    for (final recommendation in results) {
      expect(recommendation.garmentIds[GarmentSlot.dress], 'd1');
      expect(recommendation.garmentIds[GarmentSlot.top], isNull);
      expect(recommendation.garmentIds[GarmentSlot.bottom], isNull);
    }
  });
}
