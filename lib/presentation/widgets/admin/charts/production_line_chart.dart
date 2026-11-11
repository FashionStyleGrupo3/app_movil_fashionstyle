// @source-mirror: src/components/admin/GraficoPanel.vue
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/dashboard/dashboard_models.dart';
import 'package:fashion_style_mobile/data/services/dashboard_service.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/chart_helpers.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/payment_method_doughnut_chart.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/stacked_bar_chart.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/stock_alerts_doughnut_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductionLineChartWidget extends StatelessWidget {
  final List<ProduccionPorMesItem> items;
  final Map<String, int> ordenesPorEstado;
  final double height;

  const ProductionLineChartWidget({
    super.key,
    required this.items,
    required this.ordenesPorEstado,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final tieneDatos = items.isNotEmpty && items.any((i) => i.planificadas > 0 || i.completadas > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: tieneDatos
              ? CustomPaint(
                  painter: _ProductionLineChartPainter(items: items),
                  size: Size.infinite,
                )
              : Center(
                  child: Text(
                    'Aún no hay datos de producción en este periodo.',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AdminPalette.textoMuted,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IndicadorLeyenda(
              color: AdminPalette.arena,
              etiqueta: 'Unidades planificadas',
              esPunto: true,
            ),
            const SizedBox(width: 16),
            IndicadorLeyenda(
              color: AdminPalette.negro,
              etiqueta: 'Unidades completadas',
              esPunto: true,
            ),
          ],
        ),
        if (ordenesPorEstado.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ordenesPorEstado.entries.map((entry) {
              const mapaNombres = {
                'planificada': 'Planificada',
                'en_proceso': 'En proceso',
                'pausada': 'Pausada',
                'completada': 'Completada',
                'cancelada': 'Cancelada',
              };
              final nombre = mapaNombres[entry.key] ?? entry.key;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminPalette.crema,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminPalette.arenaSuave),
                ),
                child: Text(
                  '$nombre: ${entry.value}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FashionColors.textoOscuro,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _ProductionLineChartPainter extends CustomPainter {
  final List<ProduccionPorMesItem> items;

  _ProductionLineChartPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 35;
    const double paddingRight = 15;
    const double paddingTop = 15;
    const double paddingBottom = 26;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    if (chartWidth <= 0 || chartHeight <= 0 || items.isEmpty) return;

    double maxVal = items.fold<double>(
      0.0,
      (acc, i) => math.max(acc, math.max(i.planificadas.toDouble(), i.completadas.toDouble())),
    );
    if (maxVal <= 0) maxVal = 10;
    maxVal = maxVal * 1.2;

    final gridPaint = Paint()
      ..color = AdminPalette.arenaSuave
      ..strokeWidth = 1;

    // Líneas guía horizontales
    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + chartHeight * (1 - (i / 3.0));
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final val = maxVal * (i / 3.0);
      final textSpan = TextSpan(
        text: formatearNumeroGrafico(val),
        style: GoogleFonts.montserrat(
          fontSize: 9,
          color: AdminPalette.textoMuted,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 6, y - tp.height / 2));
    }

    final n = items.length;
    final stepX = n > 1 ? chartWidth / (n - 1) : chartWidth;

    final List<Offset> puntosPlan = [];
    final List<Offset> puntosComp = [];

    final baseY = paddingTop + chartHeight;

    for (int i = 0; i < n; i++) {
      final x = n > 1 ? paddingLeft + (i * stepX) : paddingLeft + chartWidth / 2;
      final yPlan = baseY - (items[i].planificadas / maxVal) * chartHeight;
      final yComp = baseY - (items[i].completadas / maxVal) * chartHeight;

      puntosPlan.add(Offset(x, yPlan));
      puntosComp.add(Offset(x, yComp));

      // Etiqueta del mes
      final mesTexto = formatearNombreMesGrafico(items[i].mes);
      final mesSpan = TextSpan(
        text: mesTexto,
        style: GoogleFonts.montserrat(
          fontSize: 9,
          color: AdminPalette.textoMuted,
          fontWeight: FontWeight.w500,
        ),
      );
      final mesTp = TextPainter(
        text: mesSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      mesTp.paint(canvas, Offset(x - mesTp.width / 2, baseY + 6));
    }

    // Dibujar área suave bajo unidades planificadas
    if (puntosPlan.isNotEmpty) {
      final fillPath = Path()..moveTo(puntosPlan.first.dx, baseY);
      for (final p in puntosPlan) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(puntosPlan.last.dx, baseY);
      fillPath.close();

      final fillPaint = Paint()
        ..color = AdminPalette.arena.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Línea de Planificadas (Arena)
    _dibujarLineaYVertices(
      canvas: canvas,
      puntos: puntosPlan,
      color: AdminPalette.arena,
      grosor: 2.2,
      radioPunto: 3.5,
    );

    // Línea de Completadas (Negro)
    _dibujarLineaYVertices(
      canvas: canvas,
      puntos: puntosComp,
      color: AdminPalette.negro,
      grosor: 2.2,
      radioPunto: 3.5,
    );
  }

  void _dibujarLineaYVertices({
    required Canvas canvas,
    required List<Offset> puntos,
    required Color color,
    required double grosor,
    required double radioPunto,
  }) {
    if (puntos.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (int i = 1; i < puntos.length; i++) {
      path.lineTo(puntos[i].dx, puntos[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final innerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final p in puntos) {
      canvas.drawCircle(p, radioPunto, dotPaint);
      canvas.drawCircle(p, radioPunto * 0.5, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _ProductionLineChartPainter oldDelegate) => true;
}

// ============================================================================
// 4. STOCK ALERTS DOUGHNUT: ALERTAS AUTOMÁTICAS
// ============================================================================
