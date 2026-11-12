// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class ProductVariant {
  final int idVariante;
  final String talla;
  final String sku;
  final double precioVenta;
  final double precioOriginal;
  final int stock;

  int get id => idVariante;

  const ProductVariant({
    required this.idVariante,
    required this.talla,
    required this.sku,
    required this.precioVenta,
    required this.precioOriginal,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(
      map['id_variante'] ?? map['id'] ?? map['variante_id'] ?? map['producto_variante_id'],
    );
    final dynamic rawTalla = map['talla'] ?? map['talla_nombre'] ?? map['nombre_talla'];
    final talla = rawTalla is Map
        ? JsonParser.toStr(rawTalla['talla'] ?? rawTalla['nombre'])
        : JsonParser.toStr(rawTalla);
    final sku = JsonParser.toStr(map['sku']);
    final precioVenta = JsonParser.toDouble(
      map['precio_venta'] ?? map['precio'] ?? map['precio_base'] ?? map['precio_unitario'],
    );
    final precioOriginal = JsonParser.toDouble(
      map['precio_original'] ?? map['precio_venta'] ?? map['precio'],
      precioVenta,
    );
    final stock = JsonParser.toInt(
      map['stock'] ??
          map['disponible'] ??
          map['cantidad'] ??
          map['inventario'] ??
          map['stock_actual'] ??
          map['cantidad_disponible'] ??
          map['stock_total'],
    );

    return ProductVariant(
      idVariante: id,
      talla: talla.isNotEmpty ? talla : 'U',
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
