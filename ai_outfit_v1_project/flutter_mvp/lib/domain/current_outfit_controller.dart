import 'package:flutter/foundation.dart';

import 'garment.dart';
import 'outfit_recommendation.dart';
import 'outfit_state.dart';

/// 业务规则异常。UI 层需要显示明确信息并允许用户确认强制替换。
class OutfitRuleException implements Exception {
  const OutfitRuleException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 负责单一事实来源的 CurrentOutfit 状态：
///
/// 1. 校验衣柜中是否存在被选择的衣服、类别与归属是否正确；
/// 2. 维护锁定 / 连衣裙互斥 / 套装完整性；
/// 3. 推荐先原子校验再提交；
/// 4. notifyListeners() 让 AvatarCanvas 与服装卡片一起刷新。
///
/// 不负责真实推荐评分、网络请求、AI 识别和持久化。
class CurrentOutfitController extends ChangeNotifier {
  CurrentOutfitController({
    required Iterable<Garment> closet,
    CurrentOutfit? initial,
  })  : _catalog = <String, Garment>{
          for (final garment in closet) garment.id: garment,
        },
        _state = initial ?? CurrentOutfit() {
    _readonlyCatalog = Map<String, Garment>.unmodifiable(_catalog);
    _validateItems(_state.garmentIds);
  }

  Map<String, Garment> _catalog;
  late Map<String, Garment> _readonlyCatalog;
  CurrentOutfit _state;

  CurrentOutfit get state => _state;

  /// 保持引用稳定，避免 AvatarPainter 因新的 Map wrapper 无意义地重绘。
  Map<String, Garment> get catalog => _readonlyCatalog;

  Garment? selected(GarmentSlot slot) {
    final id = _state[slot];
    return id == null ? null : _catalog[id];
  }

  void _checkKnown(GarmentSlot slot, String id) {
    final garment = _catalog[id];
    if (garment == null || !garment.owned) {
      throw OutfitRuleException('服装不存在于当前用户的衣柜：$id');
    }
    if (garment.slot != slot) {
      throw OutfitRuleException(
        '类别不匹配：${garment.name} 不能放到 ${slot.label}',
      );
    }
  }

  void _validateItems(Map<GarmentSlot, String?> garments) {
    for (final slot in GarmentSlot.values) {
      final id = garments[slot];
      if (id != null) _checkKnown(slot, id);
    }
    if (garments[GarmentSlot.dress] != null &&
        (garments[GarmentSlot.top] != null ||
            garments[GarmentSlot.bottom] != null)) {
      throw const OutfitRuleException('连衣裙与普通上衣/下装互斥');
    }
  }

  void _commit({
    required Map<GarmentSlot, String?> garments,
    required Set<GarmentSlot> locks,
    String? styleId,
  }) {
    _validateItems(garments);
    final next = CurrentOutfit(
      styleId: styleId ?? _state.styleId,
      garmentIds: garments,
      lockedSlots: locks,
      revision: _state.revision + 1,
    );
    _state = next;
    notifyListeners();
  }

  /// 显式人工选择：默认锁定选中单品。
  ///
  /// replaceLocked / clearConflictingLocks 仅应在 UI 明确二次确认之后设 true。
  void selectGarment(
    GarmentSlot slot,
    String garmentId, {
    bool replaceLocked = false,
    bool clearConflictingLocks = false,
    bool lockSelected = true,
  }) {
    _checkKnown(slot, garmentId);
    if (_state.isLocked(slot) && _state[slot] != garmentId && !replaceLocked) {
      throw OutfitRuleException('${slot.label}已锁定，请确认后再替换');
    }
    final garments = Map<GarmentSlot, String?>.of(_state.garmentIds);
    final locks = Set<GarmentSlot>.of(_state.lockedSlots);

    if (slot == GarmentSlot.dress) {
      for (final conflicting in <GarmentSlot>[
        GarmentSlot.top,
        GarmentSlot.bottom,
      ]) {
        if (locks.contains(conflicting) && !clearConflictingLocks) {
          throw const OutfitRuleException('请先解锁上衣/下装，才能穿连衣裙');
        }
        garments[conflicting] = null;
        locks.remove(conflicting);
      }
    } else if (slot == GarmentSlot.top || slot == GarmentSlot.bottom) {
      if (locks.contains(GarmentSlot.dress) && !clearConflictingLocks) {
        throw const OutfitRuleException('请先解锁连衣裙，才能更换上下装');
      }
      garments[GarmentSlot.dress] = null;
      locks.remove(GarmentSlot.dress);
    }

    garments[slot] = garmentId;
    if (lockSelected) {
      locks.add(slot);
    } else {
      locks.remove(slot);
    }
    _commit(garments: garments, locks: locks);
  }

  /// 移除单品。已锁定槽位必须显式传 force=true。
  void clearSlot(GarmentSlot slot, {bool force = false}) {
    if (_state.isLocked(slot) && !force) {
      throw OutfitRuleException('${slot.label}已锁定，请先解锁');
    }
    if (_state[slot] == null) return;
    final garments = Map<GarmentSlot, String?>.of(_state.garmentIds);
    final locks = Set<GarmentSlot>.of(_state.lockedSlots);
    garments[slot] = null;
    locks.remove(slot);
    _commit(garments: garments, locks: locks);
  }

  void toggleLock(GarmentSlot slot) {
    if (_state[slot] == null) {
      throw OutfitRuleException('不能锁定空的${slot.label}槽位');
    }
    final locks = Set<GarmentSlot>.of(_state.lockedSlots);
    if (!locks.add(slot)) locks.remove(slot);
    _commit(
      garments: Map<GarmentSlot, String?>.of(_state.garmentIds),
      locks: locks,
    );
  }

  void setStyle(String styleId) {
    if (styleId == _state.styleId) return;
    _commit(
      garments: Map<GarmentSlot, String?>.of(_state.garmentIds),
      locks: Set<GarmentSlot>.of(_state.lockedSlots),
      styleId: styleId,
    );
  }

  /// 推荐应用是原子操作：先验证全部候选 ID / 类别 / 锁定约束，再提交。
  /// 失败时 state 和 revision 都不得改变。
  void applyRecommendation(OutfitRecommendation recommendation) {
    final garments = Map<GarmentSlot, String?>.of(recommendation.garmentIds);
    _validateItems(garments);
    for (final lockedSlot in _state.lockedSlots) {
      if (garments[lockedSlot] != _state[lockedSlot]) {
        throw OutfitRuleException(
          '推荐试图覆盖已锁定的${lockedSlot.label}',
        );
      }
    }
    _commit(
      garments: garments,
      locks: Set<GarmentSlot>.of(_state.lockedSlots),
      styleId: recommendation.styleId,
    );
  }

  /// 恢复收藏。被删掉的衣服会成为空槽位，不会擅自替换为其他衣服。
  /// 收藏状态不沿用当年的锁定状态。
  void restoreSaved(CurrentOutfit saved) {
    final garments = <GarmentSlot, String?>{
      for (final slot in GarmentSlot.values) slot: null,
    };
    for (final slot in GarmentSlot.values) {
      final id = saved[slot];
      if (id == null) continue;
      final garment = _catalog[id];
      if (garment != null && garment.owned && garment.slot == slot) {
        garments[slot] = id;
      }
    }
    if (garments[GarmentSlot.dress] != null) {
      garments[GarmentSlot.top] = null;
      garments[GarmentSlot.bottom] = null;
    }
    _commit(
      garments: garments,
      locks: <GarmentSlot>{},
      styleId: saved.styleId,
    );
  }

  /// 用户删除或导入服装后更新缓存。移除失效的当前单品及其锁定状态。
  void replaceCloset(Iterable<Garment> closet) {
    final nextCatalog = <String, Garment>{
      for (final garment in closet) garment.id: garment,
    };
    final garments = Map<GarmentSlot, String?>.of(_state.garmentIds);
    final locks = Set<GarmentSlot>.of(_state.lockedSlots);
    for (final slot in GarmentSlot.values) {
      final id = garments[slot];
      final candidate = id == null ? null : nextCatalog[id];
      if (id != null &&
          (candidate == null || !candidate.owned || candidate.slot != slot)) {
        garments[slot] = null;
        locks.remove(slot);
      }
    }
    _catalog = nextCatalog;
    _readonlyCatalog = Map<String, Garment>.unmodifiable(_catalog);
    _commit(garments: garments, locks: locks);
  }

  void clearAll() {
    _commit(
      garments: <GarmentSlot, String?>{
        for (final slot in GarmentSlot.values) slot: null,
      },
      locks: <GarmentSlot>{},
    );
  }
}
