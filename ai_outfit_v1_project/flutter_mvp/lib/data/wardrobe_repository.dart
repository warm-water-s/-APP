import 'package:flutter/foundation.dart';

import '../domain/garment.dart';

/// 本地衣橱仓库（V1.0 内存实现；持久化由 `AppState` + `OutfitStorage` 负责）。
///
/// 正式版本会用带鉴权的后端 Repository 替换本类；UI 不直接维护服装列表。
class WardrobeRepository extends ChangeNotifier {
  WardrobeRepository({Iterable<Garment> initial = const <Garment>[]})
      : _garments = List<Garment>.of(initial);

  final List<Garment> _garments;
  int _sequence = 0;

  List<Garment> get garments => List<Garment>.unmodifiable(_garments);

  int get length => _garments.length;

  Map<String, Garment> get asMap => <String, Garment>{
        for (final garment in _garments) garment.id: garment,
      };

  Garment? find(String id) {
    for (final garment in _garments) {
      if (garment.id == id) return garment;
    }
    return null;
  }

  List<Garment> bySlot(GarmentSlot slot) => _garments
      .where((garment) => garment.slot == slot)
      .toList(growable: false);

  /// 衣橱列表的类别 + 关键字过滤；空关键字表示不过滤。
  List<Garment> search({GarmentSlot? slot, String query = ''}) {
    final keyword = query.trim().toLowerCase();
    return _garments.where((garment) {
      if (slot != null && garment.slot != slot) return false;
      if (keyword.isEmpty) return true;
      return garment.name.toLowerCase().contains(keyword) ||
          garment.subcategory.toLowerCase().contains(keyword);
    }).toList(growable: false);
  }

  /// 添加服装。id 为空或与现有重复时生成新的本地演示 ID。
  Garment add(Garment draft) {
    var id = draft.id;
    if (id.isEmpty || find(id) != null) {
      do {
        _sequence++;
        id = 'g-$_sequence';
      } while (find(id) != null);
    }
    final garment = draft.copyWith(id: id);
    _garments.add(garment);
    notifyListeners();
    return garment;
  }

  void update(Garment garment) {
    final index = _garments.indexWhere((item) => item.id == garment.id);
    if (index < 0) {
      throw ArgumentError('服装不存在：${garment.id}');
    }
    _garments[index] = garment;
    notifyListeners();
  }

  bool remove(String id) {
    final index = _garments.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    _garments.removeAt(index);
    notifyListeners();
    return true;
  }

  /// 清空衣橱（隐私设置中的“删除本机数据”）。
  void clear() {
    if (_garments.isEmpty) return;
    _garments.clear();
    _sequence = 0;
    notifyListeners();
  }
}
