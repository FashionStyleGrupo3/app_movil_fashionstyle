// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class ParallelPaymentControl {
  final double recaudoWompiOnline;
  final int cantidadPedidosPagados;
  final double recaudoPosMostrador;
  final int cantidadVentasPos;
  final double recaudoTotalConsolidado;
  final int facturasEmitidas;
  final List<dynamic> transacciones;

  const ParallelPaymentControl({
    required this.recaudoWompiOnline,
    required this.cantidadPedidosPagados,
    required this.recaudoPosMostrador,
    required this.cantidadVentasPos,
    required this.recaudoTotalConsolidado,
    required this.facturasEmitidas,
    required this.transacciones,
  });

  factory ParallelPaymentControl.fromJson(Map<String, dynamic> map) {
    return ParallelPaymentControl(
      recaudoWompiOnline: JsonParser.toDouble(map['recaudo_wompi_online']),
      cantidadPedidosPagados: JsonParser.toInt(map['cantidad_pedidos_pagados']),
      recaudoPosMostrador: JsonParser.toDouble(map['recaudo_pos_mostrador']),
      cantidadVentasPos: JsonParser.toInt(map['cantidad_ventas_pos']),
      recaudoTotalConsolidado: JsonParser.toDouble(map['recaudo_total_consolidado']),
      facturasEmitidas: JsonParser.toInt(map['facturas_emitidas']),
      transacciones: map['transacciones'] is List ? map['transacciones'] as List : [],
    );
  }
}
