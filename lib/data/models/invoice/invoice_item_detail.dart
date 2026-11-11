// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class InvoiceItemDetail {
  final String descripcion;
  final String talla;
  final int cantidad;
  final double precio;
  final double subtotal;

  const InvoiceItemDetail({
    required this.descripcion,
    required this.talla,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory InvoiceItemDetail.fromJson(Map<String, dynamic> map) {
    final cantidad = JsonParser.toInt(map['cantidad']);
    final precio = JsonParser.toDouble(map['precio_unitario'] ?? map['precio']);

    final varMap = map['variante'] is Map<String, dynamic> ? map['variante'] as Map<String, dynamic> : null;
    final prodMap = map['producto'] is Map<String, dynamic>
        ? map['producto'] as Map<String, dynamic>
        : (varMap?['producto'] is Map<String, dynamic> ? varMap!['producto'] as Map<String, dynamic> : null);

    final desc = JsonParser.toStr(
      map['descripcion'] ?? prodMap?['nombre'] ?? map['nombre_producto'],
      'Prenda',
    );

    return InvoiceItemDetail(
      descripcion: desc,
      talla: JsonParser.toStr(varMap?['talla'] ?? map['talla']),
      cantidad: cantidad,
      precio: precio,
      subtotal: JsonParser.toDouble(map['subtotal'], cantidad * precio),
    );
  }
}
