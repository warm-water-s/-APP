import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/garment.dart';

const _swatchBackground = Color(0xFFF7F1E8);

/// 解析 `#RRGGBB` 颜色；非法值回退为中性灰，避免坏数据导致页面崩溃。
Color parseGarmentColor(String? hex) {
  if (hex == null) return const Color(0xFFD9CFC3);
  final value = hex.replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
    return const Color(0xFFD9CFC3);
  }
  return Color(int.parse('FF$value', radix: 16));
}

IconData garmentSlotIcon(GarmentSlot slot) {
  switch (slot) {
    case GarmentSlot.top:
      return Icons.checkroom;
    case GarmentSlot.outer:
      return Icons.dry_cleaning;
    case GarmentSlot.bottom:
      return Icons.airline_seat_legroom_normal;
    case GarmentSlot.dress:
      return Icons.woman;
    case GarmentSlot.shoes:
      return Icons.hiking;
    case GarmentSlot.hat:
      return Icons.sports_baseball;
  }
}

/// 用主色 + 类别轮廓表示服装，是 V1.0 在没有真实商品图时的统一占位。
///
/// 轮廓只表达“这是上衣/裤子/鞋”，不承诺真实版型；接入真实图片后由图片替代。
class GarmentSwatch extends StatelessWidget {
  const GarmentSwatch({
    super.key,
    required this.garment,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.showIcon = true,
  });

  final Garment? garment;
  final double? width;
  final double? height;
  final double borderRadius;

  /// 为 false 时使用纯色块（用于非常小的空间），仍保留类别底色。
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final item = garment;
    final color = item == null
        ? const Color(0xFFE7DED2)
        : parseGarmentColor(item.colorHex);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _swatchBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: item == null
          ? Center(
              child: Icon(
                Icons.add,
                size: 20,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            )
          : showIcon
              ? SizedBox.expand(
                  child: CustomPaint(
                    painter: GarmentShapePainter(
                      slot: item.slot,
                      color: color,
                      isSkirt: item.subcategory.contains('裙'),
                    ),
                  ),
                )
              : ColoredBox(color: color),
    );
  }
}

/// 在 100 × 120 的逻辑坐标内绘制简化的服装剪影。
class GarmentShapePainter extends CustomPainter {
  GarmentShapePainter({
    required this.slot,
    required this.color,
    this.isSkirt = false,
  });

  final GarmentSlot slot;
  final Color color;
  final bool isSkirt;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 100, size.height / 120);
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 120 * scale) / 2,
    );
    canvas.scale(scale);

    final path = _buildPath();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    _paintDetails(canvas, path);
    canvas.restore();
  }

  Path _buildPath() {
    switch (slot) {
      case GarmentSlot.top:
        return Path()
          ..moveTo(31, 16)
          ..lineTo(43, 11)
          ..lineTo(50, 20)
          ..lineTo(57, 11)
          ..lineTo(69, 16)
          ..lineTo(82, 30)
          ..lineTo(73, 43)
          ..lineTo(66, 37)
          ..lineTo(66, 104)
          ..lineTo(34, 104)
          ..lineTo(34, 37)
          ..lineTo(27, 43)
          ..lineTo(18, 30)
          ..close();
      case GarmentSlot.outer:
        return Path()
          ..moveTo(32, 15)
          ..lineTo(44, 10)
          ..lineTo(50, 18)
          ..lineTo(56, 10)
          ..lineTo(68, 15)
          ..lineTo(82, 32)
          ..lineTo(73, 44)
          ..lineTo(66, 38)
          ..lineTo(70, 112)
          ..lineTo(30, 112)
          ..lineTo(34, 38)
          ..lineTo(27, 44)
          ..lineTo(18, 32)
          ..close();
      case GarmentSlot.bottom:
        if (isSkirt) {
          return Path()
            ..moveTo(32, 18)
            ..lineTo(68, 18)
            ..lineTo(84, 104)
            ..lineTo(16, 104)
            ..close();
        }
        return Path()
          ..moveTo(30, 16)
          ..lineTo(70, 16)
          ..lineTo(76, 106)
          ..lineTo(55, 106)
          ..lineTo(50, 48)
          ..lineTo(45, 106)
          ..lineTo(24, 106)
          ..close();
      case GarmentSlot.dress:
        return Path()
          ..moveTo(38, 12)
          ..lineTo(44, 12)
          ..lineTo(50, 24)
          ..lineTo(56, 12)
          ..lineTo(62, 12)
          ..lineTo(67, 36)
          ..lineTo(84, 106)
          ..lineTo(16, 106)
          ..lineTo(33, 36)
          ..close();
      case GarmentSlot.shoes:
        return Path()
          ..moveTo(14, 82)
          ..cubicTo(20, 64, 38, 62, 47, 74)
          ..lineTo(70, 80)
          ..cubicTo(84, 84, 87, 96, 78, 102)
          ..lineTo(22, 102)
          ..cubicTo(15, 98, 12, 90, 14, 82)
          ..close();
      case GarmentSlot.hat:
        return Path()
          ..moveTo(22, 76)
          ..cubicTo(26, 40, 44, 26, 57, 30)
          ..cubicTo(72, 34, 79, 52, 80, 76)
          ..close();
    }
  }

  void _paintDetails(Canvas canvas, Path path) {
    final line = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    switch (slot) {
      case GarmentSlot.top:
      case GarmentSlot.outer:
      case GarmentSlot.dress:
        // 领口：用底色椭圆暗示颈部开口。
        canvas.drawOval(
          const Rect.fromLTWH(43, 8, 14, 10),
          Paint()..color = _swatchBackground,
        );
        if (slot == GarmentSlot.outer) {
          canvas.drawLine(const Offset(50, 18), const Offset(50, 112), line);
        }
        if (slot == GarmentSlot.dress) {
          canvas.drawLine(const Offset(33, 40), const Offset(67, 40), line);
        }
        break;
      case GarmentSlot.bottom:
        if (isSkirt) {
          canvas.drawLine(const Offset(34, 30), const Offset(66, 30), line);
        } else {
          canvas.drawLine(const Offset(30, 28), const Offset(70, 28), line);
        }
        break;
      case GarmentSlot.shoes:
        canvas.drawLine(const Offset(18, 92), const Offset(80, 96), line);
        canvas.drawLine(const Offset(30, 76), const Offset(44, 88), line);
        break;
      case GarmentSlot.hat:
        canvas.drawLine(const Offset(18, 78), const Offset(86, 78), line);
        canvas.drawLine(const Offset(50, 30), const Offset(50, 76), line);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant GarmentShapePainter oldDelegate) =>
      slot != oldDelegate.slot ||
      color != oldDelegate.color ||
      isSkirt != oldDelegate.isSkirt;
}
