// @source-mirror: src/components/admin/GraficoPanel.vue
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/data/models/dashboard/dashboard_models.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/charts/chart_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

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
              IndicadorLeyenda(
                color: AdminPalette.statusDanger,
                etiqueta: 'Agotado: $agotado',
              ),
              const SizedBox(width: 12),
              IndicadorLeyenda(
                color: AdminPalette.editorialOchre,
                etiqueta: 'Crítico: $critico',
              ),
              const SizedBox(width: 12),
              IndicadorLeyenda(
                color: AdminPalette.inkPrimary,
                etiqueta: 'Bajo: $bajo',
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminPalette.statusSuccess.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminPalette.statusSuccess.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AdminPalette.statusSuccess, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sin alertas de stock pendientes.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.statusSuccess,
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
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AdminPalette.inkPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(5, menorStock.length),
            separatorBuilder: (_, __) => const Divider(height: 8, color: AdminPalette.borderSubtle),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AdminPalette.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: esCritico ? AdminPalette.statusDanger.withValues(alpha: 0.12) : AdminPalette.mineralSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: esCritico ? AdminPalette.statusDanger.withValues(alpha: 0.3) : AdminPalette.borderSubtle),
                      ),
                      child: Text(
                        '${item.stock} un.',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: esCritico ? AdminPalette.statusDanger : AdminPalette.inkPrimary,
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdminPalette.editorialOchre,
            ),
          ),
        ],
      ],
    );
  }
}

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
      MapEntry(agotado, AdminPalette.statusDanger),
      MapEntry(critico, AdminPalette.editorialOchre),
      MapEntry(bajo, AdminPalette.inkPrimary),
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

    // Texto central con JetBrains Mono + Plus Jakarta Sans
    final textSpan = TextSpan(
      text: '$total\n',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AdminPalette.inkPrimary,
      ),
      children: [
        TextSpan(
          text: total == 1 ? 'Alerta' : 'Alertas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AdminPalette.textMuted,
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
