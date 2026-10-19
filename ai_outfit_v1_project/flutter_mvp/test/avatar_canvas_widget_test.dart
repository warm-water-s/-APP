import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_outfit_mvp/data/demo_catalog.dart';
import 'package:ai_outfit_mvp/domain/current_outfit_controller.dart';
import 'package:ai_outfit_mvp/domain/garment.dart';
import 'package:ai_outfit_mvp/ui/avatar_canvas.dart';

void main() {
  testWidgets('W01: AvatarCanvas 存在 6 个可点击的快捷槽位', (
    WidgetTester tester,
  ) async {
    final controller = CurrentOutfitController(closet: demoGarments);
    GarmentSlot? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: AvatarCanvas(
                outfit: controller.state,
                closet: controller.catalog,
                onSlotTap: (slot) => tapped = slot,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('avatar-paint')), findsOneWidget);
    expect(find.byKey(const Key('avatar-slot-top')), findsOneWidget);
    expect(find.byKey(const Key('avatar-slot-outer')), findsOneWidget);
    expect(find.byKey(const Key('avatar-slot-bottom')), findsOneWidget);
    expect(find.byKey(const Key('avatar-slot-dress')), findsOneWidget);
    expect(find.byKey(const Key('avatar-slot-shoes')), findsOneWidget);
    expect(find.byKey(const Key('avatar-slot-hat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('avatar-slot-top')));
    expect(tapped, GarmentSlot.top);
    controller.dispose();
  });

  test('W02: 状态 revision 变化时，人物画笔应重绘', () {
    final controller = CurrentOutfitController(closet: demoGarments);
    final before = AvatarPainter(
      outfit: controller.state,
      closet: controller.catalog,
    );
    controller.selectGarment(GarmentSlot.top, 't1');
    final after = AvatarPainter(
      outfit: controller.state,
      closet: controller.catalog,
    );
    expect(after.shouldRepaint(before), isTrue);
    controller.dispose();
  });
}
