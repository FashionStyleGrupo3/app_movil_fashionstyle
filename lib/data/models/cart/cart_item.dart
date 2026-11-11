// @source-mirror: src/stores/carrito.js
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final int productoId;
  final String nombre;
  final String imagen;
  final int varianteId;
  final String talla;
  final String sku;
  final double precio;
  final double precioOriginal;
  final int stockMaximo;
  final int cantidad;
  final int? categoriaId;
  final int? catalogoId;

  const CartItem({
    required this.productoId,
    required this.nombre,
    required this.imagen,
    required this.varianteId,
    required this.talla,
    required this.sku,
    required this.precio,
    required this.precioOriginal,
    required this.stockMaximo,
    required this.cantidad,
    this.categoriaId,
    this.catalogoId,
  });

  factory CartItem.fromJson(Map<String, dynamic> map) {
    return CartItem(
      productoId: JsonParser.toInt(map['productoId'] ?? map['producto_id']),
      nombre: JsonParser.toStr(map['nombre']),
      imagen: JsonParser.toStr(map['imagen']),
      varianteId: JsonParser.toInt(map['varianteId'] ?? map['variante_id']),
      talla: JsonParser.toStr(map['talla']),
      sku: JsonParser.toStr(map['sku']),
      precio: JsonParser.toDouble(map['precio']),
      precioOriginal: JsonParser.toDouble(map['precioOriginal'] ?? map['precio_original'], JsonParser.toDouble(map['precio'])),
      stockMaximo: JsonParser.toInt(map['stockMaximo'] ?? map['stock_maximo']),
      cantidad: JsonParser.toInt(map['cantidad'], 1),
      categoriaId: map['categoriaId'] != null ? JsonParser.toInt(map['categoriaId']) : null,
      catalogoId: map['catalogoId'] != null ? JsonParser.toInt(map['catalogoId']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'imagen': imagen,
      'varianteId': varianteId,
      'talla': talla,
      'sku': sku,
      'precio': precio,
      'precioOriginal': precioOriginal,
      'stockMaximo': stockMaximo,
      'cantidad': cantidad,
      'categoriaId': categoriaId,
      'catalogoId': catalogoId,
    };
  }

  CartItem copyWith({
    int? cantidad,
    double? precio,
    double? precioOriginal,
    int? stockMaximo,
  }) {
    return CartItem(
      productoId: productoId,
      nombre: nombre,
      imagen: imagen,
      varianteId: varianteId,
      talla: talla,
      sku: sku,
      precio: precio ?? this.precio,
      precioOriginal: precioOriginal ?? this.precioOriginal,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      cantidad: cantidad ?? this.cantidad,
      categoriaId: categoriaId,
      catalogoId: catalogoId,
    );
  }
}
