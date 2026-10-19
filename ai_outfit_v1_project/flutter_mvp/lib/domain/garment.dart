/// 真实衣服的类别 / 在 2D 人物上的穿着槽位。
/// 第一版只允许每个槽位选择一件衣服。
enum GarmentSlot {
  top('上衣'),
  outer('外套'),
  bottom('下装'),
  dress('连衣裙'),
  shoes('鞋子'),
  hat('帽子');

  const GarmentSlot(this.label);
  final String label;
}

/// 服装进入衣橱的来源。正式服务的来源由后端返回，客户端只做展示。
enum GarmentSource {
  demo('演示数据'),
  photo('相册导入'),
  camera('拍照导入'),
  link('商品链接'),
  manual('手动录入');

  const GarmentSource(this.label);
  final String label;
}

/// 领域数据，不依赖 Flutter UI。
/// 生产环境 garment.id 应由后端发放，owned 以及访问权限需由服务端确认。
class Garment {
  const Garment({
    required this.id,
    required this.name,
    required this.slot,
    required this.colorHex,
    required this.subcategory,
    this.styleIds = const <String>{},
    this.seasons = const <String>{},
    this.owned = true,
    this.sourceType = GarmentSource.demo,
    this.sourceUrl,
    this.imageRef,
    this.fit,
    this.pattern,
    this.note,
  });

  final String id;
  final String name;
  final GarmentSlot slot;
  final String subcategory;
  final String colorHex; // #RRGGBB
  final Set<String> styleIds;
  final Set<String> seasons;
  final bool owned;

  /// 数据来源。演示衣柜中的衣服必须保持 [GarmentSource.demo]，不能伪装成真实导入。
  final GarmentSource sourceType;
  final String? sourceUrl;

  /// 预留的图片资源标识；V1.0 仅展示颜色/轮廓占位，不加载远程图片。
  final String? imageRef;
  final String? fit;
  final String? pattern;
  final String? note;

  bool get isDemo => sourceType == GarmentSource.demo;

  Garment copyWith({
    String? id,
    String? name,
    GarmentSlot? slot,
    String? subcategory,
    String? colorHex,
    Set<String>? styleIds,
    Set<String>? seasons,
    bool? owned,
    GarmentSource? sourceType,
    String? sourceUrl,
    String? imageRef,
    String? fit,
    String? pattern,
    String? note,
  }) {
    return Garment(
      id: id ?? this.id,
      name: name ?? this.name,
      slot: slot ?? this.slot,
      subcategory: subcategory ?? this.subcategory,
      colorHex: colorHex ?? this.colorHex,
      styleIds: styleIds ?? this.styleIds,
      seasons: seasons ?? this.seasons,
      owned: owned ?? this.owned,
      sourceType: sourceType ?? this.sourceType,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imageRef: imageRef ?? this.imageRef,
      fit: fit ?? this.fit,
      pattern: pattern ?? this.pattern,
      note: note ?? this.note,
    );
  }
}

/// 季节字典，供 UI 显示中文名。
const seasonNames = <String, String>{
  'spring': '春',
  'summer': '夏',
  'autumn': '秋',
  'winter': '冬',
};
