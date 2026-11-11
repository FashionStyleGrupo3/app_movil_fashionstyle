// @source-mirror: src/services/productoServicio.js, src/services/promocionServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/utils/image_url_resolver.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';

class Product {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final String color;
  final bool activo;
  final bool publicado;
  final int? categoriaId;
  final int? catalogoId;
  final Category? categoria;
  final Catalog? catalogo;
  final List<ProductImage> imagenes;
  final List<ProductVariant> variantes;
  final double? precioFinalBackend;
  final Map<String, dynamic> original;

  const Product({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.color,
    required this.activo,
    this.publicado = true,
    this.categoriaId,
    this.catalogoId,
    this.categoria,
    this.catalogo,
    required this.imagenes,
    required this.variantes,
    this.precioFinalBackend,
    required this.original,
  });

  factory Product.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id_producto'] ?? map['id']);
    final nombre = JsonParser.toStr(map['nombre']);
    final descripcion = JsonParser.toStr(map['descripcion']);
    final color = JsonParser.toStr(map['color']);
    final activo = map['activo'] == null ? true : JsonParser.toBool(map['activo']);
    final publicado = map['publicado'] == null ? true : JsonParser.toBool(map['publicado']);

    final catMap = map['categoria'] is Map<String, dynamic> ? map['categoria'] as Map<String, dynamic> : null;
    final rawCatId = map['id_categoria'] ?? map['categoria_id'] ?? catMap?['id_categoria'] ?? catMap?['id'];
    final categoriaId = rawCatId != null ? JsonParser.toInt(rawCatId) : null;

    final colMap = map['catalogo'] is Map<String, dynamic> ? map['catalogo'] as Map<String, dynamic> : null;
    final rawColId = map['id_catalogo'] ?? map['catalogo_id'] ?? colMap?['id_catalogo'] ?? colMap?['id'];
    final catalogoId = rawColId != null ? JsonParser.toInt(rawColId) : null;

    final categoria = catMap != null ? Category.fromJson(catMap) : null;
    final catalogo = colMap != null ? Catalog.fromJson(colMap) : null;

    final List<ProductImage> imagenes = [];
    final rawImgs = map['imagenes'] ?? map['fotos'];
    if (rawImgs is List) {
      for (final img in rawImgs) {
        if (img is Map<String, dynamic>) {
          imagenes.add(ProductImage.fromJson(img));
        }
      }
    }

    final List<ProductVariant> variantes = [];
    final rawVars = map['variantes'] ?? map['tallas'];
    if (rawVars is List) {
      for (final v in rawVars) {
        if (v is Map<String, dynamic>) {
          variantes.add(ProductVariant.fromJson(v));
        }
      }
    }

    final rawPrecioFinal = map['precio_final'] ?? map['precio_con_descuento'];
    final precioFinalBackend = rawPrecioFinal != null ? JsonParser.toDouble(rawPrecioFinal) : null;

    return Product(
      idProducto: id,
      nombre: nombre,
      descripcion: descripcion,
      color: color,
      activo: activo,
      publicado: publicado,
      categoriaId: categoriaId != null && categoriaId > 0 ? categoriaId : null,
      catalogoId: catalogoId != null && catalogoId > 0 ? catalogoId : null,
      categoria: categoria,
      catalogo: catalogo,
      imagenes: imagenes,
      variantes: variantes,
      precioFinalBackend: precioFinalBackend,
      original: map,
    );
  }

  String get primeraImagenUrl {
    if (imagenes.isEmpty) {
      final fallbackImg = original['imagen'] ?? original['foto'] ?? original['url'];
      return fallbackImg != null ? ImageUrlResolver.resolve(fallbackImg) : '';
    }
    final principal = imagenes.firstWhere(
      (img) => img.esPrincipal,
      orElse: () => imagenes.first,
    );
    return principal.urlResuelta;
  }

  double get precioMinimo {
    if (variantes.isEmpty) {
      return JsonParser.toDouble(original['precio_venta'] ?? original['precio_base'] ?? original['precio']);
    }
    double min = variantes.first.precioVenta;
    for (final v in variantes) {
      if (v.precioVenta < min && v.precioVenta > 0) {
        min = v.precioVenta;
      }
    }
    return min;
  }

  int get stockTotal {
    int total = 0;
    for (final v in variantes) {
      total += v.stock;
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'activo': activo,
      'publicado': publicado,
      'id_categoria': categoriaId,
      'id_catalogo': catalogoId,
      'categoria': categoria?.toJson(),
      'catalogo': catalogo?.toJson(),
      'imagenes': imagenes.map((e) => e.toJson()).toList(),
      'variantes': variantes.map((e) => e.toJson()).toList(),
      if (precioFinalBackend != null) 'precio_final': precioFinalBackend,
    };
  }
}
