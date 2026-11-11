// @source-mirror: src/components/admin/GraficoPanel.vue
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
// 1. STACKED BAR CHART: VENTAS POR MES (POS vs Web)
// ============================================================================

typedef VoidToCallback = void Function();

// Indicador reutilizable para las leyendas de gráficos
class IndicadorLeyenda extends StatelessWidget {
  final Color color;
  final String etiqueta;
  final bool esPunto;

  const IndicadorLeyenda({super.key, 
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
