import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';

/// Emblema e isotipo oficial de FashionStyle Boutique & Atelier.
///
/// Representa el rombo de costura de alta gama, el gancho de sastrería
/// minimalista y el ancla artesanal de hilo en oro arena.
/// Vectorial, escalable e hipernítido en cualquier densidad de pantalla.
class FashionBrandEmblem extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color fillColor;
  final bool conSombra;

  const FashionBrandEmblem({
    super.key,
    this.size = 36,
    this.primaryColor = FashionColors.negro,
    this.secondaryColor = FashionColors.pizarra,
    this.accentColor = FashionColors.arenaOscura,
    this.fillColor = FashionColors.arenaSuave,
    this.conSombra = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: conSombra
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _FashionEmblemPainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          accentColor: accentColor,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class _FashionEmblemPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color fillColor;

  _FashionEmblemPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 160.0; // Sistema de coordenadas base de 160x160

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    // 1. Rombo exterior decorativo de costura artesanal (Oro Arena)
    final pathRomboExt = Path()
      ..moveTo(0, -68)
      ..lineTo(68, 0)
      ..lineTo(0, 68)
      ..lineTo(-68, 0)
      ..close();

    final paintRomboExt = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(pathRomboExt, paintRomboExt);

    // 2. Rombo interior con relleno suave crema/arena
    final pathRomboInt = Path()
      ..moveTo(0, -58)
      ..lineTo(58, 0)
      ..lineTo(0, 58)
      ..lineTo(-58, 0)
      ..close();

    final paintRelleno = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pathRomboInt, paintRelleno);

    final paintBordeInt = Paint()
      ..color = secondaryColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(pathRomboInt, paintBordeInt);

    // 3. Gancho de percha estilizado (Alta Costura) en negro ébano
    final pathGancho = Path()
      ..moveTo(0, -38)
      ..cubicTo(14, -38, 22, -28, 22, -18)
      ..cubicTo(22, -8, 12, -2, 0, 4);

    final paintGancho = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pathGancho, paintGancho);

    // 4. Base triangular de la percha / solapa
    final pathBase = Path()
      ..moveTo(0, 4)
      ..lineTo(-36, 25)
      ..lineTo(36, 25)
      ..close();

    final paintBase = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pathBase, paintBase);

    // 5. Aguja / punto ancla de sastrería central
    final paintPunto = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 40), 3.8, paintPunto);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FashionEmblemPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.fillColor != fillColor;
  }
}

/// Cabecera de marca con isotipo y tipografía editorial de lujo.
class FashionBrandHeader extends StatelessWidget {
  final double emblemSize;
  final bool compacto;
  final VoidCallback? onTap;

  const FashionBrandHeader({
    super.key,
    this.emblemSize = 32,
    this.compacto = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FashionBrandEmblem(
            size: emblemSize,
            conSombra: true,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FASHIONSTYLE',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: compacto ? 15 : 17,
                  letterSpacing: 2.2,
                  color: FashionColors.negro,
                  height: 1.1,
                ),
              ),
              Text(
                'BOUTIQUE & ATELIER',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: compacto ? 8 : 9,
                  letterSpacing: 2.0,
                  color: FashionColors.pizarra,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
