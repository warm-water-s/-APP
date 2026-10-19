import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/current_outfit_controller.dart';
import '../domain/garment.dart';
import '../domain/outfit_state.dart';
import '../domain/saved_outfit.dart';
import 'demo_catalog.dart';
import 'outfit_storage.dart';
import 'saved_outfits_repository.dart';
import 'wardrobe_repository.dart';

/// 应用级状态容器：把衣橱、当前穿搭、收藏与偏好放在同一生命周期内。
///
/// 传入 [OutfitStorage] 时会自动持久化用户资产（衣橱、收藏、偏好、欢迎页状态）；
/// 当前穿搭草稿仍只存在于内存。未传 storage 的单元测试保持纯内存、无异步副作用。
class AppState extends ChangeNotifier {
  AppState({
    List<Garment>? initialWardrobe,
    Iterable<SavedOutfit> initialSavedOutfits = const <SavedOutfit>[],
    DateTime Function()? clock,
    Iterable<String> preferredStyles = const <String>[],
    bool welcomeSeen = false,
    OutfitStorage? storage,
  })  : wardrobe = WardrobeRepository(
          initial: initialWardrobe ?? demoGarments,
        ),
        savedOutfits = SavedOutfitsRepository(
          initial: initialSavedOutfits,
          clock: clock,
        ),
        _preferredStyles = <String>{...preferredStyles},
        _welcomeSeen = welcomeSeen,
        _storage = storage {
    outfit = CurrentOutfitController(closet: wardrobe.garments);
    wardrobe.addListener(_handleWardrobeChanged);
    savedOutfits.addListener(_handleSavedOutfitsChanged);
  }

  /// 从本地存储恢复；首次启动（或数据损坏）时使用演示衣橱并立即落盘。
  static Future<AppState> load({
    OutfitStorage? storage,
    List<Garment>? fallbackWardrobe,
    DateTime Function()? clock,
  }) async {
    final store = storage ?? SharedPreferencesOutfitStorage();
    StoredAppData? stored;
    try {
      stored = await store.load();
    } catch (_) {
      stored = null;
    }

    if (stored == null || !stored.hasWardrobe) {
      final state = AppState(
        initialWardrobe: fallbackWardrobe ?? demoGarments,
        clock: clock,
        storage: store,
      );
      await state.flush();
      return state;
    }

    return AppState(
      initialWardrobe: stored.garments,
      initialSavedOutfits: stored.savedOutfits,
      preferredStyles: stored.preferredStyles,
      welcomeSeen: stored.welcomeSeen,
      clock: clock,
      storage: store,
    );
  }

  final WardrobeRepository wardrobe;
  final SavedOutfitsRepository savedOutfits;
  final OutfitStorage? _storage;

  late final CurrentOutfitController outfit;

  final Set<String> _preferredStyles;
  bool _welcomeSeen;
  Timer? _persistTimer;
  bool _disposed = false;
  Object? _lastPersistenceError;

  Set<String> get preferredStyles => Set<String>.unmodifiable(_preferredStyles);

  bool get welcomeSeen => _welcomeSeen;

  /// 最近一次后台持久化错误；UI 可用它提示“本次修改可能无法跨启动保存”。
  Object? get lastPersistenceError => _lastPersistenceError;

  /// 首次启动显示欢迎页；进入主页后标记为已看过。
  void markWelcomeSeen() {
    if (_welcomeSeen) return;
    _welcomeSeen = true;
    notifyListeners();
    _schedulePersist();
  }

  void setPreferredStyles(Iterable<String> styles) {
    _preferredStyles
      ..clear()
      ..addAll(styles);
    notifyListeners();
    _schedulePersist();
  }

  void _handleWardrobeChanged() {
    // 服装被删除/编辑后，当前穿搭中失效的单品必须同步移除。
    outfit.replaceCloset(wardrobe.garments);
    notifyListeners();
    _schedulePersist();
  }

  void _handleSavedOutfitsChanged() {
    _schedulePersist();
  }

  SaveOutfitResult saveCurrentOutfit({String? name}) {
    return savedOutfits.save(outfit.state.snapshot(), name: name);
  }

  /// 恢复收藏；缺失的单品会变成空槽位，由控制器统一处理。
  void applySaved(SavedOutfit saved) {
    outfit.restoreSaved(saved.toOutfit());
  }

  /// 导出本机快照 JSON（用于用户检查 / 备份）。当前不提供导入恢复。
  String exportData() => _snapshot().encode();

  /// 删除本机衣橱、收藏、偏好与当前穿搭草稿。
  ///
  /// 删除后会写入一个“空衣橱”快照，避免下次启动重新填充演示数据。
  /// 欢迎页状态保持不变，避免用户被突然送回引导页。
  Future<void> clearPersonalData() async {
    _persistTimer?.cancel();
    outfit.clearAll();
    wardrobe.clear();
    savedOutfits.clear();
    _preferredStyles.clear();
    notifyListeners();

    final storage = _storage;
    if (storage != null) {
      try {
        await storage.clear();
        _lastPersistenceError = null;
      } catch (error) {
        _lastPersistenceError = error;
      }
    }
    await flush();
  }

  CurrentOutfit get currentOutfit => outfit.state;

  void _schedulePersist() {
    if (_storage == null || _disposed) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 120), () {
      unawaited(_persistNow());
    });
  }

  /// 立即写入磁盘。测试与退出前可等待它完成。
  Future<void> flush() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    await _persistNow();
  }

  Future<void> _persistNow() async {
    final storage = _storage;
    if (storage == null || _disposed) return;
    try {
      await storage.save(_snapshot());
      _lastPersistenceError = null;
    } catch (error) {
      _lastPersistenceError = error;
    }
  }

  StoredAppData _snapshot() {
    return StoredAppData(
      version: StoredAppData.currentVersion,
      hasWardrobe: true,
      garments: wardrobe.garments,
      savedOutfits: savedOutfits.all,
      preferredStyles: _preferredStyles,
      welcomeSeen: _welcomeSeen,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _persistTimer?.cancel();
    wardrobe.removeListener(_handleWardrobeChanged);
    savedOutfits.removeListener(_handleSavedOutfitsChanged);
    outfit.dispose();
    wardrobe.dispose();
    savedOutfits.dispose();
    super.dispose();
  }
}
