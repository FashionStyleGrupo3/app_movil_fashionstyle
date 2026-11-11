// @source-mirror: src/components/admin/GraficoPanel.vue
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/dashboard/dashboard_models.dart';
import 'package:fashion_style_mobile/data/services/dashboard_service.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/chart_helpers.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/production_line_chart.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/stacked_bar_chart.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/stock_alerts_doughnut_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodDoughnutChartWidget extends StatelessWidget {
  final List<VentasPorMedioItem> items;
  final double height;

  const PaymentMethodDoughnutChartWidget({
    super.key,
    required this.items,
    this.height = 200,
  });

  static const List<Color> _colores = [
    AdminPalette.negro,
    AdminPalette.pizarra,
    AdminPalette.arena,
    AdminPalette.verde,
    AdminPalette.ambar,
    Color(0xFF8B949E),
  ];

  @override
  Widget build(BuildContext context) {
    final validos = items.where((i) => i.monto > 0).toList();
    final tieneDatos = validos.isNotEmpty;
    final totalMonto = validos.fold<double>(0.0, (acc, i) => acc + i.monto);

    if (!tieneDatos) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Aún no hay ventas en este periodo.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AdminPalette.textoMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _DoughnutChartPainter(
              items: validos,
              colores: _colores,
              total: totalMonto,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(validos.length, (idx) {
            final item = validos[idx];
            final color = _colores[idx % _colores.length];
            final pct = totalMonto > 0 ? (item.monto / totalMonto * 100).round() : 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AdminPalette.crema,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AdminPalette.arenaSuave),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.medio}: ',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.negro,
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.formatearCOP(item.monto)} ($pct%)',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AdminPalette.textoMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DoughnutChartPainter extends CustomPainter {
  final List<VentasPorMedioItem> items;
  final List<Color> colores;
  final double total;

  _DoughnutChartPainter({
    required this.items,
    required this.colores,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 26.0;
    final arcRadius = outerRadius - (strokeWidth / 2);

    final rect = Rect.fromCircle(center: center, radius: arcRadius);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final sweepAngle = (item.monto / total) * 2 * math.pi;
      final color = colores[i % colores.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Separadores blancos finos entre rebanadas
    if (items.length > 1) {
      double cutAngle = -math.pi / 2;
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final item in items) {
        final p1 = Offset(
          center.dx + (outerRadius - strokeWidth) * math.cos(cutAngle),
          center.dy + (outerRadius - strokeWidth) * math.sin(cutAngle),
        );
        final p2 = Offset(
          center.dx + outerRadius * math.cos(cutAngle),
          center.dy + outerRadius * math.sin(cutAngle),
        );
        canvas.drawLine(p1, p2, borderPaint);
        cutAngle += (item.monto / total) * 2 * math.pi;
      }
    }

    // Texto central en el cutout del donut
    final totalSpan = TextSpan(
      text: 'TOTAL\n',
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AdminPalette.textoMuted,
        letterSpacing: 0.5,
      ),
      children: [
        TextSpan(
          text: CurrencyFormatter.formatearCOP(total),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AdminPalette.negro,
          ),
        ),
      ],
    );
    final tp = TextPainter(
      text: totalSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: outerRadius * 1.3);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DoughnutChartPainter oldDelegate) => true;
}

// ============================================================================
// 3. DUAL LINE CHART: PRODUCCIÓN (Planificadas vs Completadas)
// ============================================================================
