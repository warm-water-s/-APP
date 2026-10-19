import 'package:flutter_test/flutter_test.dart';

import 'package:ai_outfit_mvp/data/app_state.dart';
import 'package:ai_outfit_mvp/data/demo_catalog.dart';
import 'package:ai_outfit_mvp/data/wardrobe_repository.dart';
import 'package:ai_outfit_mvp/domain/garment.dart';
import 'package:ai_outfit_mvp/domain/outfit_state.dart';

void main() {
  group('WardrobeRepository', () {
    test('R01: 添加服装会生成唯一 ID，并可更新和删除', () {
      final repo = WardrobeRepository(initial: demoGarments);
      final initialCount = repo.length;

      final added = repo.add(
        const Garment(
          id: '',
          name: '测试风衣',
          slot: GarmentSlot.outer,
          colorHex: '#BDA98E',
          subcategory: '风衣',
          sourceType: GarmentSource.manual,
        ),
      );
      expect(added.id, isNotEmpty);
      expect(repo.length, initialCount + 1);
      expect(repo.find(added.id)?.name, '测试风衣');

      repo.update(added.copyWith(name: '测试风衣（改）'));
      expect(repo.find(added.id)?.name, '测试风衣（改）');

      expect(repo.remove(added.id), isTrue);
      expect(repo.length, initialCount);
      expect(repo.remove('not-exist'), isFalse);
    });

    test('R02: 搜索按类别与关键字过滤', () {
      final repo = WardrobeRepository(initial: demoGarments);
      expect(repo.bySlot(GarmentSlot.top).length, 4);
      expect(repo.search(query: '衬衫').length, 2);
      expect(repo.search(slot: GarmentSlot.top, query: '条纹').length, 1);
      expect(repo.search(query: '不存在的关键字'), isEmpty);
    });
  });

  group('SavedOutfitsRepository', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
      appState.outfit.selectGarment(GarmentSlot.top, 't1');
      appState.outfit.selectGarment(GarmentSlot.bottom, 'b1');
      appState.outfit.selectGarment(GarmentSlot.shoes, 's1');
    });

    tearDown(() => appState.dispose());

    test('R03: 同一套穿搭重复保存保持幂等', () {
      final first = appState.saveCurrentOutfit();
      final second = appState.saveCurrentOutfit();

      expect(first.created, isTrue);
      expect(second.created, isFalse);
      expect(second.outfit.id, first.outfit.id);
      expect(appState.savedOutfits.length, 1);
    });

    test('R04: 收藏保存同一份服装 ID，锁定状态不写入收藏', () {
      final result = appState.saveCurrentOutfit(name: '通勤一套');
      expect(result.outfit.name, '通勤一套');
      expect(result.outfit.garmentIds[GarmentSlot.top], 't1');
      expect(result.outfit.garmentIds[GarmentSlot.bottom], 'b1');
      expect(result.outfit.garmentIds[GarmentSlot.shoes], 's1');
      expect(result.outfit.toOutfit().lockedSlots, isEmpty);
    });

    test('R05: 删除被收藏引用的衣服后，恢复只保留仍存在的单品', () {
      final saved = appState.saveCurrentOutfit().outfit;
      appState.wardrobe.remove('b1');

      expect(saved.missingSlots(appState.wardrobe.asMap), <GarmentSlot>[
        GarmentSlot.bottom,
      ]);

      appState.outfit.clearAll();
      appState.applySaved(saved);

      expect(appState.outfit.state[GarmentSlot.top], 't1');
      expect(appState.outfit.state[GarmentSlot.bottom], isNull);
      expect(appState.outfit.state[GarmentSlot.shoes], 's1');
      expect(appState.outfit.state.isComplete, isFalse);
      expect(appState.outfit.state.lockedSlots, isEmpty);
    });

    test('R06: 删除收藏不影响衣服', () {
      final saved = appState.saveCurrentOutfit().outfit;
      expect(appState.savedOutfits.remove(saved.id), isTrue);
      expect(appState.savedOutfits.length, 0);
      expect(appState.wardrobe.find('t1'), isNotNull);
    });
  });

  group('AppState 衣橱与当前穿搭同步', () {
    test('R07: 删除当前穿着的衣服会同步移除槽位与锁定', () {
      final appState = AppState();
      addTearDown(appState.dispose);
      appState.outfit.selectGarment(GarmentSlot.top, 't1');
      expect(appState.outfit.state.isLocked(GarmentSlot.top), isTrue);

      appState.wardrobe.remove('t1');

      expect(appState.outfit.state[GarmentSlot.top], isNull);
      expect(appState.outfit.state.isLocked(GarmentSlot.top), isFalse);
    });

    test('R08: 新导入服装后可直接用于搭配', () {
      final appState = AppState(initialWardrobe: const <Garment>[]);
      addTearDown(appState.dispose);
      final added = appState.wardrobe.add(
        const Garment(
          id: '',
          name: '新衬衫',
          slot: GarmentSlot.top,
          colorHex: '#FFFFFF',
          subcategory: '衬衫',
          sourceType: GarmentSource.manual,
        ),
      );

      appState.outfit.selectGarment(GarmentSlot.top, added.id);
      expect(appState.outfit.state[GarmentSlot.top], added.id);
    });
  });

  test('R09: CurrentOutfit 快照不可被外部修改', () {
    final state = CurrentOutfit(
      garmentIds: const <GarmentSlot, String?>{
        GarmentSlot.top: 't1',
      },
    );
    expect(
      () => state.garmentIds[GarmentSlot.top] = 't2',
      throwsUnsupportedError,
    );
  });
}
