// @source-mirror: src/components/admin/GraficoPanel.vue
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/dashboard_service.dart';

// Paleta visual neutral y de lujo alineada 100% con la Web
class AdminPalette {
  static const Color negro = Color(0xFF111111);
  static const Color pizarra = Color(0xFF56657A);
  static const Color arena = Color(0xFFD4C2A8);
  static const Color arenaSuave = Color(0xFFECE5DA);
  static const Color crema = Color(0xFFF7F4EF);
  static const Color rojo = Color(0xFFD9434B);
  static const Color ambar = Color(0xFFC08A2B);
  static const Color verde = Color(0xFF3F7D5C);
  static const Color textoMuted = Color(0xFF6F6F6F);
}

String _formatearNombreMes(String claveMes) {
  if (claveMes.isEmpty) return '';
  final partes = claveMes.split('-');
  if (partes.length < 2) return claveMes;
  final anio = int.tryParse(partes[0]) ?? 2026;
  final mes = int.tryParse(partes[1]) ?? 1;
  const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  final mesNom = (mes >= 1 && mes <= 12) ? meses[mes - 1] : '$mes';
  final anioCorto = anio.toString().length >= 4 ? anio.toString().substring(2) : '$anio';
  return '$mesNom $anioCorto';
}

String _formatearNumero(num valor) {
  if (valor >= 1000000) {
    return '${(valor / 1000000).toStringAsFixed(1)}M';
  } else if (valor >= 1000) {
    return '${(valor / 1000).toStringAsFixed(0)}k';
  }
  return valor.toStringAsFixed(0);
}

// ============================================================================
// 1. STACKED BAR CHART: VENTAS POR MES (POS vs Web)
// ============================================================================

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
            _IndicadorLeyenda(
              color: AdminPalette.pizarra,
              etiqueta: 'Tienda física (POS)',
            ),
            const SizedBox(width: 16),
            _IndicadorLeyenda(
              color: AdminPalette.arena,
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
    const double paddingLeft = 45;
    const double paddingRight = 12;
    const double paddingTop = 15;
    const double paddingBottom = 26;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    if (chartWidth <= 0 || chartHeight <= 0 || items.isEmpty) return;

    // Calcular escala máxima con margen del 10%
    double maxVal = items.map((e) => e.total).reduce(math.max);
    if (maxVal <= 0) maxVal = 100000;
    maxVal = maxVal * 1.15;

    final gridPaint = Paint()
      ..color = AdminPalette.arenaSuave
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
        text: '\$${_formatearNumero(val)}',
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

    // Dibujar barras apiladas
    final n = items.length;
    final slotWidth = chartWidth / n;
    final barWidth = math.min(28.0, slotWidth * 0.55);

    final posPaint = Paint()
      ..color = AdminPalette.pizarra
      ..style = PaintingStyle.fill;

    final webPaint = Paint()
      ..color = AdminPalette.arena
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
          bottomLeft: const Radius.circular(3),
          bottomRight: const Radius.circular(3),
          topLeft: webHeight <= 0 ? const Radius.circular(4) : Radius.zero,
          topRight: webHeight <= 0 ? const Radius.circular(4) : Radius.zero,
        );
        canvas.drawRRect(rectPos, posPaint);
      }

      // Barra Web (superior apilada)
      if (webHeight > 0) {
        final webBottom = baseY - posHeight;
        final webTop = webBottom - webHeight;
        final rectWeb = RRect.fromRectAndCorners(
          Rect.fromLTRB(left, webTop, right, webBottom),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
          bottomLeft: posHeight <= 0 ? const Radius.circular(3) : Radius.zero,
          bottomRight: posHeight <= 0 ? const Radius.circular(3) : Radius.zero,
        );
        canvas.drawRRect(rectWeb, webPaint);
      }

      // Etiqueta del mes en el eje X
      final mesTexto = _formatearNombreMes(item.mes);
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
      mesTp.paint(canvas, Offset(centerX - mesTp.width / 2, baseY + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarChartPainter oldDelegate) => true;
}

// ============================================================================
// 2. DOUGHNUT CHART: VENTAS POR MEDIO DE PAGO
// ============================================================================

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
            _IndicadorLeyenda(
              color: AdminPalette.arena,
              etiqueta: 'Unidades planificadas',
              esPunto: true,
            ),
            const SizedBox(width: 16),
            _IndicadorLeyenda(
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
        text: _formatearNumero(val),
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
      final mesTexto = _formatearNombreMes(items[i].mes);
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

class StockAlertsDoughnutWidget extends StatelessWidget {
  final Map<String, int> alertasPorNivel;
  final List<InventarioMenorStockItem> menorStock;
  final int materiasBajoMinimo;
  final VoidToCallback? onVerKardex;
  final double height;

  const StockAlertsDoughnutWidget({
    super.key,
    required this.alertasPorNivel,
    required this.menorStock,
    required this.materiasBajoMinimo,
    this.onVerKardex,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    final agotado = alertasPorNivel['AGOTADO'] ?? 0;
    final critico = alertasPorNivel['CRITICO'] ?? 0;
    final bajo = alertasPorNivel['BAJO'] ?? 0;
    final total = agotado + critico + bajo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total > 0) ...[
          SizedBox(
            height: height,
            child: CustomPaint(
              painter: _StockAlertsPainter(
                agotado: agotado,
                critico: critico,
                bajo: bajo,
                total: total,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IndicadorLeyenda(
                color: AdminPalette.rojo,
                etiqueta: 'Agotado: $agotado',
              ),
              const SizedBox(width: 12),
              _IndicadorLeyenda(
                color: AdminPalette.ambar,
                etiqueta: 'Crítico: $critico',
              ),
              const SizedBox(width: 12),
              _IndicadorLeyenda(
                color: AdminPalette.pizarra,
                etiqueta: 'Bajo: $bajo',
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminPalette.verde.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminPalette.verde.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AdminPalette.verde, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sin alertas de stock pendientes.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.verde,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (menorStock.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Prendas con menor stock',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminPalette.negro,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(5, menorStock.length),
            separatorBuilder: (_, __) => const Divider(height: 8, color: AdminPalette.arenaSuave),
            itemBuilder: (context, index) {
              final item = menorStock[index];
              final esCritico = item.stock <= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.producto} · Talla ${item.talla}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: FashionColors.textoOscuro,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: esCritico ? AdminPalette.rojo.withValues(alpha: 0.12) : AdminPalette.crema,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.stock} un.',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: esCritico ? AdminPalette.rojo : AdminPalette.negro,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        if (materiasBajoMinimo > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Materias primas bajo su mínimo: $materiasBajoMinimo',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdminPalette.ambar,
            ),
          ),
        ],
      ],
    );
  }
}

typedef VoidToCallback = void Function();

class _StockAlertsPainter extends CustomPainter {
  final int agotado;
  final int critico;
  final int bajo;
  final int total;

  _StockAlertsPainter({
    required this.agotado,
    required this.critico,
    required this.bajo,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 6;
    const strokeWidth = 22.0;
    final arcRadius = outerRadius - (strokeWidth / 2);

    final rect = Rect.fromCircle(center: center, radius: arcRadius);

    final slices = [
      MapEntry(agotado, AdminPalette.rojo),
      MapEntry(critico, AdminPalette.ambar),
      MapEntry(bajo, AdminPalette.pizarra),
    ].where((e) => e.key > 0).toList();

    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.key / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.value
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Texto central
    final textSpan = TextSpan(
      text: '$total\n',
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AdminPalette.negro,
      ),
      children: [
        TextSpan(
          text: total == 1 ? 'Alerta' : 'Alertas',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AdminPalette.textoMuted,
          ),
        ),
      ],
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StockAlertsPainter oldDelegate) => true;
}

// Indicador reutilizable para las leyendas de gráficos
class _IndicadorLeyenda extends StatelessWidget {
  final Color color;
  final String etiqueta;
  final bool esPunto;

  const _IndicadorLeyenda({
    required this.color,
    required this.etiqueta,
    this.esPunto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: esPunto ? 8 : 10,
          height: esPunto ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: esPunto ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: esPunto ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          etiqueta,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: AdminPalette.textoMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
