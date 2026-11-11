// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class ProductVariant {
  final int idVariante;
  final String talla;
  final String sku;
  final double precioVenta;
  final double precioOriginal;
  final int stock;

  const ProductVariant({
    required this.idVariante,
    required this.talla,
    required this.sku,
    required this.precioVenta,
    required this.precioOriginal,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id_variante'] ?? map['id']);
    final talla = JsonParser.toStr(map['talla']);
    final sku = JsonParser.toStr(map['sku']);
    final precioVenta = JsonParser.toDouble(map['precio_venta'] ?? map['precio']);
    final precioOriginal = JsonParser.toDouble(
      map['precio_original'] ?? map['precio_venta'] ?? map['precio'],
      precioVenta,
    );
    final stock = JsonParser.toInt(map['stock']);

    return ProductVariant(
      idVariante: id,
      talla: talla,
      sku: sku,
      precioVenta: precioVenta,
      precioOriginal: precioOriginal,
      stock: stock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_variante': idVariante,
      'talla': talla,
      'sku': sku,
      'precio_venta': precioVenta,
      'precio_original': precioOriginal,
      'stock': stock,
    };
  }
}
