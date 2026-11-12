import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';

/// Tipos de ilustraciones de estado vacío para el sistema Neo-Atelier.
enum AtelierEmptyStateType {
  emptyBag,
  emptySearch,
  zeroStock,
}

/// Fondo decorativo con retícula técnica y puntadas sutiles de sastrería.
class AtelierPatternBackground extends StatelessWidget {
  final Widget child;
  final Color? colorFondo;
  final double opacidadReticula;

  const AtelierPatternBackground({
    super.key,
    required this.child,
    this.colorFondo,
    this.opacidadReticula = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AtelierPatternPainter(
        colorFondo: colorFondo ?? FashionColors.canvasBackground,
        opacidad: opacidadReticula,
      ),
      child: child,
    );
  }
}

class _AtelierPatternPainter extends CustomPainter {
  final Color colorFondo;
  final double opacidad;

  _AtelierPatternPainter({
    required this.colorFondo,
    required this.opacidad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = colorFondo;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = FashionColors.inkSecondary.withValues(alpha: opacidad)
      ..strokeWidth = 1.0;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Acentos diagonales de costura en intersecciones clave
    final stitchPaint = Paint()
      ..color = FashionColors.brandAccent.withValues(alpha: opacidad * 1.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (double x = step; x < size.width; x += step * 2) {
      for (double y = step; y < size.height; y += step * 2) {
        canvas.drawLine(Offset(x - 3, y - 3), Offset(x + 3, y + 3), stitchPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtelierPatternPainter oldDelegate) {
    return oldDelegate.colorFondo != colorFondo || oldDelegate.opacidad != opacidad;
  }
}

/// Monograma vectorial 'FS' dentro de un octágono sartorial con puntada diagonal Terracotta.
///
/// Implementación nativa de alta fidelidad de `assets/images/logo-fashionstyle-mobile.svg`.
class AtelierMonogram extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;

  const AtelierMonogram({
    super.key,
    this.size = 36,
    this.primaryColor = FashionColors.inkPrimary,
    this.accentColor = FashionColors.brandAccent,
    this.surfaceColor = FashionColors.surfaceCard,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _AtelierMonogramPainter(
          primaryColor: primaryColor,
          accentColor: accentColor,
          surfaceColor: surfaceColor,
        ),
      ),
    );
  }
}

class _AtelierMonogramPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color surfaceColor;

  _AtelierMonogramPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Octágono sartorial exterior
    final pathOctagon = Path()
      ..moveTo(29, 6)
      ..lineTo(71, 6)
      ..lineTo(94, 29)
      ..lineTo(94, 71)
      ..lineTo(71, 94)
      ..lineTo(29, 94)
      ..lineTo(6, 71)
      ..lineTo(6, 29)
      ..close();

    // Relleno superficie
    final fillPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pathOctagon, fillPaint);

    // Borde exterior
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pathOctagon, strokePaint);

    // 2. Monograma 'FS' geométrico interno
    final letterPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Columna vertical de 'F'
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 26, 7, 48), const Radius.circular(1.5)),
      letterPaint,
    );
    // Barra superior de 'F'
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 26, 22, 6.5), const Radius.circular(1.5)),
      letterPaint,
    );
    // Barra media de 'F'
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 44, 18, 6.5), const Radius.circular(1.5)),
      letterPaint,
    );

    // Letra 'S' sartorial entrelazada
    final pathS = Path()
      ..moveTo(52, 33)
      ..lineTo(72, 33)
      ..lineTo(72, 45)
      ..lineTo(54, 45)
      ..lineTo(54, 61)
      ..lineTo(74, 61)
      ..lineTo(74, 74)
      ..lineTo(50, 74)
      ..lineTo(50, 64)
      ..lineTo(67, 64)
      ..lineTo(67, 52)
      ..lineTo(50, 52)
      ..close();
    canvas.drawPath(pathS, letterPaint);

    // 3. Puntada diagonal Terracotta (#B83A24) de sastrería
    final stitchPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(18, 80), const Offset(82, 20), stitchPaint);

    // Nudos ancla en los extremos
    final knotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(18, 80), 2.2, knotPaint);
    canvas.drawCircle(const Offset(82, 20), 2.2, knotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AtelierMonogramPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

/// Ilustraciones vectoriales hipernítidas para estados vacíos de la aplicación.
class AtelierEmptyStateIllustration extends StatelessWidget {
  final AtelierEmptyStateType type;
  final double size;
  final String? title;
  final String? subtitle;

  const AtelierEmptyStateIllustration({
    super.key,
    required this.type,
    this.size = 140,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            size: Size(size, size),
            painter: _EmptyStatePainter(type: type),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: 16),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: FashionColors.inkPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: FashionColors.inkSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyStatePainter extends CustomPainter {
  final AtelierEmptyStateType type;

  _EmptyStatePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 140.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Fondo circular suave
    final circlePaint = Paint()
      ..color = FashionColors.surfaceMuted
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(70, 70), 62, circlePaint);

    final borderPaint = Paint()
      ..color = FashionColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(70, 70), 62, borderPaint);

    switch (type) {
      case AtelierEmptyStateType.emptyBag:
        _paintEmptyBag(canvas);
        break;
      case AtelierEmptyStateType.emptySearch:
        _paintEmptySearch(canvas);
        break;
      case AtelierEmptyStateType.zeroStock:
        _paintZeroStock(canvas);
        break;
    }

    canvas.restore();
  }

  void _paintEmptyBag(Canvas canvas) {
    // Carrito sartorial
    final bagPath = Path()
      ..moveTo(42, 54)
      ..lineTo(98, 54)
      ..lineTo(93, 104)
      ..lineTo(47, 104)
      ..close();

    final bagFill = Paint()..color = FashionColors.surfaceCard;
    canvas.drawPath(bagPath, bagFill);

    final bagStroke = Paint()
      ..color = FashionColors.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bagPath, bagStroke);

    // Asas del carrito
    final handlePath = Path()
      ..moveTo(55, 54)
      ..cubicTo(55, 34, 85, 34, 85, 54);

    final handleStroke = Paint()
      ..color = FashionColors.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(handlePath, handleStroke);

    // Puntada decorativa Terracotta
    final stitch = Paint()
      ..color = FashionColors.brandAccent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(48, 76), const Offset(92, 76), stitch);
  }

  void _paintEmptySearch(Canvas canvas) {
    // Lupa técnica con retícula de medidas
    final lensCenter = const Offset(64, 62);
    final lensRadius = 26.0;

    final lensFill = Paint()..color = FashionColors.surfaceCard;
    canvas.drawCircle(lensCenter, lensRadius, lensFill);

    final lensStroke = Paint()
      ..color = FashionColors.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(lensCenter, lensRadius, lensStroke);

    // Cruz interna de encuadre
    final crossPaint = Paint()
      ..color = FashionColors.borderSubtle
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(44, 62), const Offset(84, 62), crossPaint);
    canvas.drawLine(const Offset(64, 42), const Offset(64, 82), crossPaint);

    // Punto focal Terracotta
    final dotPaint = Paint()..color = FashionColors.brandAccent;
    canvas.drawCircle(lensCenter, 3.0, dotPaint);

    // Mango de la lupa
    final handleStroke = Paint()
      ..color = FashionColors.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(84, 82), const Offset(104, 102), handleStroke);
  }

  void _paintZeroStock(Canvas canvas) {
    // Bobina de hilo con hilo desenrollado
    final spoolBody = RRect.fromRectAndRadius(
      const Rect.fromLTWH(55, 48, 30, 44),
      const Radius.circular(4),
    );
    final spoolTop = RRect.fromRectAndRadius(
      const Rect.fromLTWH(48, 42, 44, 8),
      const Radius.circular(3),
    );
    final spoolBottom = RRect.fromRectAndRadius(
      const Rect.fromLTWH(48, 90, 44, 8),
      const Radius.circular(3),
    );

    final inkPaint = Paint()..color = FashionColors.inkPrimary;
    canvas.drawRRect(spoolTop, inkPaint);
    canvas.drawRRect(spoolBottom, inkPaint);

    final spoolFill = Paint()..color = FashionColors.surfaceCard;
    canvas.drawRRect(spoolBody, spoolFill);

    final spoolStroke = Paint()
      ..color = FashionColors.inkPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(spoolBody, spoolStroke);

    // Hilo desenrollado en Terracotta
    final threadPath = Path()
      ..moveTo(85, 70)
      ..cubicTo(100, 70, 95, 100, 110, 100);

    final threadPaint = Paint()
      ..color = FashionColors.brandAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(threadPath, threadPaint);
  }

  @override
  bool shouldRepaint(covariant _EmptyStatePainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
