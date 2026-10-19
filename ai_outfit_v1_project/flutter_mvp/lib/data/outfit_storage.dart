import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/garment.dart';
import '../domain/saved_outfit.dart';

/// 本地持久化的完整快照。
///
/// 只保存“用户资产”（衣橱、收藏、偏好、是否看过欢迎页），
/// 当前穿搭草稿仍由 `CurrentOutfitController` 在内存中管理。
class StoredAppData {
  StoredAppData({
    required this.version,
    required this.hasWardrobe,
    required List<Garment> garments,
    required List<SavedOutfit> savedOutfits,
    required Set<String> preferredStyles,
    required this.welcomeSeen,
  })  : garments = List<Garment>.unmodifiable(garments),
        savedOutfits = List<SavedOutfit>.unmodifiable(savedOutfits),
        preferredStyles = Set<String>.unmodifiable(preferredStyles);

  static const int currentVersion = 1;

  final int version;

  /// true 表示用户衣橱已经初始化（包括“用户主动清空”），此时不应再用演示数据覆盖。
  final bool hasWardrobe;
  final List<Garment> garments;
  final List<SavedOutfit> savedOutfits;
  final Set<String> preferredStyles;
  final bool welcomeSeen;

  String encode() {
    return jsonEncode(<String, Object?>{
      'version': currentVersion,
      'has_wardrobe': hasWardrobe,
      'wardrobe': <Map<String, Object?>>[
        for (final garment in garments) _garmentToJson(garment),
      ],
      'saved_outfits': <Map<String, Object?>>[
        for (final outfit in savedOutfits) _savedOutfitToJson(outfit),
      ],
      'preferred_styles': preferredStyles.toList(growable: false),
      'welcome_seen': welcomeSeen,
    });
  }

  /// 解析失败（损坏 / 版本不支持 / 字段类型错误）时返回 null，调用方回退到演示数据。
  static StoredAppData? tryDecode(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      final version = decoded['version'];
      if (version is! int || version != currentVersion) return null;

      final garments = <Garment>[];
      final wardrobe = decoded['wardrobe'];
      if (wardrobe is List) {
        for (final item in wardrobe) {
          if (item is! Map<String, dynamic>) continue;
          final garment = _garmentFromJson(item);
          if (garment != null) garments.add(garment);
        }
      }

      final savedOutfits = <SavedOutfit>[];
      final saved = decoded['saved_outfits'];
      if (saved is List) {
        for (final item in saved) {
          if (item is! Map<String, dynamic>) continue;
          final outfit = _savedOutfitFromJson(item);
          if (outfit != null) savedOutfits.add(outfit);
        }
      }

      return StoredAppData(
        version: version,
        hasWardrobe: decoded['has_wardrobe'] == true,
        garments: garments,
        savedOutfits: savedOutfits,
        preferredStyles: _stringSet(decoded['preferred_styles']),
        welcomeSeen: decoded['welcome_seen'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 存储抽象，便于测试注入内存实现，也便于将来换成后端。
abstract interface class OutfitStorage {
  Future<StoredAppData?> load();

  Future<void> save(StoredAppData data);

  /// 删除本机快照（隐私设置里的“删除本机数据”）。
  Future<void> clear();
}

/// 真实设备 / Web 使用的本地存储（shared_preferences）。
class SharedPreferencesOutfitStorage implements OutfitStorage {
  static const String storageKey = 'ai_outfit_v1_state';

  @override
  Future<StoredAppData?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    return StoredAppData.tryDecode(raw);
  }

  @override
  Future<void> save(StoredAppData data) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(storageKey, data.encode());
    if (!saved) {
      throw StateError('本地存储写入失败');
    }
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(storageKey);
    if (!removed) {
      throw StateError('本地存储删除失败');
    }
  }
}

/// 测试 / 截图使用的内存存储。
class InMemoryOutfitStorage implements OutfitStorage {
  InMemoryOutfitStorage({this.throwOnSave = false});

  StoredAppData? data;
  bool throwOnSave;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<StoredAppData?> load() async => data;

  @override
  Future<void> save(StoredAppData value) async {
    saveCount++;
    if (throwOnSave) throw StateError('模拟存储失败');
    // 通过一次真实的 JSON 编解码，确保测试覆盖序列化而不是只换对象引用。
    final decoded = StoredAppData.tryDecode(value.encode());
    if (decoded == null) throw StateError('内存存储序列化失败');
    data = decoded;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    data = null;
  }
}

Map<String, Object?> _garmentToJson(Garment garment) {
  return <String, Object?>{
    'id': garment.id,
    'name': garment.name,
    'slot': garment.slot.name,
    'subcategory': garment.subcategory,
    'color_hex': garment.colorHex,
    'style_ids': garment.styleIds.toList(growable: false),
    'seasons': garment.seasons.toList(growable: false),
    'owned': garment.owned,
    'source_type': garment.sourceType.name,
    'source_url': garment.sourceUrl,
    'image_ref': garment.imageRef,
    'fit': garment.fit,
    'pattern': garment.pattern,
    'note': garment.note,
  };
}

Garment? _garmentFromJson(Map<String, dynamic> json) {
  final id = json['id'];
  final name = json['name'];
  final slotName = json['slot'];
  final subcategory = json['subcategory'];
  final colorHex = json['color_hex'];
  if (id is! String || id.isEmpty) return null;
  if (name is! String || name.isEmpty) return null;
  if (slotName is! String) return null;
  if (subcategory is! String || subcategory.isEmpty) return null;
  if (colorHex is! String || colorHex.isEmpty) return null;
  final slot = _enumByName(GarmentSlot.values, slotName);
  if (slot == null) return null;

  return Garment(
    id: id,
    name: name,
    slot: slot,
    subcategory: subcategory,
    colorHex: colorHex,
    styleIds: _stringSet(json['style_ids']),
    seasons: _stringSet(json['seasons']),
    owned: json['owned'] != false,
    sourceType: _enumByName(GarmentSource.values, json['source_type']) ??
        GarmentSource.manual,
    sourceUrl: _optionalString(json['source_url']),
    imageRef: _optionalString(json['image_ref']),
    fit: _optionalString(json['fit']),
    pattern: _optionalString(json['pattern']),
    note: _optionalString(json['note']),
  );
}

Map<String, Object?> _savedOutfitToJson(SavedOutfit outfit) {
  return <String, Object?>{
    'id': outfit.id,
    'name': outfit.name,
    'style_id': outfit.styleId,
    'garments': <String, String?>{
      for (final slot in GarmentSlot.values) slot.name: outfit.garmentIds[slot],
    },
    'created_at': outfit.createdAt.toIso8601String(),
  };
}

SavedOutfit? _savedOutfitFromJson(Map<String, dynamic> json) {
  final id = json['id'];
  final name = json['name'];
  final styleId = json['style_id'];
  final garments = json['garments'];
  final createdAtRaw = json['created_at'];
  if (id is! String || id.isEmpty) return null;
  if (name is! String || name.isEmpty) return null;
  if (styleId is! String || styleId.isEmpty) return null;
  if (garments is! Map) return null;
  if (createdAtRaw is! String) return null;
  final createdAt = DateTime.tryParse(createdAtRaw);
  if (createdAt == null) return null;

  final garmentIds = <GarmentSlot, String?>{
    for (final slot in GarmentSlot.values)
      slot:
          garments[slot.name] is String ? garments[slot.name] as String : null,
  };
  if (garmentIds.values.every((id) => id == null)) return null;

  return SavedOutfit(
    id: id,
    name: name,
    styleId: styleId,
    garmentIds: garmentIds,
    createdAt: createdAt,
  );
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

Set<String> _stringSet(Object? value) {
  if (value is! List) return <String>{};
  return <String>{
    for (final item in value)
      if (item is String && item.isNotEmpty) item,
  };
}

String? _optionalString(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}
