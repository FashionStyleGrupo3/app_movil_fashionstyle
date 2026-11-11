// @source-mirror: src/components/admin/GraficoPanel.vue
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/data/models/dashboard/dashboard_models.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/chart_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class StackedBarChartWidget extends StatelessWidget {
  final List<VentasPorMesItem> items;
  final double height;

  const StackedBarChartWidget({
    super.key,
    required this.items,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final tieneDatos = items.isNotEmpty && items.any((i) => i.total > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: tieneDatos
              ? CustomPaint(
                  painter: _StackedBarChartPainter(items: items),
                  size: Size.infinite,
                )
              : Center(
                  child: Text(
                    'Aún no hay ventas registradas en este periodo.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AdminPalette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            IndicadorLeyenda(
              color: AdminPalette.inkPrimary,
              etiqueta: 'Tienda física (POS)',
            ),
            SizedBox(width: 16),
            IndicadorLeyenda(
              color: AdminPalette.brandAccent,
              etiqueta: 'Tienda en línea',
            ),
          ],
        ),
      ],
    );
  }
}

class _StackedBarChartPainter extends CustomPainter {
  final List<VentasPorMesItem> items;

  _StackedBarChartPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 48;
    const double paddingRight = 12;
    const double paddingTop = 15;
    const double paddingBottom = 26;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    if (chartWidth <= 0 || chartHeight <= 0 || items.isEmpty) return;

    // Calcular escala máxima con margen del 15%
    double maxVal = items.map((e) => e.total).reduce(math.max);
    if (maxVal <= 0) maxVal = 100000;
    maxVal = maxVal * 1.15;

    final gridPaint = Paint()
      ..color = AdminPalette.borderSubtle
      ..strokeWidth = 1;

    // Líneas de guía horizontales (4 niveles: 0%, 33%, 66%, 100%)
    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + chartHeight * (1 - (i / 3.0));
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final val = maxVal * (i / 3.0);
      final textSpan = TextSpan(
        text: '\$${formatearNumeroGrafico(val)}',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          color: AdminPalette.textMuted,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 6, y - tp.height / 2));
    }

    // Dibujar barras apiladas
    final n = items.length;
    final slotWidth = chartWidth / n;
    final barWidth = math.min(28.0, slotWidth * 0.55);

    final posPaint = Paint()
      ..color = AdminPalette.inkPrimary
      ..style = PaintingStyle.fill;

    final webPaint = Paint()
      ..color = AdminPalette.brandAccent
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final item = items[i];
      final centerX = paddingLeft + (i * slotWidth) + (slotWidth / 2);
      final left = centerX - barWidth / 2;
      final right = centerX + barWidth / 2;

      final posHeight = (item.pos / maxVal) * chartHeight;
      final webHeight = (item.web / maxVal) * chartHeight;
      final baseY = paddingTop + chartHeight;

      // Barra POS (inferior)
      if (posHeight > 0) {
        final posTop = baseY - posHeight;
        final rectPos = RRect.fromRectAndCorners(
          Rect.fromLTRB(left, posTop, right, baseY),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
          topLeft: webHeight <= 0 ? const Radius.circular(5) : Radius.zero,
          topRight: webHeight <= 0 ? const Radius.circular(5) : Radius.zero,
        );
        canvas.drawRRect(rectPos, posPaint);
      }

      // Barra Web (superior apilada)
      if (webHeight > 0) {
        final webBottom = baseY - posHeight;
        final webTop = webBottom - webHeight;
        final rectWeb = RRect.fromRectAndCorners(
          Rect.fromLTRB(left, webTop, right, webBottom),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
          bottomLeft: posHeight <= 0 ? const Radius.circular(4) : Radius.zero,
          bottomRight: posHeight <= 0 ? const Radius.circular(4) : Radius.zero,
        );
        canvas.drawRRect(rectWeb, webPaint);
      }

      // Etiqueta del mes en el eje X
      final mesTexto = formatearNombreMesGrafico(item.mes);
      final mesSpan = TextSpan(
        text: mesTexto,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.5,
          color: AdminPalette.textMuted,
          fontWeight: FontWeight.w600,
        ),
      );
      final mesTp = TextPainter(
        text: mesSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      mesTp.paint(canvas, Offset(centerX - mesTp.width / 2, baseY + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarChartPainter oldDelegate) => true;
}
