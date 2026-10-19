import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/garment.dart';
import '../domain/outfit_state.dart';
import 'widgets/app_pill.dart';
import 'widgets/garment_visual.dart';

/// V1.0：固定人形 + 可替换颜色/轮廓的 2D 穿搭示意。
///
/// 重要边界：这里不进行任意商品图的几何变形，也不保证真实试穿效果。
/// 正式版可将绘制层升级为经过规范化的分层 PNG / SVG 素材。
class AvatarCanvas extends StatelessWidget {
  const AvatarCanvas({
    super.key,
    required this.outfit,
    required this.closet,
    required this.onSlotTap,
    this.showHotspots = true,
  });

  final CurrentOutfit outfit;
  final Map<String, Garment> closet;
  final ValueChanged<GarmentSlot> onSlotTap;

  /// 小尺寸缩略图（收藏列表、欢迎页）关闭热点，避免溢出和误导性点击。
  final bool showHotspots;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 350 / 370,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEADFD3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 8, 26, 8),
                    child: CustomPaint(
                      key: const Key('avatar-paint'),
                      painter: AvatarPainter(outfit: outfit, closet: closet),
                    ),
                  ),
                ),
                if (showHotspots) ...<Widget>[
                  _hotspot(GarmentSlot.hat, top: 38, right: 6),
                  _hotspot(GarmentSlot.top, top: 112, left: 6),
                  _hotspot(GarmentSlot.outer, top: 166, right: 6),
                  _hotspot(GarmentSlot.dress, top: 199, left: 6),
                  _hotspot(GarmentSlot.bottom, top: 244, left: 6),
                  _hotspot(GarmentSlot.shoes, bottom: 42, right: 6),
                  Positioned(
                    bottom: 7,
                    left: 0,
                    right: 0,
                    child: Text(
                      '点击服装部位来换装 · 2D 示意非真实试衣',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF978C81),
                          ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hotspot(
    GarmentSlot slot, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AppPill(
        key: Key('avatar-slot-${slot.name}'),
        label: slot.label,
        selected: outfit[slot] != null,
        dense: true,
        semanticLabel: '更换${slot.label}',
        leading: Icon(garmentSlotIcon(slot)),
        onTap: () => onSlotTap(slot),
      ),
    );
  }
}

class AvatarPainter extends CustomPainter {
  AvatarPainter({
    required this.outfit,
    required this.closet,
  });

  final CurrentOutfit outfit;
  final Map<String, Garment> closet;

  Color _colorFor(GarmentSlot slot, Color fallback) {
    final id = outfit[slot];
    final raw = id == null ? null : closet[id]?.colorHex;
    if (raw == null) return fallback;
    final value = raw.replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return fallback;
    return Color(int.parse('FF$value', radix: 16));
  }

  void _polygon(Canvas canvas, Color color, List<Offset> points,
      {Color? stroke}) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const logicalWidth = 280.0;
    const logicalHeight = 480.0;
    final scale = math.min(
      size.width / logicalWidth,
      size.height / logicalHeight,
    );
    canvas.save();
    canvas.translate(
      (size.width - logicalWidth * scale) / 2,
      (size.height - logicalHeight * scale) / 2,
    );
    canvas.scale(scale);
    _paintPerson(canvas);
    canvas.restore();
  }

  void _paintPerson(Canvas canvas) {
    const skin = Color(0xFFE0B398);
    const hair = Color(0xFF503B35);
    const outline = Color(0x33716356);
    final top = _colorFor(GarmentSlot.top, const Color(0xFFF0E7DE));
    final bottom = _colorFor(GarmentSlot.bottom, const Color(0xFF4C5260));
    final dress = _colorFor(GarmentSlot.dress, const Color(0xFFB2C3BD));
    final outer = _colorFor(GarmentSlot.outer, const Color(0xFFB9A58F));
    final shoe = _colorFor(GarmentSlot.shoes, const Color(0xFFF2EDE5));
    final hat = _colorFor(GarmentSlot.hat, const Color(0xFFB59B7F));

    // 舞台底部的柔和接地阴影。
    canvas.drawOval(
      const Rect.fromLTWH(77, 448, 128, 14),
      Paint()..color = const Color(0x3DA18E80),
    );
    // 人物四肢的基础形体。
    _polygon(canvas, skin, const [
      Offset(114, 265),
      Offset(139, 265),
      Offset(134, 433),
      Offset(116, 433),
    ]);
    _polygon(canvas, skin, const [
      Offset(143, 265),
      Offset(165, 265),
      Offset(168, 433),
      Offset(148, 433),
    ]);
    _polygon(canvas, skin, const [
      Offset(105, 156),
      Offset(88, 164),
      Offset(77, 239),
      Offset(91, 318),
      Offset(103, 316),
      Offset(99, 235),
      Offset(116, 193),
    ]);
    _polygon(canvas, skin, const [
      Offset(175, 156),
      Offset(192, 164),
      Offset(203, 239),
      Offset(189, 318),
      Offset(177, 316),
      Offset(181, 235),
      Offset(164, 193),
    ]);

    // 头发、面部和脖颈。
    canvas.drawOval(
      const Rect.fromLTWH(99, 24, 82, 121),
      Paint()..color = hair,
    );
    canvas.drawRect(
      const Rect.fromLTWH(128, 123, 24, 31),
      Paint()..color = skin,
    );
    canvas.drawOval(
      const Rect.fromLTWH(102, 35, 76, 98),
      Paint()..color = skin,
    );
    _polygon(canvas, hair, const [
      Offset(100, 75),
      Offset(105, 37),
      Offset(127, 22),
      Offset(162, 26),
      Offset(180, 55),
      Offset(178, 83),
      Offset(158, 51),
      Offset(138, 61),
      Offset(118, 69),
    ]);
    canvas.drawCircle(
      const Offset(126, 88),
      1.8,
      Paint()..color = hair,
    );
    canvas.drawCircle(
      const Offset(153, 88),
      1.8,
      Paint()..color = hair,
    );
    canvas.drawArc(
      const Rect.fromLTWH(130, 103, 19, 7),
      0.2,
      2.6,
      false,
      Paint()
        ..color = const Color(0xFFAA706A)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );

    final wearingDress = outfit[GarmentSlot.dress] != null;
    // 下装先于上衣绘制，以便上衣自然遮盖腰部连接。
    if (wearingDress) {
      _polygon(
          canvas,
          dress,
          const [
            Offset(113, 145),
            Offset(126, 139),
            Offset(140, 151),
            Offset(154, 139),
            Offset(167, 145),
            Offset(198, 197),
            Offset(179, 207),
            Offset(167, 185),
            Offset(184, 354),
            Offset(96, 354),
            Offset(113, 185),
            Offset(101, 207),
            Offset(82, 197),
          ],
          stroke: outline);
    } else {
      final bottomId = outfit[GarmentSlot.bottom];
      final bottomGarment = bottomId == null ? null : closet[bottomId];
      final isSkirt = bottomGarment?.subcategory.contains('裙') ?? false;
      if (isSkirt) {
        _polygon(
            canvas,
            bottom,
            const [
              Offset(111, 282),
              Offset(168, 282),
              Offset(194, 370),
              Offset(86, 370),
            ],
            stroke: outline);
      } else {
        _polygon(
            canvas,
            bottom,
            const [
              Offset(112, 280),
              Offset(168, 280),
              Offset(174, 431),
              Offset(147, 431),
              Offset(140, 326),
              Offset(133, 431),
              Offset(108, 431),
            ],
            stroke: outline);
      }
      _polygon(
          canvas,
          top,
          const [
            Offset(117, 146),
            Offset(126, 138),
            Offset(140, 151),
            Offset(154, 138),
            Offset(166, 146),
            Offset(196, 207),
            Offset(175, 217),
            Offset(167, 182),
            Offset(166, 288),
            Offset(113, 288),
            Offset(113, 183),
            Offset(105, 217),
            Offset(84, 207),
          ],
          stroke: outline);
      canvas.drawLine(
        const Offset(113, 284),
        const Offset(166, 284),
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..strokeWidth = 1.5,
      );
    }
    // 外套：左右两片分开，让内搭视觉上可见。
    if (outfit[GarmentSlot.outer] != null) {
      _polygon(
          canvas,
          outer,
          const [
            Offset(104, 145),
            Offset(126, 137),
            Offset(136, 157),
            Offset(132, 291),
            Offset(105, 285),
            Offset(110, 186),
            Offset(104, 218),
            Offset(83, 209),
          ],
          stroke: outline);
      _polygon(
          canvas,
          outer,
          const [
            Offset(176, 145),
            Offset(154, 137),
            Offset(144, 157),
            Offset(148, 291),
            Offset(175, 285),
            Offset(170, 186),
            Offset(176, 218),
            Offset(197, 209),
          ],
          stroke: outline);
    }
    // 鞋子绘制在下装和小腿前面。
    _polygon(
        canvas,
        shoe,
        const [
          Offset(114, 420),
          Offset(135, 420),
          Offset(137, 450),
          Offset(99, 450),
          Offset(103, 438),
        ],
        stroke: outline);
    _polygon(
        canvas,
        shoe,
        const [
          Offset(145, 420),
          Offset(167, 420),
          Offset(181, 448),
          Offset(142, 450),
        ],
        stroke: outline);
    canvas.drawLine(
      const Offset(101, 446),
      const Offset(136, 446),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      const Offset(143, 446),
      const Offset(179, 446),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
    // 可选帽子：盖在头发上方。
    if (outfit[GarmentSlot.hat] != null) {
      _polygon(
          canvas,
          hat,
          const [
            Offset(97, 65),
            Offset(101, 35),
            Offset(116, 23),
            Offset(140, 19),
            Offset(163, 23),
            Offset(181, 38),
            Offset(183, 65),
          ],
          stroke: outline);
      canvas.drawLine(
        const Offset(93, 64),
        const Offset(190, 64),
        Paint()
          ..color = hat
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) =>
      outfit.revision != oldDelegate.outfit.revision ||
      !identical(closet, oldDelegate.closet);
}
