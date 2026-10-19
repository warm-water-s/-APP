import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_outfit_mvp/data/app_state.dart';
import 'package:ai_outfit_mvp/data/demo_catalog.dart';
import 'package:ai_outfit_mvp/data/outfit_storage.dart';
import 'package:ai_outfit_mvp/domain/garment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('P01: JSON 往返保留衣橱可选字段、收藏、偏好与欢迎状态', () async {
    final storage = InMemoryOutfitStorage();
    final state = AppState(
      storage: storage,
      preferredStyles: const <String>['minimal'],
      welcomeSeen: true,
    );
    addTearDown(state.dispose);

    state.wardrobe.add(
      const Garment(
        id: 'g-link',
        name: '链接风衣',
        slot: GarmentSlot.outer,
        colorHex: '#BDA98E',
        subcategory: '风衣',
        styleIds: <String>{'commute'},
        seasons: <String>{'autumn'},
        sourceType: GarmentSource.link,
        sourceUrl: 'https://example.com/item/1',
        note: '来源备注',
      ),
    );
    state.outfit.selectGarment(GarmentSlot.top, 't1');
    state.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    state.outfit.selectGarment(GarmentSlot.shoes, 's1');
    state.setPreferredStyles(const <String>['minimal', 'korean']);
    state.saveCurrentOutfit(name: '通勤一套');
    await state.flush();

    final decoded = StoredAppData.tryDecode(storage.data!.encode());
    expect(decoded, isNotNull);
    expect(decoded!.hasWardrobe, isTrue);
    expect(decoded.welcomeSeen, isTrue);
    expect(decoded.preferredStyles, <String>{'minimal', 'korean'});
    expect(decoded.garments.length, demoGarments.length + 1);
    expect(decoded.savedOutfits, hasLength(1));
    expect(decoded.savedOutfits.single.name, '通勤一套');

    final linked = decoded.garments.firstWhere((g) => g.id == 'g-link');
    expect(linked.sourceType, GarmentSource.link);
    expect(linked.sourceUrl, 'https://example.com/item/1');
    expect(linked.note, '来源备注');
    expect(linked.seasons, <String>{'autumn'});
  });

  test('P02: 重启后恢复衣橱修改、收藏、偏好与欢迎状态', () async {
    final storage = InMemoryOutfitStorage();
    final clock = () => DateTime(2026, 10, 18, 10, 30);

    final first = await AppState.load(storage: storage, clock: clock);
    first.wardrobe.add(
      const Garment(
        id: 'g-persist',
        name: '持久化风衣',
        slot: GarmentSlot.outer,
        colorHex: '#BDA98E',
        subcategory: '风衣',
        sourceType: GarmentSource.manual,
      ),
    );
    first.outfit.selectGarment(GarmentSlot.dress, 'd1');
    first.outfit.selectGarment(GarmentSlot.shoes, 's1');
    first.saveCurrentOutfit(name: '重启后还在');
    first.setPreferredStyles(const <String>['street']);
    first.markWelcomeSeen();
    await first.flush();
    first.dispose();

    final second = await AppState.load(storage: storage, clock: clock);
    addTearDown(second.dispose);

    expect(second.welcomeSeen, isTrue);
    expect(second.preferredStyles, <String>{'street'});
    expect(second.wardrobe.find('g-persist')?.name, '持久化风衣');
    expect(second.savedOutfits.length, 1);
    expect(second.savedOutfits.items.single.name, '重启后还在');
    expect(second.savedOutfits.items.single.styleId, 'minimal');
    expect(
        second.savedOutfits.items.single.garmentIds[GarmentSlot.dress], 'd1');
  });

  test('P03: 用户清空衣柜后，重启不会重新填充演示数据', () async {
    final storage = InMemoryOutfitStorage();
    final first = await AppState.load(storage: storage);
    for (final garment in <Garment>[...first.wardrobe.garments]) {
      first.wardrobe.remove(garment.id);
    }
    await first.flush();
    first.dispose();
    expect(storage.data!.garments, isEmpty);

    final second = await AppState.load(storage: storage);
    addTearDown(second.dispose);
    expect(second.wardrobe.length, 0);
    expect(second.wardrobe.garments, isEmpty);
  });

  test('P04: 损坏 / 版本不兼容的本地数据回退为 null', () {
    expect(StoredAppData.tryDecode('not-json'), isNull);
    expect(StoredAppData.tryDecode('{"version":99,"wardrobe":[]}'), isNull);
    expect(
      StoredAppData.tryDecode('{"version":1,"wardrobe":"bad"}'),
      isNotNull,
    );
  });

  test('P05: 存储失败不阻断启动，并记录 lastPersistenceError', () async {
    final storage = InMemoryOutfitStorage(throwOnSave: true);
    final state = await AppState.load(storage: storage);
    addTearDown(state.dispose);

    expect(state.lastPersistenceError, isNotNull);
    expect(state.wardrobe.length, greaterThan(0));

    storage.throwOnSave = false;
    state.markWelcomeSeen();
    await state.flush();
    expect(state.lastPersistenceError, isNull);
    expect(storage.data!.welcomeSeen, isTrue);
  });

  test('P06: 多条收藏重启后保持创建顺序（最新在前）', () async {
    final storage = InMemoryOutfitStorage();
    final clock = () => DateTime(2026, 10, 18, 9, 0);

    final first = await AppState.load(storage: storage, clock: clock);
    first.outfit.selectGarment(GarmentSlot.top, 't1');
    first.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    first.outfit.selectGarment(GarmentSlot.shoes, 's1');
    first.saveCurrentOutfit(name: '第一套');

    first.outfit.clearAll();
    first.outfit.selectGarment(GarmentSlot.top, 't2');
    first.outfit.selectGarment(GarmentSlot.bottom, 'b2');
    first.outfit.selectGarment(GarmentSlot.shoes, 's2');
    first.saveCurrentOutfit(name: '第二套');
    await first.flush();
    first.dispose();

    final second = await AppState.load(storage: storage, clock: clock);
    addTearDown(second.dispose);
    expect(second.savedOutfits.items.length, 2);
    expect(second.savedOutfits.items[0].name, '第二套');
    expect(second.savedOutfits.items[1].name, '第一套');
  });

  test('P07: 当前穿搭草稿不会跨启动持久化', () async {
    final storage = InMemoryOutfitStorage();
    final first = await AppState.load(storage: storage);
    first.outfit.selectGarment(GarmentSlot.top, 't1');
    first.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    first.outfit.selectGarment(GarmentSlot.shoes, 's1');
    await first.flush();
    first.dispose();

    final second = await AppState.load(storage: storage);
    addTearDown(second.dispose);
    expect(second.currentOutfit.isEmpty, isTrue);
  });

  test('P08: SharedPreferences 存储实现可读写完整快照', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = SharedPreferencesOutfitStorage();
    expect(await storage.load(), isNull);

    final state = AppState(storage: storage);
    addTearDown(state.dispose);
    state.outfit.selectGarment(GarmentSlot.top, 't1');
    state.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    state.outfit.selectGarment(GarmentSlot.shoes, 's1');
    state.saveCurrentOutfit(name: '本地保存');
    state.markWelcomeSeen();
    await state.flush();

    final loaded = await storage.load();
    expect(loaded, isNotNull);
    expect(loaded!.welcomeSeen, isTrue);
    expect(loaded.garments.length, demoGarments.length);
    expect(loaded.savedOutfits.single.name, '本地保存');
  });

  test('P09: 两种存储实现都支持删除快照', () async {
    final memory = InMemoryOutfitStorage();
    final memoryState = AppState(storage: memory);
    await memoryState.flush();
    expect(memory.data, isNotNull);
    await memory.clear();
    expect(memory.data, isNull);
    expect(memory.clearCount, 1);
    memoryState.dispose();

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = SharedPreferencesOutfitStorage();
    final prefState = AppState(storage: preferences);
    await prefState.flush();
    expect(await preferences.load(), isNotNull);
    await preferences.clear();
    expect(await preferences.load(), isNull);
    prefState.dispose();
  });

  test('P10: 删除本机数据会清空衣橱/收藏/偏好并持久化空快照', () async {
    final storage = InMemoryOutfitStorage();
    final state = await AppState.load(storage: storage);
    state.wardrobe.add(
      const Garment(
        id: 'g-delete',
        name: '待删除风衣',
        slot: GarmentSlot.outer,
        colorHex: '#BDA98E',
        subcategory: '风衣',
        sourceType: GarmentSource.manual,
      ),
    );
    state.outfit.selectGarment(GarmentSlot.top, 't1');
    state.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    state.outfit.selectGarment(GarmentSlot.shoes, 's1');
    state.saveCurrentOutfit(name: '待删除收藏');
    state.setPreferredStyles(const <String>['street']);
    state.markWelcomeSeen();
    await state.flush();

    await state.clearPersonalData();

    expect(state.wardrobe.length, 0);
    expect(state.savedOutfits.length, 0);
    expect(state.preferredStyles, isEmpty);
    expect(state.currentOutfit.isEmpty, isTrue);
    expect(state.welcomeSeen, isTrue);
    expect(storage.data, isNotNull);
    expect(storage.data!.garments, isEmpty);
    expect(storage.data!.savedOutfits, isEmpty);
    expect(storage.data!.preferredStyles, isEmpty);

    final reloaded = await AppState.load(storage: storage);
    addTearDown(reloaded.dispose);
    expect(reloaded.wardrobe.length, 0);
    expect(reloaded.savedOutfits.length, 0);
    expect(reloaded.preferredStyles, isEmpty);
    expect(reloaded.welcomeSeen, isTrue);
    state.dispose();
  });

  test('P11: 导出数据包含衣橱、收藏与偏好，不包含当前穿搭草稿键', () async {
    final state = AppState(storage: InMemoryOutfitStorage());
    addTearDown(state.dispose);
    state.outfit.selectGarment(GarmentSlot.top, 't1');
    state.outfit.selectGarment(GarmentSlot.bottom, 'b1');
    state.outfit.selectGarment(GarmentSlot.shoes, 's1');
    state.saveCurrentOutfit(name: '导出测试');
    state.setPreferredStyles(const <String>['minimal']);

    final json = state.exportData();
    expect(json, contains('"wardrobe"'));
    expect(json, contains('"saved_outfits"'));
    expect(json, contains('导出测试'));
    expect(json, contains('"preferred_styles"'));
    expect(json, isNot(contains('"current_outfit"')));
  });
}
