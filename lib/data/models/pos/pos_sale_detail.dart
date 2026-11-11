// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'dart:convert';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/payment/bank_account_config.dart';
import 'package:fashion_style_mobile/data/models/payment/parallel_payment_control.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_model.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sales_summary.dart';
import 'package:fashion_style_mobile/data/services/payment_config_service.dart';
import 'package:fashion_style_mobile/data/services/pos_sale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosSaleDetail {
  final int? id;
  final int? varianteId;
  final String nombre;
  final String talla;
  final String sku;
  final int cantidad;
  final double precio;
  final double subtotal;

  const PosSaleDetail({
    this.id,
    this.varianteId,
    required this.nombre,
    required this.talla,
    required this.sku,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory PosSaleDetail.fromJson(Map<String, dynamic> map) {
    final cantidad = JsonParser.toInt(map['cantidad']);
    final precio = JsonParser.toDouble(map['precio_unitario'] ?? map['precio']);

    final varMap = map['variante'] is Map<String, dynamic> ? map['variante'] as Map<String, dynamic> : null;
    final prodMap = map['producto'] is Map<String, dynamic>
        ? map['producto'] as Map<String, dynamic>
        : (varMap?['producto'] is Map<String, dynamic> ? varMap!['producto'] as Map<String, dynamic> : null);

    final nombre = JsonParser.toStr(
      varMap?['producto']?['nombre'] ?? prodMap?['nombre'] ?? map['nombre_producto'],
      'Prenda',
    );

    return PosSaleDetail(
      id: map['id'] != null ? JsonParser.toInt(map['id']) : null,
      varianteId: map['variante_id'] != null
          ? JsonParser.toInt(map['variante_id'])
          : (varMap?['id_variante'] != null ? JsonParser.toInt(varMap!['id_variante']) : null),
      nombre: nombre,
      talla: JsonParser.toStr(varMap?['talla'] ?? map['talla']),
      sku: JsonParser.toStr(varMap?['sku'] ?? map['sku']),
      cantidad: cantidad,
      precio: precio,
      subtotal: JsonParser.toDouble(map['subtotal'], cantidad * precio),
    );
  }
}
