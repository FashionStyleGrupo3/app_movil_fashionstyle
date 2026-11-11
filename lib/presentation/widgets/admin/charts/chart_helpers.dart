// @source-mirror: src/components/admin/GraficoPanel.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta visual Neo-Atelier Mineral & Terracotta para analítica y métricas móvil
class AdminPalette {
  static const Color inkPrimary = FashionColors.inkPrimary; // #14161F
  static const Color brandAccent = FashionColors.brandAccent; // #B83A24
  static const Color atelierJade = FashionColors.atelierJade; // #115E59
  static const Color editorialOchre = FashionColors.editorialOchre; // #9A6700
  static const Color statusSuccess = FashionColors.statusSuccess; // #157347
  static const Color statusDanger = FashionColors.statusDanger; // #C92A2A
  static const Color borderSubtle = FashionColors.borderSubtle; // #DFE3EC
  static const Color mineralSurface = FashionColors.canvasBackground; // #F6F7F9
  static const Color surfaceCard = FashionColors.surfaceCard; // #FFFFFF
  static const Color textMuted = FashionColors.inkSecondary; // #525866
  static const Color textSecondary = FashionColors.inkPrimary; // #14161F

  // Alias semánticos para compatibilidad con widgets existentes
  static const Color negro = FashionColors.inkPrimary;
  static const Color pizarra = FashionColors.inkPrimary;
  static const Color arena = FashionColors.brandAccent;
  static const Color arenaSuave = FashionColors.borderSubtle;
  static const Color crema = FashionColors.canvasBackground;
  static const Color rojo = FashionColors.statusDanger;
  static const Color ambar = FashionColors.editorialOchre;
  static const Color verde = FashionColors.statusSuccess;
  static const Color textoMuted = FashionColors.inkSecondary;
}

String formatearNombreMesGrafico(String claveMes) {
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

String formatearNumeroGrafico(num valor) {
  if (valor >= 1000000) {
    return '${(valor / 1000000).toStringAsFixed(1)}M';
  } else if (valor >= 1000) {
    return '${(valor / 1000).toStringAsFixed(0)}k';
  }
  return valor.toStringAsFixed(0);
}

// ============================================================================
// LEYENDAS Y UTILIDADES DE GRÁFICOS
// ============================================================================

typedef VoidToCallback = void Function();

/// Indicador reutilizable para las leyendas de gráficos con tipografía Plus Jakarta Sans
class IndicadorLeyenda extends StatelessWidget {
  final Color color;
  final String etiqueta;
  final bool esPunto;

  const IndicadorLeyenda({
    super.key,
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
            borderRadius: esPunto ? null : BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          etiqueta,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AdminPalette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
