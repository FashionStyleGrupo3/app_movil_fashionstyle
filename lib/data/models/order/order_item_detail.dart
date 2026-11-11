// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';

class OrderItemDetail {
  final int? id;
  final int? productoId;
  final int? varianteId;
  final String nombre;
  final String imagen;
  final String talla;
  final String sku;
  final int cantidad;
  final double precio;
  final double subtotal;

  const OrderItemDetail({
    this.id,
    this.productoId,
    this.varianteId,
    required this.nombre,
    required this.imagen,
    required this.talla,
    required this.sku,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> map) {
    final cantidad = JsonParser.toInt(map['cantidad']);
    final precio = JsonParser.toDouble(map['precio_unitario'] ?? map['precio']);

    final prodMap = map['producto'] is Map<String, dynamic> ? map['producto'] as Map<String, dynamic> : null;
    final varMap = map['variante'] is Map<String, dynamic> ? map['variante'] as Map<String, dynamic> : null;
    final varProdMap = varMap?['producto'] is Map<String, dynamic> ? varMap!['producto'] as Map<String, dynamic> : null;

    final rawImgs = prodMap?['imagenes'] ?? varProdMap?['imagenes'] ?? [];
    dynamic principalImg;
    if (rawImgs is List && rawImgs.isNotEmpty) {
      principalImg = rawImgs.firstWhere(
        (img) => img is Map && JsonParser.toBool(img['es_principal']),
        orElse: () => rawImgs.first,
      );
    }

    final nombre = JsonParser.toStr(
      varProdMap?['nombre'] ?? prodMap?['nombre'] ?? map['nombre_producto'],
      'Prenda',
    );

    return OrderItemDetail(
      id: map['id'] != null ? JsonParser.toInt(map['id']) : null,
      productoId: map['producto_id'] != null
          ? JsonParser.toInt(map['producto_id'])
          : (prodMap?['id_producto'] != null ? JsonParser.toInt(prodMap!['id_producto']) : null),
      varianteId: map['producto_variante_id'] != null
          ? JsonParser.toInt(map['producto_variante_id'])
          : (varMap?['id_variante'] != null ? JsonParser.toInt(varMap!['id_variante']) : null),
      nombre: nombre,
      imagen: ImageUrlResolver.resolve(principalImg ?? map['imagen']),
      talla: JsonParser.toStr(varMap?['talla'] ?? map['talla']),
      sku: JsonParser.toStr(varMap?['sku'] ?? map['sku']),
      cantidad: cantidad,
      precio: precio,
      subtotal: JsonParser.toDouble(map['subtotal'], cantidad * precio),
    );
  }
}
