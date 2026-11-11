// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class PosSalesSummary {
  final int ventasHoy;
  final double montoHoy;
  final double montoActivas;
  final Map<String, dynamic> porMedioPago;

  const PosSalesSummary({
    required this.ventasHoy,
    required this.montoHoy,
    required this.montoActivas,
    required this.porMedioPago,
  });

  factory PosSalesSummary.fromJson(Map<String, dynamic> map) {
    return PosSalesSummary(
      ventasHoy: JsonParser.toInt(map['ventas_hoy'] ?? map['total_ventas_hoy']),
      montoHoy: JsonParser.toDouble(map['monto_hoy'] ?? map['ingresos_hoy']),
      montoActivas: JsonParser.toDouble(map['monto_activas'] ?? map['total_activas']),
      porMedioPago: map['por_medio_pago'] is Map<String, dynamic>
          ? map['por_medio_pago'] as Map<String, dynamic>
          : (map['desglose_medios'] is Map<String, dynamic>
              ? map['desglose_medios'] as Map<String, dynamic>
              : (map['medios_pago'] is Map<String, dynamic> ? map['medios_pago'] as Map<String, dynamic> : {})),
    );
  }
}
