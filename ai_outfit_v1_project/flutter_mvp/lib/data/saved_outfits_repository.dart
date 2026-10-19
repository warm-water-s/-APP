import 'package:flutter/foundation.dart';

import '../domain/outfit_state.dart';
import '../domain/saved_outfit.dart';

/// 收藏写入结果。用于区分“新建”与“重复收藏”，避免连续点击产生重复记录。
class SaveOutfitResult {
  const SaveOutfitResult({required this.outfit, required this.created});

  final SavedOutfit outfit;
  final bool created;
}

/// 本地收藏仓库（V1.0 内存实现；持久化由 `AppState` + `OutfitStorage` 负责）。
class SavedOutfitsRepository extends ChangeNotifier {
  SavedOutfitsRepository({
    Iterable<SavedOutfit> initial = const <SavedOutfit>[],
    DateTime Function()? clock,
  })  : _items = List<SavedOutfit>.of(initial),
        _clock = clock ?? DateTime.now;

  final List<SavedOutfit> _items;
  final DateTime Function() _clock;
  int _sequence = 0;

  /// 最新收藏在前。
  List<SavedOutfit> get items =>
      List<SavedOutfit>.unmodifiable(_items.reversed);

  /// 按写入顺序（最旧在前），用于持久化，避免重新加载后顺序反转。
  List<SavedOutfit> get all => List<SavedOutfit>.unmodifiable(_items);

  int get length => _items.length;

  SavedOutfit? find(String id) {
    for (final outfit in _items) {
      if (outfit.id == id) return outfit;
    }
    return null;
  }

  SavedOutfit? findBySignature(String signature) {
    for (final outfit in _items) {
      if (outfit.signature == signature) return outfit;
    }
    return null;
  }

  SaveOutfitResult save(CurrentOutfit snapshot, {String? name}) {
    final draft = SavedOutfit.fromOutfit(
      snapshot,
      id: '',
      name: '',
      createdAt: _clock(),
    );
    final existing = findBySignature(draft.signature);
    if (existing != null) {
      return SaveOutfitResult(outfit: existing, created: false);
    }
    do {
      _sequence++;
    } while (find('saved-$_sequence') != null);
    final saved = SavedOutfit(
      id: 'saved-$_sequence',
      name:
          (name == null || name.trim().isEmpty) ? '穿搭 $_sequence' : name.trim(),
      styleId: snapshot.styleId,
      garmentIds: snapshot.garmentIds,
      createdAt: draft.createdAt,
    );
    _items.add(saved);
    notifyListeners();
    return SaveOutfitResult(outfit: saved, created: true);
  }

  bool remove(String id) {
    final index = _items.indexWhere((outfit) => outfit.id == id);
    if (index < 0) return false;
    _items.removeAt(index);
    notifyListeners();
    return true;
  }

  /// 清空收藏（隐私设置中的“删除本机数据”）。
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _sequence = 0;
    notifyListeners();
  }
}
