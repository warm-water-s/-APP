import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_outfit_mvp/app.dart';
import 'package:ai_outfit_mvp/data/app_state.dart';
import 'package:ai_outfit_mvp/domain/garment.dart';
import 'package:ai_outfit_mvp/ui/avatar_canvas.dart';

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<AppState> _startApp(WidgetTester tester,
    {Size size = const Size(390, 844)}) async {
  await _setSurface(tester, size);
  final appState = AppState();
  addTearDown(appState.dispose);
  await tester.pumpWidget(AiOutfitApp(appState: appState));
  await tester.tap(find.byKey(const Key('welcome-start')));
  await tester.pumpAndSettle();
  return appState;
}

Future<void> _scrollTo(
  WidgetTester tester,
  Key key, {
  Key scrollKey = const Key('home-scroll'),
}) async {
  final scrollable = find
      .descendant(
        of: find.byKey(scrollKey),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    find.byKey(key),
    220,
    scrollable: scrollable,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('W03: 首页完整换装 → 搭配 → 收藏 → 收藏列表', (tester) async {
    final appState = await _startApp(tester);

    expect(find.byKey(const Key('avatar-canvas')), findsOneWidget);
    expect(find.text('今天，穿点不一样的。'), findsOneWidget);

    // 点击人物上衣热点 → BottomSheet → 选择衬衫。
    await tester.tap(find.byKey(const Key('avatar-slot-top')));
    await tester.pumpAndSettle();
    expect(find.text('选择上衣'), findsOneWidget);

    await tester.tap(find.byKey(const Key('picker-t1')));
    await tester.pumpAndSettle();

    expect(appState.outfit.state[GarmentSlot.top], 't1');
    expect(appState.outfit.state.isLocked(GarmentSlot.top), isTrue);
    expect(find.text('米白色基础衬衫'), findsWidgets);

    // 生成推荐：锁定上衣必须保留，人物与卡片读取同一状态。
    await _scrollTo(tester, const Key('recommend-button'));
    await tester.tap(find.byKey(const Key('recommend-button')));
    await tester.pumpAndSettle();

    await _scrollTo(tester, const Key('recommendation-counter'));
    expect(find.byKey(const Key('recommendation-counter')), findsOneWidget);
    expect(find.textContaining('方案 1 /'), findsOneWidget);
    expect(appState.outfit.state[GarmentSlot.top], 't1');
    expect(appState.outfit.state.isLocked(GarmentSlot.top), isTrue);
    expect(appState.outfit.state.isComplete, isTrue);

    // 换一套后仍保留锁定上衣。
    await _scrollTo(tester, const Key('next-recommendation'));
    await tester.tap(find.byKey(const Key('next-recommendation')));
    await tester.pumpAndSettle();
    expect(find.textContaining('方案 2 /'), findsOneWidget);
    expect(appState.outfit.state[GarmentSlot.top], 't1');

    // 保存收藏。
    await _scrollTo(tester, const Key('save-recommendation'));
    await tester.tap(find.byKey(const Key('save-recommendation')));
    await tester.pumpAndSettle();
    expect(appState.savedOutfits.length, 1);

    // 进入穿搭 Tab，看到刚保存的收藏。
    await tester.tap(find.byKey(const Key('tab-outfits')));
    await tester.pumpAndSettle();
    expect(find.text('我的穿搭'), findsOneWidget);
    final savedId = appState.savedOutfits.items.first.id;
    expect(find.byKey(Key('saved-item-$savedId')), findsOneWidget);
  });

  testWidgets('W04: 替换已锁定上衣必须弹窗确认，取消则不改变状态', (tester) async {
    final appState = await _startApp(tester);
    appState.outfit.selectGarment(GarmentSlot.top, 't1');
    await tester.pumpAndSettle();

    await _scrollTo(tester, const Key('slot-row-top'));
    await tester.tap(find.byKey(const Key('slot-row-top')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('picker-t2')));
    await tester.pumpAndSettle();
    expect(find.text('需要确认'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(appState.outfit.state[GarmentSlot.top], 't1');

    // 再次尝试并确认替换。
    await tester.tap(find.byKey(const Key('slot-row-top')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picker-t2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认替换'));
    await tester.pumpAndSettle();

    expect(appState.outfit.state[GarmentSlot.top], 't2');
    expect(appState.outfit.state.isLocked(GarmentSlot.top), isTrue);
  });

  testWidgets('W05: 衣物删除后，收藏显示缺失且恢复不虚构替代', (tester) async {
    final appState = await _startApp(tester);
    appState.outfit.selectGarment(GarmentSlot.top, 't1');
    appState.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    appState.outfit.selectGarment(GarmentSlot.shoes, 's1');
    appState.saveCurrentOutfit();
    appState.wardrobe.remove('b1');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab-outfits')));
    await tester.pumpAndSettle();
    expect(find.textContaining('缺失：下装'), findsOneWidget);

    final savedId = appState.savedOutfits.items.first.id;
    await tester.tap(find.byKey(Key('saved-item-$savedId')));
    await tester.pumpAndSettle();
    expect(find.text('穿搭详情'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wear-saved')));
    await tester.pumpAndSettle();

    expect(appState.outfit.state[GarmentSlot.bottom], isNull);
    expect(appState.outfit.state[GarmentSlot.top], 't1');
    expect(find.text('今天，穿点不一样的。'), findsOneWidget);
  });

  testWidgets('W06: 320px 窄屏下首页与选衣弹层不溢出', (tester) async {
    final appState = await _startApp(tester, size: const Size(320, 640));

    await tester.drag(
      find.byKey(const Key('home-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('home-scroll')),
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('avatar-slot-outer')));
    await tester.pumpAndSettle();
    expect(find.text('选择外套'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('picker-o1')));
    await tester.pumpAndSettle();
    expect(appState.outfit.state[GarmentSlot.outer], 'o1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('W07: 缩略图模式不渲染交互热点', (tester) async {
    final appState = AppState();
    addTearDown(appState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 90,
              child: AvatarCanvas(
                outfit: appState.currentOutfit,
                closet: appState.wardrobe.asMap,
                onSlotTap: (_) {},
                showHotspots: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('avatar-paint')), findsOneWidget);
    expect(find.byKey(const Key('avatar-slot-top')), findsNothing);
    expect(find.byKey(const Key('avatar-slot-hat')), findsNothing);
  });

  testWidgets('W09: 1.3 倍大字体下首页仍可滚动且无布局异常', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _startApp(tester, size: const Size(390, 844));
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('home-scroll')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _scrollTo(tester, const Key('save-button'));
    expect(find.byKey(const Key('save-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W10: 隐私页删除本机数据会清空衣橱与收藏', (tester) async {
    final appState = await _startApp(tester);
    appState.outfit.selectGarment(GarmentSlot.top, 't1');
    appState.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    appState.outfit.selectGarment(GarmentSlot.shoes, 's1');
    appState.saveCurrentOutfit(name: '待删除');
    appState.setPreferredStyles(const <String>['street']);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab-profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-privacy')));
    await tester.pumpAndSettle();

    expect(find.text('本机数据管理'), findsOneWidget);
    await _scrollTo(
      tester,
      const Key('privacy-clear'),
      scrollKey: const Key('privacy-scroll'),
    );
    await tester.tap(find.byKey(const Key('privacy-clear')));
    await tester.pumpAndSettle();
    expect(find.text('删除本机数据？'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(appState.wardrobe.length, 0);
    expect(appState.savedOutfits.length, 0);
    expect(appState.preferredStyles, isEmpty);
    expect(appState.currentOutfit.isEmpty, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('我的'), findsWidgets);
  });

  testWidgets('W08: 衣橱空状态添加服装后可用于搭配', (tester) async {
    final appState = AppState(initialWardrobe: const <Garment>[]);
    addTearDown(appState.dispose);
    await tester.pumpWidget(AiOutfitApp(appState: appState));
    await tester.tap(find.byKey(const Key('welcome-start')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab-wardrobe')));
    await tester.pumpAndSettle();
    expect(find.text('衣橱还是空的'), findsOneWidget);

    await tester.tap(find.byKey(const Key('empty-add')));
    await tester.pumpAndSettle();
    expect(find.text('添加衣服'), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-link')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('link-url')),
      'https://item.taobao.com/item.htm?id=1',
    );
    await tester.tap(find.byKey(const Key('link-parse')));
    await tester.pumpAndSettle();
    expect(find.text('链接格式有效'), findsOneWidget);

    await tester.tap(find.byKey(const Key('link-continue')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('garment-name')), '新买的衬衫');
    await _scrollTo(
      tester,
      const Key('garment-save'),
      scrollKey: const Key('garment-editor-scroll'),
    );
    await tester.tap(find.byKey(const Key('garment-save')));
    await tester.pumpAndSettle();

    expect(appState.wardrobe.length, 1);
    expect(find.text('我的衣橱'), findsOneWidget);
    expect(find.text('1 件'), findsOneWidget);
  });
}
